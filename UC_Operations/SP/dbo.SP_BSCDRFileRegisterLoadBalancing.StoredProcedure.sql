USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRFileRegisterLoadBalancing]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRFileRegisterLoadBalancing]
(
    @InstanceID int,
	@FileNameTag varchar(50) ,
	@FileExtension varchar(50) ,
	@ControlFileExtension varchar(50) ,
	@CDRFileLocation varchar(1000) ,
	@CDRDestinationLocation varchar(1000) ,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @LoadBalancingFormula varchar(2000),
        @NumCDRDatabases int

Declare @Command varchar(2000),
        @SQLStr varchar(2000),
		@FileExists int


--------------------------------------------------------------
-- Get the Load Balancing Formula and the number of Databases
--------------------------------------------------------------

Select @LoadBalancingFormula = LoadBalancingFormula,
       @NumCDRDatabases = NumberOfCDRInstances
from tb_LoadBalancingFormula

if ( ( @LoadBalancingFormula is NULL ) or ( @NumCDRDatabases is NULL ) )
Begin

		set @ErrorDescription = 'ERROR !!!!! Load balancing Formula details not defined'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

----------------------------------------------------
-- Change the status of Object Instance to running
-----------------------------------------------------

update tb_ObjectInstance
set statusid = 10111 -- CDR Collect Running
where ObjectInstanceID = @InstanceID

---------------------------------------------------------------------------------
-- Create a table to store the names of all the CDR files which are present in
-- the input directory, but have never been registered for processing
-- We need to pick up the CONTROL files, and for CONTROL file, we need to 
-- pick up the corresponding CDR File
---------------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFilesToProcess') )
		Drop table #temp_CDRFilesToProcess

Create table #temp_CDRFilesToProcess ( CDRFileName varchar(500) )

-- Added the '\' at the end of both directory location as we will be
-- comparing them to establish if Source and destination folder are the same

if ( right(@CDRFileLocation ,1) <> '\' )
	set @CDRFileLocation = @CDRFileLocation + '\'

if ( right(@CDRDestinationLocation ,1) <> '\' )
	set @CDRDestinationLocation = @CDRDestinationLocation + '\'

Begin Try

		set @Command = 'Dir ' + '"'+ @CDRFileLocation + @FileNameTag + '*' +  @ControlFileExtension + '"' + ' ' + '/b'
		print @Command

		insert into #temp_CDRFilesToProcess
		EXEC 	master..xp_cmdshell @Command


		Select * from #temp_CDRFilesToProcess

		delete from #temp_CDRFilesToProcess
		where 
		( 
		  CDRFileName is NULL
		  or
		  substring(CDRFileName  , 1 , len(@FileNameTag) ) <> @FileNameTag
		  or 
		  reverse(substring(reverse(CDRFileName) , 1 , charindex('.' , reverse(CDRFileName)))) <> @ControlFileExtension
		)

		-----------------------------------------------------------------------
		-- Update the table holding the control file information to remove the
		-- control file extension and have the original file name
		-----------------------------------------------------------------------

		update #temp_CDRFilesToProcess
		set CDRFileName =  Case
								When @FileExtension is NULL then replace(CDRFileName , @ControlFileExtension, '')
								Else replace(CDRFileName , @ControlFileExtension , @FileExtension)
						   End 

        --Select 'After Replacing Control File Extension' ,* 
		--from #temp_CDRFilesToProcess

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

		set @ErrorDescription = 'ERROR !!!!! While extracting list of CDR files from Input Directory .' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--------------------------------------------------------------
-- Alter the temporary CDR files table to add the RangeValue
-- and CDR File Processing ObjectID
--------------------------------------------------------------

Alter table #temp_CDRFilesToProcess Add RangeValue int
Alter table #temp_CDRFilesToProcess Add ObjectID int
Alter table #temp_CDRFilesToProcess Add FileCollectDate datetime
Alter table #temp_CDRFilesToProcess Add OriginalFileSizeInKB Decimal(19,2)
Alter table #temp_CDRFilesToProcess Add CollectFileSizeInKB Decimal(19,2)


-------------------------------------------------------------------------------
-- Find out Range value for all new files which are going to be registered
-- for the first time
--------------------------------------------------------------------------------


Begin Try

		---------------------------------------------------------------
		-- Run dynamic SQL to update the Range Value for the CDR files
		-- which qualify for registration
		---------------------------------------------------------------

		set @SQLStr = 'Update #temp_CDRFilesToProcess ' + char(10)+
			      ' set RangeValue = ' + 'convert(int , ' + @LoadBalancingFormula + ')%'+ convert(varchar(20) , @NumCDRDatabases)

		print @SQLStr

		Exec (@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Updating the Range Value for each CDR file based on load balancing formula  .' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorDescription)
		GOTO ENDPROCESS

End Catch


--Select 'After updating Range Value ' , * 
--from #temp_CDRFilesToProcess


-----------------------------------------------------------------
-- Update the ObjectID field with the value of the ObjectID
-- depending on the range value
-----------------------------------------------------------------

update tbl1
set ObjectID = tbl2.CDRFileObjectID
from #temp_CDRFilesToProcess tbl1
inner join tb_LoadBalancingRange tbl2 on tbl1.RangeValue = tbl2.LoadBalancingRangeValue
where tbl1.RangeValue is not NULL


--Select * from #temp_CDRFilesToProcess

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
		@AbsoluteControlCDRFileName varchar(2000),
		@AbsoluteOrigCDRFileName varchar(2000),
		@OriginalCDRFileSize int,
		@CopiedCDRFileSize int,
		@FileDetails varchar(1000)


DECLARE db_cur_Register_CDR_Files CURSOR FOR
select CDRFilename , ObjectID
from #temp_CDRFilesToProcess
where objectid is not null

OPEN db_cur_Register_CDR_Files
FETCH NEXT FROM db_cur_Register_CDR_Files
INTO @VarCDRFileName ,  @VarObjectID

While @@FETCH_STATUS = 0
BEGIN


        -------------------------------------------------------------------------
		-- Remove any old instance of file existing in the destination folder
		-------------------------------------------------------------------------

		set @AbsoluteControlCDRFileName = @CDRFileLocation + 
		                                  Case
												When @FileExtension is NULL then @VarCDRFileName + @ControlFileExtension
												Else replace(@VarCDRFileName , @FileExtension , @ControlFileExtension )
										   End 

        set @AbsoluteCDRFileName = Case
					                   When right(@CDRDestinationLocation,1) <> '\' then @CDRDestinationLocation + '\'
					                   Else @CDRDestinationLocation
		                           End + @VarCDRFileName

        set @AbsoluteOrigCDRFileName = @CDRFileLocation + @VarCDRFileName

		if (@CDRFileLocation <> @CDRDestinationLocation)
		Begin

				-------------------------------------------------
				-- Delete if any instance of the CDR file exists
				-- in the destination folder
				-------------------------------------------------

				set @FileExists = 0

				Exec master..xp_fileexist  @AbsoluteCDRFileName , @FileExists output 

				If (@FileExists = 1)
				Begin

			        
						set @Command = 'del ' + '"'+ @AbsoluteCDRFileName + '"'
						--print @Command 

						Exec master..xp_cmdshell @Command

				End

				-------------------------------------------
				--  Copy the CDR file to destination folder
				-------------------------------------------

				delete from #temp_CDRFileProcessResults

				set @Command = 'Copy ' + '"' + @CDRFileLocation + @VarCDRFileName + '"' + ' ' + '"' + @CDRDestinationLocation + '"'

				--print @Command

				insert into #temp_CDRFileProcessResults
				EXEC master..xp_cmdshell @Command


				--------------------------------------------------------------------------------
				-- Confirm to see that the CDR file has been copied to the destination folder
				-------------------------------------------------------------------------------

				if not exists ( select 1 from #temp_CDRFileProcessResults where charindex('1 file(s) copied' , CDRFileProcessResults) <> 0 )
				Begin

						set @ErrorDescription = 'ERROR !!!!! CDR file : ' + @VarCDRFileName + ' could not be copied to destination folder : ' + @CDRDestinationLocation
						set @ResultFlag = 1

						CLOSE db_cur_Register_CDR_Files
						DEALLOCATE db_cur_Register_CDR_Files


						GOTO ENDPROCESS

				End

		End

		----------------------------------------------------------------------------------
		-- Once the file is successfully copied, remove the CONTROL file instance from the
		-- Source folder. Also delete the originaal file from Source folder

		-- Before doing that ensure that the size of the CDR file at source and destination
		-- locations is the same
		-----------------------------------------------------------------------------------

		------------------------------------------------------------------------------
		-- CHECK SIZE OF CDR FILE AT SOURCE AND DESTINATION LOCATION TO ENSURE THAT
		-- FILE IS COPIED CORRECTLY
		------------------------------------------------------------------------------

		Exec SP_BSCDRFileRegisterGetFileDetails @VarCDRFileName , @AbsoluteOrigCDRFileName , @FileDetails Output

		Select @OriginalCDRFileSize = Replace(substring(rtrim(@FileDetails), 22 , len(rtrim(@FileDetails))), ',' , '')

		Exec SP_BSCDRFileRegisterGetFileDetails @VarCDRFileName , @AbsoluteCDRFileName , @FileDetails Output

		Select @CopiedCDRFileSize = Replace(substring(rtrim(@FileDetails), 22 , len(rtrim(@FileDetails))), ',' , '')

		if (@OriginalCDRFileSize <> @CopiedCDRFileSize ) 
		Begin

				set @ErrorDescription = 'ERROR !!!!! CDR file : ' + @VarCDRFileName + 
				                   ' size in source folder : ( '+ convert(varchar(20) , @OriginalCDRFileSize) + ' bytes ) ' +
								   ' not same as size in destination folder : ( '+ convert(varchar(20) , @CopiedCDRFileSize) + ' bytes ) '
				

				set @ResultFlag = 1

				CLOSE db_cur_Register_CDR_Files
				DEALLOCATE db_cur_Register_CDR_Files


				GOTO ENDPROCESS

		End

		---------------------------------------------------------------------------------
		-- Update the temporary table with informtion regarding File Size and collection
		-- date
		---------------------------------------------------------------------------------

		update #temp_CDRFilesToProcess
		set FileCollectDate = getdate() , 
		    OriginalFileSizeInKB = convert(decimal(19,2) , @OriginalCDRFileSize/1024.0),
			CollectFileSizeInKB =  convert(decimal(19,2) , @CopiedCDRFileSize/1024.0)
        Where CDRFileName = @VarCDRFileName


PROCESSNEXTFILE:

		FETCH NEXT FROM db_cur_Register_CDR_Files
		INTO  @VarCDRFileName ,  @VarObjectID   		 

END

CLOSE db_cur_Register_CDR_Files
DEALLOCATE db_cur_Register_CDR_Files


Begin Try

		-------------------------------------------------------------
		-- Insert records into the Object Instance table for each
		-- of the CDR files, so that they can be processed by their 
		-- respective databases
		-------------------------------------------------------------

		insert into tb_ObjectInstance
		(
			ObjectID,
			ObjectInstance,
			StatusID,
			ProcessStartTime,
			ProcessEndTime ,
			ModifiedDate,
			ModifiedByID
		)
		select ObjectID ,
			   CDRFileName,
			   10010, -- CDR File Registered
			   Getdate(),
			   NULL,
			   Getdate(),
			   -1
		from #temp_CDRFilesToProcess
		where ObjectID is not NULL

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Inserting records for registering CDR file(s) for rating process  .' + ERROR_MESSAGE()
		set @ResultFlag =  1
		GOTO ENDPROCESS

End Catch

--------------------------------------------------------------
-- Insert entry into the statisctics table for all the CDR
-- files registered
--------------------------------------------------------------

insert into tb_CDRFileCollectionStatistics
(
	CDRFileName,
	FileCollectDate,
	OriginalFileSizeInKB,
	CollectFileSizeInKB,
	CDRCollectionProcessInstanceID,
	CDRLoadObjectID
)
Select CDRFileName,
       FileCollectDate,
	   OriginalFileSizeInKB,
	   CollectFileSizeInKB,
	   @InstanceID,
	   ObjectID       
from #temp_CDRFilesToProcess

---------------------------------------------------------------
-- At this point of process :
-- 1. Files copied to Destination Folder
-- 2. Fiels registered for processing

-- Once everything haas been done successfully delete the 
-- original CDR file and control file from source folder
----------------------------------------------------------------

if ( @CDRFileLocation <> @CDRDestinationLocation )
Begin

			DECLARE db_cur_Del_Orig_CDR_Files CURSOR FOR
			select CDRFilename
			from #temp_CDRFilesToProcess
			where Objectid is not null

			OPEN db_cur_Del_Orig_CDR_Files
			FETCH NEXT FROM db_cur_Del_Orig_CDR_Files
			INTO @VarCDRFileName 

			While @@FETCH_STATUS = 0
			BEGIN

					set @AbsoluteControlCDRFileName = @CDRFileLocation + 
												Case
													When @FileExtension is NULL then @VarCDRFileName + @ControlFileExtension
													Else replace(@VarCDRFileName , @FileExtension , @ControlFileExtension )
												End 
					set @AbsoluteOrigCDRFileName = @CDRFileLocation + @VarCDRFileName

					-------------------------------------
					-- DELETING CONTROL FILE INSTANCE
					-------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteControlCDRFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

			        
							set @Command = 'del ' + '"'+ @AbsoluteControlCDRFileName + '"'
							--print @Command 
							Exec master..xp_cmdshell @Command

					End

					-------------------------------
					-- DELETING ORIGINAL CDR FILE
					-------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteOrigCDRFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

			        
							set @Command = 'del ' + '"'+ @AbsoluteOrigCDRFileName + '"'
							--print @Command 
							Exec master..xp_cmdshell @Command

					End

					FETCH NEXT FROM db_cur_Del_Orig_CDR_Files
					INTO  @VarCDRFileName 


			END

			CLOSE db_cur_Del_Orig_CDR_Files
			DEALLOCATE db_cur_Del_Orig_CDR_Files

End


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
