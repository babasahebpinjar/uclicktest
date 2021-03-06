USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTINCrossOUTASRReportTabular_Old]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTINCrossOUTASRReportTabular_Old]
(
     @ReportID int,
	 @StartDate datetime,
	 @EndDate datetime,  
	 @CallTypeID int,
	 @INAccountIDList nvarchar(max), 
	 @OUTAccountIDList nvarchar(max),
	 @INCommercialTrunkIDList nvarchar(max),
	 @OUTCommercialTrunkIDList nvarchar(max),
	 @INTechnicalTrunkIDList nvarchar(max),
	 @OUTTechnicalTrunkIDList nvarchar(max),
	 @CountryIDList nvarchar(max),
	 @DestinationIDList nvarchar(max),
 	 @ServiceLevelIDList nvarchar(max),
	 @Level1Param varchar(100),
	 @Level2Param varchar(100),
	 @Level3Param varchar(100),
	 @Level4Param varchar(100),
	 @TotalResult nvarchar(max) Output,
 	 @ErrorDescription varchar(2000) Output,
	 @ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @AllCountryFlag int = 0,
        @AllServiceLevelFlag int = 0,
		@AllDestinationFlag int = 0,
		@INAllAccountFlag int = 0,
		@INAllCommercialTrunkFlag int = 0,
		@INAllTechnicalTrunkFlag int = 0,
		@OUTAllAccountFlag int = 0,
		@OUTAllCommercialTrunkFlag int = 0,
		@OUTAllTechnicalTrunkFlag int = 0,
		@SQLStr1 nvarchar(max),
		@SQLStr2 nvarchar(max),
		@SQLStr3 nvarchar(max),
		@SQLStr  nvarchar(max)

---------------------------------------------------------
-- Check if the Report is valid and exists in he system
---------------------------------------------------------

if not exists ( select 1 from tb_Report where ReportID = @ReportID and Flag & 1 <> 1 )
Begin

		set @ErrorDescription = 'ERROR !!! Report ID is not valid or is not active (flag <> 0)'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

-------------------------------------------------------------------
-- Check if the different Level parameters are valid and are part
-- of the summarization parameters for this report 
-------------------------------------------------------------------

Declare @Level1ParamID int,
        @Level2ParamID int,
		@Level3ParamID int,
		@Level4ParamID int

Declare @Level1ParamFormat varchar(100),
        @Level2ParamFormat varchar(100),
		@Level3ParamFormat varchar(100),
		@Level4ParamFormat varchar(100)

if ( (@Level1Param is NOT NULL) )
Begin

	select @Level1ParamID = RptSummarizeParameterID,
	       @Level1ParamFormat = RptSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level1Param
	and flag & 1 <> 1

	if ( @Level1ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 1 parameter : ' + @Level1Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level1ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 1 parameter : ' + @Level1Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End

if ( (@Level2Param is NOT NULL) )
Begin

	select @Level2ParamID = RptSummarizeParameterID,
	       @Level2ParamFormat = RptSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level2Param
	and flag & 1 <> 1

	if ( @Level2ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 2 parameter : ' + @Level2Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level2ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 2 parameter : ' + @Level2Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End

if ( (@Level3Param is NOT NULL) )
Begin

	select @Level3ParamID = RptSummarizeParameterID,
	       @Level3ParamFormat = RptSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level3Param
	and flag & 1 <> 1

	if ( @Level3ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 3 parameter : ' + @Level3Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level3ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 3 parameter : ' + @Level3Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End



if ( (@Level4Param is NOT NULL) )
Begin

	select @Level4ParamID = RptSummarizeParameterID,
	       @Level4ParamFormat = RptSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level4Param
	and flag & 1 <> 1

	if ( @Level4ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 4 parameter : ' + @Level4Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level4ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 4 parameter : ' + @Level4Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End



-------------------------------------------------------------
-- Set the CALL TYPE to NULL in case the value passed is 0
-- indicating that all CALL TYPES need to be considered
-------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL

--Select 'Step 1..' , getdate()

Begin Try

-----------------------------------------------------------------
-- Create table for list of selected IN Accounts from the parameter
-- passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINAccountIDTable') )
				Drop table #TempINAccountIDTable

		Create Table #TempINAccountIDTable (AccountID varchar(100) )


		insert into #TempINAccountIDTable
		select * from FN_ParseValueList ( @INAccountIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempINAccountIDTable where ISNUMERIC(AccountID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN Account IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempINAccountIDTable 
						where AccountID = 0
				  )
		Begin

                  set @INAllAccountFlag = 1
				  GOTO PROCESSOUTACCOUNT
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempINAccountIDTable 
						where AccountID not in
						(
							Select AccountID
							from ReferenceServer.UC_Reference.dbo.tb_Account
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN Account IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSOUTACCOUNT:

-----------------------------------------------------------------
-- Create table for list of selected OUT Accounts from the parameter
-- passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTAccountIDTable') )
				Drop table #TempOUTAccountIDTable

		Create Table #TempOUTAccountIDTable (AccountID varchar(100) )


		insert into #TempOUTAccountIDTable
		select * from FN_ParseValueList ( @OUTAccountIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempOUTAccountIDTable where ISNUMERIC(AccountID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT Account IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempOUTAccountIDTable 
						where AccountID = 0
				  )
		Begin

                  set @OUTAllAccountFlag = 1
				  GOTO PROCESSINCOMMERCIALTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempOUTAccountIDTable 
						where AccountID not in
						(
							Select AccountID
							from ReferenceServer.UC_Reference.dbo.tb_Account
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT Account IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSINCOMMERCIALTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected IN Commercial Trunks from the 
-- parameter passed
-----------------------------------------------------------------
		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINCommercialTrunkIDTable') )
				Drop table #TempINCommercialTrunkIDTable

		Create table #TempINCommercialTrunkIDTable (CommercialTrunkID varchar(100) )


		insert into #TempINCommercialTrunkIDTable
		select * from FN_ParseValueList ( @INCommercialTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempINCommercialTrunkIDTable where ISNUMERIC(CommercialTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN CommercialTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the CommercialTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempINCommercialTrunkIDTable 
						where CommercialTrunkID = 0
				  )
		Begin

                  set @INAllCommercialTrunkFlag = 1
				  GOTO PROCESSOUTCOMMERCIALTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the CommercialTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempINCommercialTrunkIDTable 
						where CommercialTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID = 9 -- Commercial trunk
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN CommercialTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSOUTCOMMERCIALTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected OUT Commercial Trunks from the 
-- parameter passed
-----------------------------------------------------------------
		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTCommercialTrunkIDTable') )
				Drop table #TempOUTCommercialTrunkIDTable

		Create table #TempOUTCommercialTrunkIDTable (CommercialTrunkID varchar(100) )


		insert into #TempOUTCommercialTrunkIDTable
		select * from FN_ParseValueList ( @OUTCommercialTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempOUTCommercialTrunkIDTable where ISNUMERIC(CommercialTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT CommercialTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the CommercialTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempOUTCommercialTrunkIDTable 
						where CommercialTrunkID = 0
				  )
		Begin

                  set @OUTAllCommercialTrunkFlag = 1
				  GOTO PROCESSINTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the CommercialTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempOUTCommercialTrunkIDTable 
						where CommercialTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID = 9 -- Commercial trunk
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT CommercialTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSINTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected IN Technical Trunks from the 
-- parameter passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINTechnicalTrunkIDTable') )
				Drop table #TempINTechnicalTrunkIDTable

		Create table #TempINTechnicalTrunkIDTable (TechnicalTrunkID varchar(100) )


		insert into #TempINTechnicalTrunkIDTable
		select * from FN_ParseValueList ( @INTechnicalTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempINTechnicalTrunkIDTable where ISNUMERIC(TechnicalTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN TechnicalTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the TechnicalTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempINTechnicalTrunkIDTable 
						where TechnicalTrunkID = 0
				  )
		Begin

                  set @INAllTechnicalTrunkFlag = 1
				  GOTO PROCESSOUTTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the TechnicalTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempINTechnicalTrunkIDTable 
						where TechnicalTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID <> 9 -- Technical Trunks
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN TechnicalTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSOUTTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected IN Technical Trunks from the 
-- parameter passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTTechnicalTrunkIDTable') )
				Drop table #TempOUTTechnicalTrunkIDTable

		Create table #TempOUTTechnicalTrunkIDTable (TechnicalTrunkID varchar(100) )


		insert into #TempOUTTechnicalTrunkIDTable
		select * from FN_ParseValueList ( @OUTTechnicalTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempOUTTechnicalTrunkIDTable where ISNUMERIC(TechnicalTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT TechnicalTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the TechnicalTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempOUTTechnicalTrunkIDTable 
						where TechnicalTrunkID = 0
				  )
		Begin

                  set @OUTAllTechnicalTrunkFlag = 1
				  GOTO PROCESSCOUNTRY
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the TechnicalTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempOUTTechnicalTrunkIDTable 
						where TechnicalTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID <> 9 -- Technical Trunks
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT TechnicalTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSCOUNTRY:
-----------------------------------------------------------------
-- Create table for list of all selected Countries from the 
-- parameter passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
				Drop table #TempCountryIDTable


		Create table #TempCountryIDTable (CountryID varchar(100) )
		
		insert into #TempCountryIDTable
		select * from FN_ParseValueList ( @CountryIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempCountryIDTable where ISNUMERIC(CountryID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the countries have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempCountryIDTable 
						where CountryID = 0
				  )
		Begin

                  set @AllCountryFlag = 1
				  GOTO PROCESSSERVICELEVEL
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Country IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempCountryIDTable 
						where CountryID not in
						(
							Select CountryID
							from ReferenceServer.UC_Reference.dbo.tb_country
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End 

PROCESSSERVICELEVEL:

		-----------------------------------------------------------------
		-- Create table for list of all selected Service Levels from the 
		-- parameter passed
		-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
				Drop table #TempServiceLevelIDTable

		Create table #TempServiceLevelIDTable (ServiceLevelID varchar(100) )


		insert into #TempServiceLevelIDTable
		select * from FN_ParseValueList ( @ServiceLevelIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempServiceLevelIDTable where ISNUMERIC(ServiceLevelID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Service Level IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Service Levels have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempServiceLevelIDTable 
						where ServiceLevelID = 0
				  )
		Begin

				  set @AllServiceLevelFlag = 1
				  GOTO PROCESSDESTINATIONLIST
				  
		End
		
        --------------------------------------------------------------------------
		-- Check to ensure that all the Service Level IDs passed are valid values
		--------------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempServiceLevelIDTable 
						where ServiceLevelID not in
						(
							Select ServiceLevelID
							from ReferenceServer.UC_Reference.dbo.tb_ServiceLevel
							where DirectionID = 1 -- All INBOUND Service Levels
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Service Level IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End 

PROCESSDESTINATIONLIST:

		-----------------------------------------------------------------
		-- Create table for list of all selected Destinations from the 
		-- parameter passed
		-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
				Drop table #TempDestinationIDTable

		Create table  #TempDestinationIDTable (DestinationID varchar(100) )


		insert into #TempDestinationIDTable
		select * from FN_ParseValueList ( @DestinationIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempDestinationIDTable where ISNUMERIC(DestinationID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End

		------------------------------------------------------
		-- Check if the All the Detinations have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempDestinationIDTable 
						where DEstinationID = 0
				  )
		Begin

				  set @AllDestinationFlag = 1
				  GOTO GENERATEREPORT
				  
		End
		
        --------------------------------------------------------------------------
		-- Check to ensure that all the Destinations passed are valid values
		--------------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempDestinationIDTable 
						where DestinationID not in
						(
							Select DestinationID
							from ReferenceServer.UC_Reference.dbo.tb_Destination
							where numberplanID = -1 -- All Routing Destinations
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

		End 


GENERATEREPORT:

		---------------------------------------------------------------------
		-- Select the subset of data on which report needs to be run based on
		-- Call Date
		---------------------------------------------------------------------

		select summ.CallDate , summ.CallDuration , summ.CircuitDuration,
			   summ.Answered , summ.Seized,
			   summ.CallTypeID , isnull(ct.CallType  , '*****') as CallType,
			   summ.INAccountID , isnull(INAcc.Account , '*****') as INAccount,
			   summ.OutAccountID , isnull(OUTAcc.Account , '*****') as OUTAccount,
			   summ.INTrunkID , isnull(INTrnk.Trunk + '/' + INSwt.Switch , '*****') as INTrunk,
			   summ.OUTTrunkID , isnull(OUTTrnk.Trunk + '/' + OUTSwt.Switch , '*****') as OUTTrunk,
			   summ.INCommercialTrunkID , isnull(INCommTrnk.Trunk , '*****') as INCommercialTrunk,
			   summ.OUTCommercialTrunkID , isnull(OUTCommTrnk.Trunk , '*****') as OUTCommercialTrunk,
			   summ.INDestinationID , isnull(INDest.Destination , '*****') as INDestination,
			   summ.OUTDestinationID , isnull(OUTDest.Destination , '*****') as OUTDestination,
			   summ.RoutingDestinationID , isnull(RDest.Destination , '*****') as RoutingDestination,
			   Cou.CountryID , isnull(Cou.Country , '*****') as Country,
			   summ.INServiceLevelID , isnull(INSl.ServiceLevel , '*****') as INServiceLevel,
			   summ.OUTServiceLevelID , isnull(OUTSl.ServiceLevel , '*****') as OUTServiceLevel,
			   summ.INRoundedCallDuration , summ.OUTRoundedCallDuration,
			   summ.INChargeDuration , summ.OUTChargeDuration
        into #TempDailyINCrossOUTMart
		from tb_DailyINCrossOutTrafficMart summ
		left join ReferenceServer.UC_Reference.dbo.tb_Account INAcc on summ.INAccountID = INAcc.AccountID
		left join ReferenceServer.UC_Reference.dbo.tb_Account OUTAcc on summ.OUTAccountID = OUTAcc.AccountID
		left join ReferenceServer.UC_Reference.dbo.tb_Trunk INTrnk on summ.INTrunkID = INTrnk.TrunkID
		left join ReferenceServer.UC_Reference.dbo.tb_Trunk OUTTrnk on summ. OUTTrunkID = OUTTrnk.TrunkID
		left join ReferenceServer.UC_Reference.dbo.tb_Trunk INCommTrnk on summ.INCommercialTrunkID = INCommTrnk.TrunkID
		left join ReferenceServer.UC_Reference.dbo.tb_Trunk OUTCommTrnk on summ.OUTCommercialTrunkID = OUTCommTrnk.TrunkID
		left join ReferenceServer.UC_Reference.dbo.tb_Destination INDest on summ.INdestinationID = INDest.DestinationID
		left join ReferenceServer.UC_Reference.dbo.tb_Destination OUTDest on summ.OUTdestinationID = OUTDest.DestinationID
		left join ReferenceServer.UC_Reference.dbo.tb_Destination RDest on summ.RoutingdestinationID = RDest.DestinationID
		left join ReferenceServer.UC_Reference.dbo.tb_Country Cou on RDest.CountryID = Cou.CountryID
		left join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel INSl on summ.INServiceLevelID = INSl.ServiceLevelID
		left join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel OUTSl on summ.OUTServiceLevelID = OUTSl.ServiceLevelID
		left join ReferenceServer.UC_Reference.dbo.tb_CallType ct on summ.CallTypeID = ct.CallTypeID
		left join ReferenceServer.UC_Reference.dbo.tb_Switch INSwt on INTrnk.SwitchID = INSwt.SwitchID
		left join ReferenceServer.UC_Reference.dbo.tb_Switch OUTSwt on OUTTrnk.SwitchID = OUTSwt.SwitchID
		where CallDate between @StartDate and @EndDate
		and summ.CalltypeID  = isnull(@CalltypeID , summ.CallTypeID)



		-----------------------------------------------------
		-- Extract the result set for the input parameters
		-----------------------------------------------------

		if ( (@Level1Param is NULL) and (@Level2Param is NULL) and (@Level3Param is NULL) and (@Level4Param is NULL) )
		Begin

				set @SQLStr1 = 'Select ''' + 'None' + ''' as Param1, ''' + 'None' + ''' as Param2, ''' + Char(10) +
							   'None' + ''' as Param3, ''' + 'None' + ''' as Param4, ' + Char(10) +
							  'Answered, Seized, ' + char(10) +
							  'convert(int ,(convert(Decimal(19,2) , tbl1.Answered) * 100.0 )/tbl1.Seized) as ASR , ' + char(10) +
							  'convert(Decimal(19,2),CallDuration/60.0) Minutes ,' +  char(10) +
							  ' Case ' + char(10) +
							  '     When tbl1.Answered = 0 then 0 ' + char(10) +
							  '     Else convert(decimal(19,2) ,(convert(Decimal(19,2),CallDuration/60.0))/tbl1.Answered) ' + char(10) +
							  ' End as ALOC' + char(10)

         End
		 Else
		 Begin

		 
				set @SQLStr1 = 'Select ' + isnull(@Level1ParamFormat, '''None''') + ' as Param1, ' + isnull(@Level2ParamFormat, '''None''') + ' as Param2, ' + Char(10) +
							   isnull(@Level3ParamFormat, '''None''') + ' as Param3, ' + isnull(@Level4ParamFormat,'''None''') + ' as Param4, ' + Char(10) +
							  'sum(tbl1.Answered) as Answered, sum(tbl1.Seized) as Seized, ' + char(10) +
							  'convert(int ,(convert(Decimal(19,2) , sum(tbl1.Answered)) * 100.0 )/sum(tbl1.Seized)) as ASR , ' + char(10) +
							  'convert(Decimal(19,2),sum(CallDuration/60.0)) Minutes ,' +  char(10) +
							  ' Case ' + char(10) +
							  '     When sum(tbl1.Answered) = 0 then 0 ' + char(10) +
							  '     Else convert(decimal(19,2) ,(convert(Decimal(19,2),sum(CallDuration/60.0)))/sum(tbl1.Answered))' + char(10) +
							  ' End as Aloc' + char(10)

		 End

         set @SQLStr2 = ' from #TempDailyINCrossOUTMart tbl1 ' + char(10) +
		                Case
						    When @INAllAccountFlag = 1 then ''
							Else ' inner join #TempINAccountIDTable tbl2 on tbl1.INAccountID = tbl2.AccountID ' + char(10)
						End + 
		                Case
						    When @OUTAllAccountFlag = 1 then ''
							Else ' inner join #TempOUTAccountIDTable tbl3 on tbl1.OUTAccountID = tbl3.AccountID ' + char(10)
						End + 
		                Case
						    When  @AllServiceLevelFlag = 1 then ''
							Else ' inner join #TempServiceLevelIDTable tbl4 on tbl1.INServiceLevelID = tbl4.ServiceLevelID ' + char(10)
						End +
		                Case
						    When  @AllDestinationFlag  = 1 then ''
							Else ' inner join #TempDestinationIDTable tbl5 on tbl1.RoutingDestinationID = tbl5.DestinationID ' + char(10)
						End +
		                Case
						    When  @AllCountryFlag = 1 then ''
							Else ' inner join #TempCountryIDTable tbl6 on tbl1.CountryID = tbl6.CountryID ' + char(10)
						End +
		                Case
						    When  @INAllCommercialTrunkFlag  = 1 then ''
							Else ' inner join #TempINCommercialTrunkIDTable tbl7 on tbl1.INCommercialTrunkID = tbl7.CommercialTrunkID ' + char(10)
						End +
		                Case
						    When  @OUTAllCommercialTrunkFlag  = 1 then ''
							Else ' inner join #TempOUTCommercialTrunkIDTable tbl8 on tbl1.OUTCommercialTrunkID = tbl8.CommercialTrunkID ' + char(10)
						End +
		                Case
						    When  @INAllTechnicalTrunkFlag   = 1 then ''
							Else ' inner join #TempINTechnicalTrunkIDTable tbl9 on tbl1.INTrunkID = tbl9.TechnicalTrunkID ' + char(10)
						End +
		                Case
						    When  @OUTAllTechnicalTrunkFlag   = 1 then ''
							Else ' inner join #TempOUTTechnicalTrunkIDTable tbl10 on tbl1.OUTTrunkID = tbl10.TechnicalTrunkID ' + char(10)
						End 


        if ( (@Level1Param is NULL) and (@Level2Param is NULL) and (@Level3Param is NULL) and (@Level4Param is NULL) )
		Begin

		        set @SQLStr3 = ''

		End
		Else
		Begin

				set @SQLStr3 = 'Where tbl1.CallDate between ''' + convert(varchar(20) , @StartDate, 120) + ''' and ''' + convert(varchar(20) , @EndDate, 120) + '''' +  char(10) +
							   'Group by ' + 
							   Case

									When @Level1Param is NULL then ''
									Else @Level1Param + ','

							   End +
							   Case

									 When @Level2Param is NULL then ''
									 Else @Level2Param + ','

							   End +
							   Case

									When @Level3Param is NULL then ''
									Else @Level3Param + ','

							   End +
							   Case

									 When @Level4Param is NULL then ''
									 Else @Level4Param 

							   End 

                   if ( right( @SQLStr3, 1) = ',')
				        set  @SQLStr3 = substring(@SQLStr3 , 1 , len(@SQLStr3) - 1)

        End

        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

     	Exec (@SQLStr)

		----------------------------------------------------------------
		-- Extract the TOTAL of the result set for display in the report
		----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalResult') )
				Drop table #TempTotalResult


        Create Table #TempTotalResult
		(
			Param1 varchar(100),
			Param2 varchar(100),
			Param3 varchar(100),
			Param4 varchar(100),
			Answered int,
			Seized int,
			ASR int,
			Minutes Decimal(19,2),
			ALOC Decimal(19,2)
		)

		set @SQLStr1 = 'Select ''TOTAL'', ''None'', ' + Char(10) +
						'''None'', ''None'', ' + Char(10) +
						'sum(tbl1.Answered), sum(tbl1.Seized), ' + char(10) +
						'convert(int ,(convert(Decimal(19,2) , sum(tbl1.Answered)) * 100.0 )/sum(tbl1.Seized)) , ' + char(10) +
						'convert(Decimal(19,2),sum(CallDuration/60.0)) ,' +  char(10) +
						' Case ' + char(10) +
						'     When sum(tbl1.Answered) = 0 then 0 ' + char(10) +
						'     Else convert(decimal(19,2) ,(convert(Decimal(19,2),sum(CallDuration/60.0)))/sum(tbl1.Answered))' + char(10) +
						' End' + char(10)

		set @SQLStr3 = 'Where tbl1.CallDate between ''' + convert(varchar(20) , @StartDate, 120) + ''' and ''' + convert(varchar(20) , @EndDate, 120) + ''''

		set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		insert into #TempTotalResult 
     	Exec (@SQLStr)

		 Select @TotalResult = 
		        Param1 + '|' + Param2 + '|' + Param3 + '|' + Param4 + '|' +
				convert(varchar(100) ,isnull(Answered,0)) + '|' +
				convert(varchar(100) ,isnull(Seized,0)) + '|' +
				convert(varchar(100) ,isnull(ASR, 0)) + '|' +
				convert(varchar(100) ,isnull(Minutes, 0)) + '|' +
				convert(varchar(100) ,isnull(ALOC, 0))
		from #TempTotalResult


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting IN OUT ASR Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINAccountIDTable') )
		Drop table #TempINAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalResult') )
		Drop table #TempTotalResult

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTAccountIDTable') )
		Drop table #TempOUTAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINTechnicalTrunkIDTable') )
		Drop table #TempINTechnicalTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTTechnicalTrunkIDTable') )
		Drop table #TempOUTTechnicalTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINCommercialTrunkIDTable') )
		Drop table #TempINCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTCommercialTrunkIDTable') )
		Drop table #TempOUTCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
		Drop table #TempServiceLevelIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
		Drop table #TempDestinationIDTable


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINCrossOUTMart') )
		Drop table #TempDailyINCrossOUTMart

GO
