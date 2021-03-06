USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCDRFileSummaryByDateTimeStamp]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetCDRFileSummaryByDateTimeStamp]
(
	@BeginDate datetime,
	@EndDate datetime,
	@CDRFileStatusID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@Clause2 varchar(1000)

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------
-- Check to ensure that begin date is less than equal to 
-- End Date
------------------------------------------------------------

if  ( @BeginDate > @EndDate )
Begin

		set @ErrorDescription = 'ERROR !!!!! Begin Date cannot be greater than End Date'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------
-- Check what CDR file status has been seleected 
--------------------------------------------------

if  ( ( isnull(@CDRFileStatusID, 0) <> 0 ) and ( @CDRFileStatusID not in (10010,10011,10012,10013) ))
Begin

		set @ErrorDescription = 'ERROR !!!!! Status passed as parameter is not valid for CDR File Processing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

if ( isnull(@CDRFileStatusID, 0) = 0 ) -- All status
	set @CDRFileStatusID = NULL


Begin Try

		-----------------------------------------------------------
		-- Convert begin and end date into time stamps for the 
		-- purpose of comparison
		-----------------------------------------------------------

		Declare @BeginTimeStamp varchar(8),
				@EndTimeStamp varchar(8)

		set @BeginTimeStamp = replace(convert(varchar(10) , @BeginDate , 120) , '-', '')
		set @EndTimeStamp = replace(convert(varchar(10) , @EndDate, 120) , '-', '')

		----------------------------------------------------------------------
		-- Extract the result set on the basis of the passed input parameters
		----------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileList') )
				Drop table #TempCDRFileList

		select FileTimeStamp , 
			   TBL1.ObjectInstanceID,
			   TBL1.ObjectInstance as CDRFileName,
			   TBL3.StatusName as Status, 
			   TBL1.StartDate , 
			   TBL1.EndDate , 
			   isnull(TBL2.Measure1, 0) as TotalCDRs
		into #TempCDRFileList
		from 
		(
			select tbl1.* ,
				   reverse(substring(reverse(TBL1.ObjectInstance) ,17 , 8)) as FileTimeStamp
			from UC_Operations.dbo.tb_ObjectInstance tbl1
			inner join UC_Operations.dbo.tb_object tbl2 on tbl1.ObjectId = tbl2.Objectid
			where tbl2.ObjectTypeID = 100
		) TBL1
		left join UC_Operations.dbo.tb_ObjectInstancetasklog TBL2 on TBL1.ObjectInstanceID = TBL2.ObjectInstanceID
																		and TBL2.Taskname = 'Upload RAW CDR File'
		inner join UC_Operations.dbo.tb_Status TBL3 on TBL1.StatusID = TBL3.StatusID
		and FileTimeStamp between @BeginTimeStamp and @EndTimeStamp
		and TBL3.StatusID = 
			   Case
					When @CDRFileStatusID is NULL then TBL3.StatusID
					Else @CDRFileStatusID
			   End 

       -------------------------------------------------------------
	   -- Summarize the data on the basis of the date time stamp
	   -------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileSummary') )
				Drop table #TempCDRFileSummary

        select FileTimeStamp , count(*) as TotalFiles , sum(TotalCDRs) as TotalCDRs
		into #TempCDRFileSummary
		from #TempCDRFileList
		group by FileTimeStamp

		----------------------------------------------------------
		-- Alter the table to add count for success and attempt
		-- files for Huawei and Ericsson switches
		-----------------------------------------------------------

		Alter table #TempCDRFileSummary Add HUA_Attempt_Files int default 0
		Alter table #TempCDRFileSummary Add HUA_Success_Files int default 0
		Alter table #TempCDRFileSummary Add ERI_Attempt_Files int default 0
		Alter table #TempCDRFileSummary Add ERI_Success_Files int default 0

		Alter table #TempCDRFileSummary Add HUA_Attempt_CDRs int default 0
		Alter table #TempCDRFileSummary Add HUA_Success_CDRs int default 0
		Alter table #TempCDRFileSummary Add ERI_Attempt_CDRs int default 0
		Alter table #TempCDRFileSummary Add ERI_Success_CDRs int default 0

		-------------------------------------------------
		-- Update the Attempt and succes files for each 
		-- date and switch
		-------------------------------------------------

		update tbl1
		set HUA_Attempt_Files = isnull(tbl2.TotalFiles, 0),
		    HUA_Attempt_CDRs = isnull(tbl2.TotalCDRs, 0)
		from #TempCDRFileSummary tbl1
		inner join
		(
			select FileTimeStamp , count(*) as TotalFiles , sum(TotalCDRs) as TotalCDRs
			from #TempCDRFileList
			where charindex('CALL_ATTMPT_HUA' , CDRFilename) <> 0
			group by FileTimeStamp
		) tbl2 on tbl1.FileTimeStamp = tbl2.FileTimeStamp

		update tbl1
		set HUA_Success_Files = isnull(tbl2.TotalFiles, 0),
		    HUA_Success_CDRs = isnull(tbl2.TotalCDRs, 0)
		from #TempCDRFileSummary tbl1
		inner join
		(
			select FileTimeStamp , count(*) as TotalFiles, sum(TotalCDRs) as TotalCDRs
			from #TempCDRFileList
			where charindex('CALL_SUCCESS_HUA' , CDRFilename) <> 0
			group by FileTimeStamp
		) tbl2 on tbl1.FileTimeStamp = tbl2.FileTimeStamp

		update tbl1
		set ERI_Attempt_Files = isnull(tbl2.TotalFiles, 0),
		    ERI_Attempt_CDRs = isnull(tbl2.TotalCDRs, 0)
		from #TempCDRFileSummary tbl1
		inner join
		(
			select FileTimeStamp , count(*) as TotalFiles, sum(TotalCDRs) as TotalCDRs
			from #TempCDRFileList
			where charindex('CALL_ATTMPT_ERI' , CDRFilename) <> 0
			group by FileTimeStamp
		) tbl2 on tbl1.FileTimeStamp = tbl2.FileTimeStamp

		update tbl1
		set ERI_Success_Files = isnull(tbl2.TotalFiles, 0),
		    ERI_Success_CDRs = isnull(tbl2.TotalCDRs, 0)
		from #TempCDRFileSummary tbl1
		inner join
		(
			select FileTimeStamp , count(*) as TotalFiles, sum(TotalCDRs) as TotalCDRs
			from #TempCDRFileList
			where charindex('CALL_SUCCESS_ERI' , CDRFilename) <> 0
			group by FileTimeStamp
		) tbl2 on tbl1.FileTimeStamp = tbl2.FileTimeStamp
		
		-------------------------------------
		-- Display results for user interface
		-------------------------------------
		
		select convert(date ,convert(datetime ,  FileTimeStamp)) as FileDateStamp ,
		       TotalFiles , TotalCDRs , 
			   isnull(HUA_Attempt_Files, 0) as HUA_Attempt_Files,
			   isnull(HUA_Attempt_CDRs, 0) as HUA_Attempt_CDRs,
			   isnull(HUA_Success_Files, 0) as HUA_Success_Files , 
			   isnull(HUA_Success_CDRs, 0) as HUA_Success_CDRs , 
			   isnull(ERI_Attempt_Files, 0) as ERI_Attempt_Files ,
			   isnull(ERI_Attempt_CDRs, 0) as ERI_Attempt_CDRs ,
			   isnull(ERI_Success_Files, 0) as ERI_Success_Files,
			   isnull(ERI_Success_CDRs, 0) as ERI_Success_CDRs
		from #TempCDRFileSummary
		order by FileTimeStamp		


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Extracting CDR File summary for selected criteria. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileList') )
		Drop table #TempCDRFileList

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileSummary') )
		Drop table #TempCDRFileSummary

Return 0
GO
