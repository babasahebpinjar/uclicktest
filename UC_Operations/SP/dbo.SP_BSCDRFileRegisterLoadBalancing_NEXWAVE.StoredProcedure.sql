USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRFileRegisterLoadBalancing_NEXWAVE]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSCDRFileRegisterLoadBalancing_NEXWAVE]
As

Declare @NumCDRDatabases int = 4,
        @LoadBalancingFormula varchar(2000) = 'Substring(CDRFileName , 24 ,1) % NumCDRDatabases',
		@FileNameTag varchar(50) = 'TELES_MGC_2016',
		@FileExtension varchar(50) = 'CDR',
		@ReprocessFileExtension varchar(50) = 'OLD',
		@CDRFileLocation varchar(1000) = 'F:\uClick_Product_Suite\uClickFacilitate\TELES_MGC\Module\Formatter\Output',
		@CDRDestinationLocation varchar(1000) = '\\10.92.1.165\f\uClick_Product_Suite\TestCopy'


---------------------------------------------------------------------------------
-- Create a table to store the names of all the CDR files which are present in
-- the input directory, but have never been registered for processing
---------------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFilesToProcess') )
		Drop table #temp_CDRFilesToProcess

Create table #temp_CDRFilesToProcess ( CDRFileName varchar(500) )

if ( right(@CDRFileLocation ,1) <> '\' )
	set @CDRFileLocation = @CDRFileLocation + '\'

Declare @Command varchar(2000),
        @SQLStr varchar(2000),
		@ErrorMSgStr varchar(2000),
		@FileExists int

Begin Try

		set @Command = 'Dir ' + '"'+ @CDRFileLocation + @FileNameTag + '*' + '.' +  @FileExtension + '"' + ' ' + '/b'
		print @Command

		insert into #temp_CDRFilesToProcess
		EXEC 	master..xp_cmdshell @Command


		--Select * from #temp_CDRFilesToProcess

		delete from #temp_CDRFilesToProcess
		where 
		( 
		  CDRFileName is NULL
		  or
		  substring(CDRFileName  , 1 , len(@FileNameTag) ) <> @FileNameTag
		  or 
		  substring( CDRFileName , charindex('.' , CDRFileName) + 1 , len(CDRFileName)) <> @FileExtension
		)


		---------------------------------------------------------------------
		-- Remove all the CDR file records from the list, which are already
		-- registered in the system
		---------------------------------------------------------------------

		Delete tbl1
		from #temp_CDRFilesToProcess tbl1
		inner join tb_ObjectInstance tbl2 on tbl1.CDRFileName = tbl2.ObjectInstance
		inner join tb_Object tbl3 on tbl2.ObjectID = tbl3.ObjectID
		where tbl3.ObjectTypeID = 100 -- CDR file Processing


		--Select * from #temp_CDRFilesToProcess



End Try

Begin Catch

		set @ErrorMSgStr = 'ERROR !!!!! While extracting list of CDR files from Input Directory .' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorMsgStr)
		GOTO ENDPROCESS

End Catch

--------------------------------------------------------------
-- Alter the temporary CDR files table to add the RangeValue
-- and CDR File Processing ObjectID
--------------------------------------------------------------

Alter table #temp_CDRFilesToProcess Add RangeValue int
Alter table #temp_CDRFilesToProcess Add ObjectID int
Alter table #temp_CDRFilesToProcess Add FileProcessType int -- 0 means NEW  and 1 menas Reprocess

--------------------------------------------------------------------
-- For all the new files set the process type as 0 for all new files
---------------------------------------------------------------------

update #temp_CDRFilesToProcess set FileProcessType = 0


-- **********************   START HANDLING REPROCESS CDR FILES ********************** --


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFilesToReProcess') )
		Drop table #temp_CDRFilesToReProcess

Create table #temp_CDRFilesToReProcess ( CDRFileName varchar(500) )

