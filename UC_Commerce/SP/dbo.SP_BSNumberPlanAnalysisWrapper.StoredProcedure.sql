USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSNumberPlanAnalysisWrapper]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSNumberPlanAnalysisWrapper]
(
	@UserID int,
	@ProcessCount int = NULL
)
As

if @ProcessCount is NULL
	set @ProcessCount = 1

Declare @SQLStr varchar(2000)

--------------------------------------------------------------------------------------
-- Get the list of all the source ids for which number plan analysis is pending.
-- Select only those source ids for which no vendor offers are pending Reference
-- analysis in the system
--------------------------------------------------------------------------------------

Create Table #TempReferenceRateReAnalyzeList
(
	NumberPlanAnalysisID int,
	SourceID int,
	AnalysisRegisterDate datetime,
	AnalysisStatusID int
)


set @SQLStr = 'insert into #TempReferenceRateReAnalyzeList ' + char(10) +
              ' (NumberPlanAnalysisID , SourceID , AnalysisRegisterDate , AnalysisStatusID) ' + char(10) +
			  ' select TOP ' + convert(varchar(20) , @ProcessCount) + char(10) +
			  '  NPA.NumberPlanAnalysisID , NPA.SourceID , NPA.AnalysisRegisterDate , NPA.AnalysisStatusID ' + char(10) +
			  ' from tb_NumberPlanAnalysis NPA ' + char(10) +
			  ' where NPA.SourceID not in ' +  char(10) +
			  ' (  ' + char(10) +
			  '   	select sourceid ' + char(10) +
			  '	    from tb_Offer ' + char(10) +
			  '	    where offertypeID = -1  ' + char(10) + -- Vendor Offer
			  '	    and dbo.FN_GetVendorOfferCurrentStatus(OfferID) in (8 , 9 , 10, 11, 12 ) ' + char(10) +
			  ' )  ' + char(10) +
			  ' and NPA.AnalysisStatusID in (1,4)  ' + char(10) + -- Analysis Registered or Completed
			  ' order by NPA.AnalysisRegisterDate , NPA.NumberPlanAnalysisID'


--print (@SQLStr)

Exec (@SQLStr)


--------------------------------------------------------------------
-- Open a cursor and process through each of the offers that are in
-- created state
--------------------------------------------------------------------

Declare @VarNumberPlanAnalysisID int,
		@VarSourceID int,
		@VarAnalysisRegisterDate datetime,
		@VarAnalysisStatusID int,
        @ResultFlag int,
		@ErrorDescription varchar(2000),
		@ErrorMsgStr varchar(2000)

DECLARE db_ReferenceRateReAnalyze_NP_Cur CURSOR FOR  
select NumberPlanAnalysisID , SourceID , AnalysisRegisterDate , AnalysisStatusID
From #TempReferenceRateReAnalyzeList
order by AnalysisRegisterDate , SourceID


OPEN db_ReferenceRateReAnalyze_NP_Cur   
FETCH NEXT FROM db_ReferenceRateReAnalyze_NP_Cur
INTO @VarNumberPlanAnalysisID , @VarSourceID , @VarAnalysisRegisterDate , @VarAnalysisStatusID

WHILE @@FETCH_STATUS = 0   
BEGIN 

       if ( @VarAnalysisStatusID = 4 ) -- Analysis Completed
	      GOTO EXPORTNPA

       --------------------------------------------------------
	   -- Check to ensure that there are no NP Analysis before
	   -- this selected analysis
	   ---------------------------------------------------------

	   if exists (	   
						select 1
						from tb_NumberPlanAnalysis tbl1
						where SourceID = @VarSourceID
						and NumberPlanAnalysisID <> @VarNumberPlanAnalysisID
						and AnalysisRegisterDate < @VarAnalysisRegisterDate
						and AnalysisStatusID <> 7 -- Analysis Exported
				 )
		Begin
		
				GOTO PROCESSNEXTREC

		End 

        ------------------------------------------------------------------------
		-- Call the stored procedure to initiate Number Plan Analysis for source
		------------------------------------------------------------------------

		Begin Try

				set @ResultFlag = 0
				set @ErrorDescription = NULL

				Exec SP_BSReferenceRateReAnalyze @VarNumberPlanAnalysisID , @UserID,
												  @ResultFlag Output,
												  @ErrorDescription Output

		End Try

		Begin Catch

				set @ErrorMsgStr = 'ERROR !!! During Number Plan Analysis process for ID : ' + convert(varchar(20) ,  @VarNumberPlanAnalysisID) + '.' + ERROR_MESSAGE()

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_ReferenceRateReAnalyze_NP_Cur  
				DEALLOCATE db_ReferenceRateReAnalyze_NP_Cur

				GOTO PROCESSEND

		End Catch

		if ( @ResultFlag <> 0 )
		Begin

				set @ErrorMsgStr = 'ERROR !!! During Number Plan Analysis process for ID : ' + convert(varchar(20) ,  @VarNumberPlanAnalysisID) + '.' + char(10)+
				                   @ErrorDescription

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_ReferenceRateReAnalyze_NP_Cur  
				DEALLOCATE db_ReferenceRateReAnalyze_NP_Cur

				GOTO PROCESSEND

		End

EXPORTNPA:

        ---------------------------------------------------------------------------
		-- Call the stored procedure to Export the successful number plan analysis
		-- into Reference Center
		----------------------------------------------------------------------------

		Begin Try

				set @ResultFlag = 0
				set @ErrorDescription = NULL

				Exec SP_BSExportReferenceReAnalyzeRates @VarNumberPlanAnalysisID , @UserID,
												        @ResultFlag Output,
												        @ErrorDescription Output

		End Try

		Begin Catch

				set @ErrorMsgStr = 'ERROR !!! During Number Plan Analysis Export for ID : ' + convert(varchar(20) ,  @VarNumberPlanAnalysisID) + '.' + ERROR_MESSAGE()

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_ReferenceRateReAnalyze_NP_Cur  
				DEALLOCATE db_ReferenceRateReAnalyze_NP_Cur

				GOTO PROCESSEND

		End Catch

		if ( @ResultFlag <> 0 )
		Begin

				set @ErrorMsgStr = 'ERROR !!! During Number Plan Analysis Export for ID : ' + convert(varchar(20) ,  @VarNumberPlanAnalysisID) + '.' + char(10)+
				                   @ErrorDescription

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_ReferenceRateReAnalyze_NP_Cur  
				DEALLOCATE db_ReferenceRateReAnalyze_NP_Cur

				GOTO PROCESSEND

		End

PROCESSNEXTREC:

		FETCH NEXT FROM db_ReferenceRateReAnalyze_NP_Cur
		INTO @VarNumberPlanAnalysisID , @VarSourceID , @VarAnalysisRegisterDate , @VarAnalysisStatusID
 
END   

CLOSE db_ReferenceRateReAnalyze_NP_Cur  
DEALLOCATE db_ReferenceRateReAnalyze_NP_Cur


PROCESSEND:

-----------------------------------------------------
--  Drop all temporary tables post processing of data
-----------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempReferenceRateReAnalyzeList') )
	Drop table #TempReferenceRateReAnalyzeList
GO
