USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRerateCreate]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRerateCreate]
(
    @UserID int,
	@RerateName varchar(500),
    @BeginDate datetime,
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
	@ConditionClause nvarchar(max),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check to see if the User ID is valid and is active
----------------------------------------------------------

if not exists ( select 1 from ReferenceServer.UC_Admin.dbo.tb_Users where UserID = @UserID and USerstatusID = 1 )
Begin

		set @ErrorDescription = 'ERROR !!!! User ID passed for extract creation does not exist or is inactive'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------------------------
-- Check to see that there does not exist another Rerate Job with the same name
-- for the user
---------------------------------------------------------------------------------

if exists ( select 1 from tb_Rerate where RerateName = @RerateName and userID = @UserID )
Begin

		set @ErrorDescription = 'ERROR !!!! There already exists a Rerate Job in the system by the same name for this user'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End


-----------------------------------------------------------------------
-- Check to ensure that the Begin Date is not greater than the End Date
-----------------------------------------------------------------------

if ( @BeginDate > @EndDate )
Begin

		set @ErrorDescription = 'ERROR !!!! Begin Date for Rerate Job cannot be greater than the End Date'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------
-- Check to ensure that Call TypeID is valid and exists
-- in the system
----------------------------------------------------------

if ( @CallTypeID is NULL )
	set @CallTypeID = 0

if ( (@CallTypeID <> 0)  and not exists (select 1 from ReferenceServer.UC_Reference.dbo.tb_CallType where CallTypeID = @CallTypeID ) )
Begin

		set @ErrorDescription = 'ERROR !!!! Call Type passed for extract does not exist in the system'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------
-- Start the validation for all the List parameters to ensure
-- everything is correct
---------------------------------------------------------------


Begin Try


-----------------------------------------------------------------
-- Create table for list of selected IN Accounts from the parameter
-- passed
-----------------------------------------------------------------

        if ( @INAccountIDList is NULL )
		Begin
			
				set @INAccountIDList = '0'
				GOTO PROCESSOUTACCOUNT

		End

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

                  set @INAccountIDList = '0'
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

        if ( @OUTAccountIDList is NULL )
		Begin
			
				set @OUTAccountIDList = '0'
				GOTO PROCESSINCOMMERCIALTRUNK

		End

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

                  set @OUTAccountIDList = '0'
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


        if ( @INCommercialTrunkIDList is NULL )
		Begin
			
				set @INCommercialTrunkIDList = '0'
				GOTO PROCESSOUTCOMMERCIALTRUNK

		End

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

                  set @INCommercialTrunkIDList = '0'
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

        if ( @OUTCommercialTrunkIDList is NULL )
		Begin
			
				set @OUTCommercialTrunkIDList = '0'
				GOTO PROCESSINTRUNK

		End

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

                  set @OUTCommercialTrunkIDList = '0'
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

        if ( @INTechnicalTrunkIDList is NULL )
		Begin
			
				set @INTechnicalTrunkIDList = '0'
				GOTO PROCESSOUTTRUNK

		End

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

                  set @INTechnicalTrunkIDList = '0'
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

        if ( @OUTTechnicalTrunkIDList is NULL )
		Begin
			
				set @OUTTechnicalTrunkIDList = '0'
				GOTO PROCESSCOUNTRY

		End

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

                  set @OUTTechnicalTrunkIDList = '0'
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


        if ( @CountryIDList is NULL )
		Begin
			
				set @CountryIDList = '0'
				GOTO PROCESSSERVICELEVEL

		End

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

                  set @CountryIDList = '0'
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


        if ( @ServiceLevelIDList is NULL )
		Begin
			
				set @ServiceLevelIDList = '0'
				GOTO PROCESSDESTINATIONLIST

		End

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

				  set @ServiceLevelIDList = '0'
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

        if ( @DestinationIDList is NULL )
		Begin
			
				set @DestinationIDList = '0'
				GOTO PROCESSCONDITIONCLAUSE

		End

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

				  set @DestinationIDList = '0'
				  GOTO PROCESSCONDITIONCLAUSE
				  
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

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While Validating multi select parameter list. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

PROCESSCONDITIONCLAUSE:

---------------------------------------------------------
-- Valdiate the condition clause parameter to ensure it
-- is semantically and syntactically correct
----------------------------------------------------------

if ( len(@ConditionClause) = 0 )
	set @ConditionClause = NULL


if ( @ConditionClause is not null )
Begin

	Begin Try

			set @ErrorDescription = NULL
			set @ResultFlag = 0

			Exec SP_BSValdiateRerateCondtionClause @ConditionClause , 
			                                           @ErrorDescription Output,
													   @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

				  set @ResultFlag = 1
			      GOTO ENDPROCESS

			End

	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR !!! While validating the condition clause for the rerate job. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End Catch

End

--------------------------------------------------------------------
-- insert the new Rerate Job data into the schema for Registration
--------------------------------------------------------------------

Declare @RerateID int

Begin Transaction ins_Rerate

Begin Try

			------------------------------------------------
			-- Insert record into the table tb_Rerate
			------------------------------------------------

			insert into tb_Rerate
			(
				RerateName , UserID , RerateStatusID,
                RerateRequestDate,ModifiedDate, ModifiedByID
			)
			Values
			(
				@RerateName , @UserID , -1 ,
				Getdate() , GetDate() , @UserID
			)

			select @RerateID = RerateID
			from tb_Rerate
			where RerateName = @RerateName
			and RerateStatusID = -1 -- Registered
			and UserID = @UserID

			insert into tb_RerateParamList
			(
				RerateID, BeginDate,
				EndDate, CallTypeID, INAccountList,
				OUTAccountList, INCommercialTrunkList,
				OUTCommercialTrunkList, INTechnicalTrunkList,
				OUTTechnicalTrunkList,CountryList,
				DestinationList, ServiceLevelList,
				ConditionClause,
				ModifiedDate, ModifiedByID
			)
			Values
			(
				@RerateID , @BeginDate,
				@EndDate , @CallTypeID , @INAccountIDList,
				@OUTAccountIDList , @INCommercialTrunkIDList,
				@OUTCommercialTrunkIDList,@INTechnicalTrunkIDList,
				@OUTTechnicalTrunkIDList , @CountryIDList,
				@DestinationIDList, @ServiceLevelIDList,
				@ConditionClause , 
				getdate() , @UserID
			)

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!! While inserting record for new Rerate Job. ' + ERROR_MESSAGE()
			set @ResultFlag = 1

			Rollback Transaction ins_Rerate

			GOTO ENDPROCESS

End Catch


Commit transaction ins_Rerate

-------------------------------------------------------------
-- Check to see if Rerate Job via email has been enabled in 
--  the system
-------------------------------------------------------------

Declare @SendRerateAlertViaEmail int

select @SendRerateAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendRerateAlertViaEmail'
and AccessScopeID = -8 

if ( @SendRerateAlertViaEmail = 1 )
Begin
		Exec SP_BSRerateAlert @RerateID
End 

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDisplayFieldIDTable') )
		Drop table #TempDisplayFieldIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINAccountIDTable') )
		Drop table #TempINAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTAccountIDTable') )
		Drop table #TempOUTAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINCommercialTrunkIDTable') )
		Drop table #TempINCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTCommercialTrunkIDTable') )
		Drop table #TempOUTCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINTechnicalTrunkIDTable') )
		Drop table #TempINTechnicalTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTTechnicalTrunkIDTable') )
		Drop table #TempOUTTechnicalTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
		Drop table #TempServiceLevelIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
		Drop table #TempDestinationIDTable
GO