------------------------------------------------------------------------------------
-- Check for any Reprocess files which need to be again reuploaded in downstream
-----------------------------------------------------------------------------------

Begin Try

		set @Command = 'Dir ' + '"'+ @CDRFileLocation + @FileNameTag + '*' + '.' +  @FileExtension +  '.' + @ReprocessFileExtension + '"' + ' ' + '/b'
		--print @Command

		insert into #temp_CDRFilesToReProcess
		EXEC 	master..xp_cmdshell @Command


		--Select * from #temp_CDRFilesToReProcess

		delete from #temp_CDRFilesToReProcess
		where 
		( 
		  CDRFileName is NULL
		  or
		  substring(CDRFileName  , 1 , len(@FileNameTag) ) <> @FileNameTag
		  or 
		  substring( CDRFileName , charindex('.' , CDRFileName) + 1 , len(CDRFileName)) <> (@FileExtension +  '.' + @ReprocessFileExtension)
		)


		----------------------------------------------------------------------
		-- Update the CDR file names to remove the Reprocess File Extension
		----------------------------------------------------------------------

		update #temp_CDRFilesToReProcess
		set CDRFilename = substring ( CDRFilename , 1 , ( len(CDRFilename)- len(@ReprocessFileExtension) -1 ))

		--Select * from #temp_CDRFilesToReProcess


End Try

Begin Catch

		set @ErrorMSgStr = 'ERROR !!!!! While extracting list of Reprocess CDR files from Input Directory .' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorMsgStr)
		GOTO ENDPROCESS

End Catch

--------------------------------------------------------------
-- Alter the temporary CDR files table to add the RangeValue
-- and CDR File Processing ObjectID
--------------------------------------------------------------

Alter table #temp_CDRFilesToReProcess Add ObjectID int
Alter table #temp_CDRFilesToReProcess Add FileProcessType int -- 0 means NEW  and 1 means Reprocess


------------------------------------------------------------------------------
-- Depending upon whether a new file has been reprocessed or an already
-- registered file has been reprocessed, set the FileProcess Type
------------------------------------------------------------------------------

update tbl1
set FileProcessType = 1,
    ObjectID = tbl2.ObjectID
from #temp_CDRFilesToReProcess tbl1
inner join tb_ObjectInstance tbl2 on tbl1.CDRFileName = tbl2.ObjectInstance
inner join tb_Object tbl3 on tbl2.ObjectID = tbl3.ObjectID
where tbl3.ObjectTypeID = 100 -- CDR file Processing


update #temp_CDRFilesToReProcess
set FileProcessType = 0
where FileProcessType is NULL



-- **********************   END HANDLING REPROCESS CDR FILES ********************** --


--------------------------------------------------------------------------------------------
-- Merge all the data for new and Reprocess files into the main table for further processing
--------------------------------------------------------------------------------------------

insert into #temp_CDRFilesToProcess
( CDRFilename , RangeValue ,ObjectID , FileProcesstype )
Select CDRFilename , NULL , ObjectID , FileProcesstype
from #temp_CDRFilesToReProcess

-------------------------------------------------------------------------------
-- Find out Range value for all new files which are going to be registered
-- for the fisrt time
--------------------------------------------------------------------------------


Begin Try

		---------------------------------------------------------------
		-- Run dynamic SQL to update the Range Value for the CDR files
		-- which qualify for registration
		---------------------------------------------------------------

		set @SQLStr = 'Update #temp_CDRFilesToProcess ' + char(10)+
			      ' set RangeValue = ' + Replace(@LoadBalancingFormula , 'NumCDRDatabases' , convert(varchar(20) ,@NumCDRDatabases)) + char(10) +
			      ' where FileProcesstype = 0 ' -- Only for New Register Files	   

		--print @SQLStr

		Exec (@SQLStr)

End Try

Begin Catch

		set @ErrorMSgStr = 'ERROR !!!!! Updating the Range Value for each CDR file based on load balancing formula  .' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorMsgStr)
		GOTO ENDPROCESS

