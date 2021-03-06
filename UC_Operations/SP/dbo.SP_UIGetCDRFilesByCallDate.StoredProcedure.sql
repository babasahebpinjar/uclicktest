USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCDRFilesByCallDate]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetCDRFilesByCallDate]
(
	@BeginDate datetime,
	@EndDate datetime,
	@CDRFileName varchar(100),
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

if  ( ( isnull(@CDRFileStatusID, 0) <> 0 ) and ( @CDRFileStatusID not in (10010,10011,10012,10013,10020 , 10021, 10022, 10023) ))
Begin

		set @ErrorDescription = 'ERROR !!!!! Status passed as parameter is not valid for CDR File Processing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

if ( isnull(@CDRFileStatusID, 0) = 0 ) -- All status
	set @CDRFileStatusID = NULL

---------------------------------------------------
-- Optimize the CDR File Name Regular Expression
---------------------------------------------------

set @CDRFileName = rtrim(ltrim(@CDRFileName))

if (( @CDRFileName is not Null ) and ( len(@CDRFileName) = 0 ) )
	set @CDRFileName = NULL

if ( ( @CDRFileName <> '_') and charindex('_' , @CDRFileName) <> -1 )
Begin

	set @CDRFileName = replace(@CDRFileName , '_' , '[_]')

End

Begin Try

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
			   isnull(TBL2.Measure1, 0) as TotalCDRs,
			   TBL1.Remarks
		into #TempCDRFileList
		from 
		(
			select tbl1.* ,
				   reverse(substring(reverse(TBL1.ObjectInstance) , charindex('_' , reverse(TBL1.ObjectInstance)) + 1 , 8)) as FileTimeStamp,
				   Convert(date , StartDate) as StartDatePart,
				   Convert(date , EndDate) as EndDatePart
			from UC_Operations.dbo.tb_ObjectInstance tbl1
			inner join UC_Operations.dbo.tb_object tbl2 on tbl1.ObjectId = tbl2.Objectid
			where tbl2.ObjectTypeID = 100
		) TBL1
		left join UC_Operations.dbo.tb_ObjectInstancetasklog TBL2 on TBL1.ObjectInstanceID = TBL2.ObjectInstanceID
		                                                          and TBL2.Taskname = 'Upload RAW CDR File'
		inner join UC_Operations.dbo.tb_Status TBL3 on TBL1.StatusID = TBL3.StatusID
		and
		  (
				TBL1.StartDatePart between @BeginDate and @EndDate
				or
				TBL1.EndDatePart between @BeginDate and @EndDate
		  )
		and TBL3.StatusID = 
			   Case
					When @CDRFileStatusID is NULL then TBL3.StatusID
					Else @CDRFileStatusID
			   End
			   
			    
		----------------------------------------------------
		-- Build the dynamic SQL to display the result set
		----------------------------------------------------

		set @SQLStr = 
			 ' Select  FileTimeStamp , ObjectInstanceID , CDRFileName , Status , StartDate , EndDate , TotalCDRs , Remarks' + char(10) +
			 ' from #TempCDRFileList ' + char(10)

		set @Clause1 = 
				   Case
					   When (@CDRFileName is NULL) then ''
					   When (@CDRFileName = '_') then ' where CDRFileName like '  + '''' + '%' + '[_]' + '%' + ''''
					   When ( ( Len(@CDRFileName) =  1 ) and ( @CDRFileName = '%') ) then ''
					   When ( right(@CDRFileName ,1) = '%' ) then ' where CDRFileName like ' + '''' + substring(@CDRFileName,1 , len(@CDRFileName) - 1) + '%' + ''''
					   Else ' where CDRFileName like ' + '''' + @CDRFileName + '%' + ''''
				   End

		set @SQLStr  = @SQLStr + @Clause1

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Extracting CDR File list for selected criteria. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileList') )
		Drop table #TempCDRFileList

Return 0
GO
