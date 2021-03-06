USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_DummyLoadBalancing]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_DummyLoadBalancing]
(
	@FileNameTag varchar(50)
)
As

Declare @NumCDRDatabases int = 4,
        @LoadBalancingFormula varchar(2000) = 'Substring(CDRFileName , 24 ,1) % NumCDRDatabases',
		--@FileNameTag varchar(50) = 'TELES_MGC',
		@CDRFileLocation varchar(1000) = 'C:\uClick_Product_Suite\uClickFacilitate\TELES_MGC\Module\Formatter\Output'


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
		@ErrorMSgStr varchar(2000)

Begin Try

		set @Command = 'Dir ' + '"'+ @CDRFileLocation + @FileNameTag + '*' + '"' + ' ' + '/b'
		print @Command

		insert into #temp_CDRFilesToProcess
		EXEC 	master..xp_cmdshell @Command

		delete from #temp_CDRFilesToProcess
		where 
		( 
		  CDRFileName is NULL
		  or
		  substring(CDRFileName  , 1 , len(@FileNameTag) ) <> @FileNameTag
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

		-----------------------------------------------------------
		-- if there are no CDR file records returned then exit the
		-- further steps
		-----------------------------------------------------------

		if ( ( select count(*) from #temp_CDRFilesToProcess ) = 0 )
			GOTO ENDPROCESS

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

Begin Try

		---------------------------------------------------------------
		-- Run dynamic SQL to update the Range Value for the CDR files
		-- which qualify for registration
		---------------------------------------------------------------

		set @SQLStr = 'Update #temp_CDRFilesToProcess ' + char(10)+
					  ' set RangeValue = ' + Replace(@LoadBalancingFormula , 'NumCDRDatabases' , convert(varchar(20) ,@NumCDRDatabases)) + char(10) 

		--print @SQLStr

		Exec (@SQLStr)

End Try

Begin Catch

		set @ErrorMSgStr = 'ERROR !!!!! Updating the Range Value for each CDR file based on load balancing formula  .' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorMsgStr)
		GOTO ENDPROCESS

End Catch


Select *
from #temp_CDRFilesToProcess

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

-- ****************** END HARD CODED LOGIC LATER TO BE REPLACED WITH DYNAMIC CODE *********************---


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

		set @ErrorMSgStr = 'ERROR !!!!! Inserting records for registering CDR file(s) for rating process  .' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorMsgStr)
		GOTO ENDPROCESS

End Catch


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRFilesToProcess') )
		Drop table #temp_CDRFilesToProcess
GO