End Catch


--Select * from #temp_CDRFilesToProcess

-- ****************** START HARD CODED LOGIC LATER TO BE REPLACED WITH DYNAMIC CODE *********************---

-----------------------------------------------------------------
-- Update the ObjectID field with the value of the ObjectID
-- depending on the range value
-----------------------------------------------------------------

update #temp_CDRFilesToProcess
set ObjectID = 
        Case
				When RangeValue = 0 then 2 -- DATA01
				When RangeValue = 1 then 4 -- DATA02
				When RangeValue = 2 then 5 -- DATA03
				When RangeValue = 3 then 6 -- DATA04
		End
where RangeValue is not NULL -- Exclude all files which are being Re-processed

-- ****************** END HARD CODED LOGIC LATER TO BE REPLACED WITH DYNAMIC CODE *********************---


Select * from #temp_CDRFilesToProcess

Select * from #temp_CDRFilesToProcess
where FileProcesstype = 1

-----------------------------------------------------------------------------
-- if there are no CDR file records to process then exit the further steps
-----------------------------------------------------------------------------

if ( ( select count(*) from #temp_CDRFilesToProcess ) = 0 )
	GOTO ENDPROCESS


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFileProcessResults') )
		Drop table #temp_CDRFileProcessResults

Create table #temp_CDRFileProcessResults ( CDRFileProcessResults varchar(500) )

-------------------------------------------------------------------------
-- Open cursor on the CDR Files tables to register each file and copy
-- it to the Destination folder
-------------------------------------------------------------------------

Declare @VarCDRFileName varchar(500),
        @VarFileProcesstype int,
		@VarObjectID int,
		@AbsoluteCDRFileName varchar(2000),
		@AbsoluteReprocessCDRFileName varchar(2000)


DECLARE db_cur_Register_CDR_Files CURSOR FOR
select CDRFilename , FileProcesstype , ObjectID
from #temp_CDRFilesToProcess

OPEN db_cur_Register_CDR_Files
FETCH NEXT FROM db_cur_Register_CDR_Files
INTO @VarCDRFileName , @VarFileProcesstype ,  @VarObjectID

While @@FETCH_STATUS = 0
BEGIN


        -------------------------------------------------------------------------
		-- Check the process type of the file. If it is a new file, then proceed
		-- other wise if it is a an already registered file, check its state
		-- to decide whether to process or skip the file
		-------------------------------------------------------------------------

		if ( @VarFileProcesstype = 1 )
		Begin

			   ------------------------------------------------------------
			   -- Skip the file if it is currently in processing status.
			   -- The file will be replaced in the destination folder in
			   -- next iteration
			   ------------------------------------------------------------
			   
			   if exists (
			                    select 1
								from tb_ObjectInstance tbl1
								inner join tb_Object tbl2 on tbl1.ObjectID = tbl2.ObjectID
								where tbl1.ObjectInstance = @VarCDRFileName
								and tbl1.StatusID = 10011 -- CDR File Running
								and tbl2.ObjectTypeID = 100
			             )	
				Begin

							GOTO PROCESSNEXTFILE

				End

		End

        -------------------------------------------------------------------------
		-- Remove any old instance of file existing in the destination folder
		-------------------------------------------------------------------------

        set @AbsoluteCDRFileName = Case
					                   When right(@CDRDestinationLocation,1) <> '\' then @CDRDestinationLocation + '\'
					                   Else @CDRDestinationLocation
		                           End + @VarCDRFileName

		set @FileExists = 0

		Exec master..xp_fileexist  @AbsoluteCDRFileName , @FileExists output 

		If (@FileExists = 1)
		Begin

			        
				set @Command = 'del ' + '"'+ @AbsoluteCDRFileName + '"'
				print @Command 

				Exec master..xp_cmdshell @Command

		End

		-------------------------------------------
		--  Copy the CDR file to destination folder
		-------------------------------------------

		delete from #temp_CDRFileProcessResults

                set @Command = 'Copy ' + '"' + @CDRFileLocation + @VarCDRFileName + '"' + ' ' + '"' + @CDRDestinationLocation + '"'
		print @Command

		insert into #temp_CDRFileProcessResults
		EXEC master..xp_cmdshell @Command


		--------------------------------------------------------------------------------
		-- Confirm to see that the CDR file has been copied to the destination folder
		-------------------------------------------------------------------------------

		if not exists ( select 1 from #temp_CDRFileProcessResults where charindex('1 file(s) copied' , CDRFileProcessResults) <> 0 )
		Begin

				set @ErrorMSgStr = 'ERROR !!!!! CDR file : ' + @VarCDRFileName + ' could not be copied to destination folder : ' + @CDRDestinationLocation
				RaisError('%s' , 16,1 , @ErrorMsgStr)

				CLOSE db_cur_Register_CDR_Files
				DEALLOCATE db_cur_Register_CDR_Files


				GOTO ENDPROCESS

		End

		-----------------------------------------------------------------------------------
		-- Depending on the File ProcessType either create a new record in the Registration
		-- table or update the status to Registered for a reprocess file
		-----------------------------------------------------------------------------------

		--if ( @VarFileProcesstype = 1 ) -- Reprocess
		--Begin

		--End

		--if ( @VarFileProcesstype = 0 ) -- New Registration
		--Begin

		--End

		----------------------------------------------------------------------------------
		-- Remove the reprocess instance of the CDR file from the source folder so that the
		-- Registration mechanism does not pick it up again
		-- First check if .OLD file exists. It could be there for an already registered
		-- file or a new file, which has been reprrocessed at mediation end, but still not
		-- Registered in UC_Operations
		-----------------------------------------------------------------------------------

		set @AbsoluteReprocessCDRFileName = @CDRFileLocation + @VarCDRFileName + '.' + @ReprocessFileExtension

		set @FileExists = 0

		Exec master..xp_fileexist  @AbsoluteReprocessCDRFileName , @FileExists output 

		If (@FileExists = 1)
		Begin

			        
				set @Command = 'del ' + '"'+ @AbsoluteReprocessCDRFileName + '"'
				print @Command 

				Exec master..xp_cmdshell @Command

		End


PROCESSNEXTFILE:

		FETCH NEXT FROM db_cur_Register_CDR_Files
		INTO  @VarCDRFileName , @VarFileProcesstype ,  @VarObjectID   		 

END

CLOSE db_cur_Register_CDR_Files
DEALLOCATE db_cur_Register_CDR_Files


--Begin Try

--		-------------------------------------------------------------
--		-- Insert records into the Object Instance table for each
--		-- of the CDR files, so that they can be processed by their 
--		-- respective databases
--		-------------------------------------------------------------

--		insert into tb_ObjectInstance
--		(
--			ObjectID,
--			ObjectInstance,
--			StatusID,
--			ProcessStartTime,
--			ProcessEndTime ,
--			ModifiedDate,
--			ModifiedByID
--		)
--		select ObjectID ,
--			   CDRFileName,
--			   10010, -- CDR File Registered
--			   Getdate(),
--			   NULL,
--			   Getdate(),
--			   -1
--		from #temp_CDRFilesToProcess
--		where ObjectID is not NULL

--End Try

--Begin Catch

--		set @ErrorMSgStr = 'ERROR !!!!! Inserting records for registering CDR file(s) for rating process  .' + ERROR_MESSAGE()
--		RaisError('%s' , 16,1 , @ErrorMsgStr)
--		GOTO ENDPROCESS

--End Catch


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFilesToProcess') )
		Drop table #temp_CDRFilesToProcess

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFileProcessResults') )
		Drop table #temp_CDRFileProcessResults

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFilesToReProcess') )
		Drop table #temp_CDRFilesToReProcess

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFilesToReProcess') )
		Drop table #temp_CDRFilesToReProcess
GO
