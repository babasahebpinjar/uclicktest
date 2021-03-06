USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingScenarioHubbingCombinations]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingScenarioHubbingCombinations]
(
	@AgreementID int,
	@CommercialTrunkIDList nvarchar(max),
	@CallTypeIDList nvarchar(max),
	@CountryIDList nvarchar(max),
	@DirectionIDList nvarchar(max),
	@ServiceLevelIDList nvarchar(max),
	@BeginDate Date,
	@EndDate Date,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

-- Attribute1 = Agreement
-- Attribute2 = Commercial Trunk
-- Attribute3 = Call Type
-- Attribute4 = Country
-- Attribute5 = Direction

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------
-- Check Validity of all the input parameters to ensure data integrity
----------------------------------------------------------------------

if ( @AgreementID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @BeginDate is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

----------------------------------
-- Check the validy of the Dates
----------------------------------

if ( ( @EndDate is not NULL ) and ( @BeginDate >= @EndDate ) )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be greater than or equal to End Date'
	set @ResultFlag = 1
	Return 1

End



---------------------------------------------------------------
-- Ensure that all input parameters are valid IDs existing in
-- the system
---------------------------------------------------------------

if not exists ( select 1 from tb_Agreement where AgreementID = @AgreementID )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID not valid and does not exist in system'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------
-- ****** COMMERCIAL TRUNK START *****
---------------------------------------

-------------------------------------------------------
-- Get the list of Commercial Trunks into temp table
-------------------------------------------------------

Declare @CommercialTrunkList table (CommercialTrunkID varchar(100) )

insert into @CommercialTrunkList
select * from FN_ParseValueList( @CommercialTrunkIDList )

------------------------------------------------------------------------------
-- Check to ensure that none of the Commercial trunk ID values are non numeric
-------------------------------------------------------------------------------

if exists ( select 1 from @CommercialTrunkList where ISNUMERIC(CommercialTrunkID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Commercial Trunk IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------------
-- Check to ensure that Agreement and Commercial Trunk belong
-- to the same Account
--------------------------------------------------------------

Declare @AgreementAccountID int,
        @CommercialTrunkAccountID int,
		@RatePlanAccountID int,
		@RatePlanDirectionID int

select @AgreementAccountID = AccountID
from tb_Agreement
where agreementID = @AgreementID

if exists ( 
				select 1 
				from @CommercialTrunkList 
				where CommercialTrunkID not in
				(
					Select trunkID
					from tb_Trunk
					where trunktypeID = 9
					and flag & 1 <> 1
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Commercial Trunk IDs passed contain value(s) which are not valid or do not have the correct trunk type'
	set @ResultFlag = 1
	Return 1

End

if exists ( 
				select 1 
				from @CommercialTrunkList  tbl1
				inner join tb_trunk tbl2 on tbl1.CommercialTrunkID = tbl2.TrunkID
				where tbl2.AccountID  <> @AgreementAccountID
				
			)
Begin

	set @ErrorDescription = 'ERROR !!! Commercial Trunk and Agreement do not belong to the same account'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------
-- ****** COMMERCIAL TRUNK END *****
---------------------------------------

---------------------------------------
-- ****** DIRECTION START *****
---------------------------------------

----------------------------------------------------------------
-- Since this is a multi record step, we need to parse the comma
-- separated values to get Direction IDs
----------------------------------------------------------------

Declare @DirectionList table (DirectionID varchar(100) )

insert into @DirectionList
select * from FN_ParseValueList( @DirectionIDList )

------------------------------------------------------------------------------
-- Check to ensure that none of the Direction ID values are non numeric
-------------------------------------------------------------------------------

if exists ( select 1 from @DirectionList where ISNUMERIC(DirectionID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Direction IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End

if exists ( 
			Select 1 from @DirectionList where DirectionID not in (1,2)
		  )
Begin

	set @ErrorDescription = 'ERROR !!! Direction has to be either Inbound or Outbound '
	set @ResultFlag = 1
	Return 1

End

---------------------------------------
-- ****** DIRECTION END *****
---------------------------------------

-------------------------------------
-- ******* CALL TYPE START *******
-------------------------------------
----------------------------------------------------------------
-- Since this is a multi record step, we need to parse the comma
-- separated values to get Direction IDs
----------------------------------------------------------------

Declare @CallTypeList table (CallTypeID varchar(100) )

insert into @CallTypeList
select * from FN_ParseValueList( @CallTypeIDList )

------------------------------------------------------------------------------
-- Check to ensure that none of the Call Type ID values are non numeric
-------------------------------------------------------------------------------

if exists ( select 1 from @CallTypeList where ISNUMERIC(CallTypeID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Call Type IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End


if exists (
			 select 1 from @CallTypeList 
			 where CallTypeID not in
			 (
				select calltypeID
				from tb_CallType
				where useflag & 64 = 64 -- Rating enabled Call Types

			 )
		  )
Begin

	set @ErrorDescription = 'ERROR !!! List of Call Type IDs passed contain invalid value(S)'
	set @ResultFlag = 1
	Return 1

End

-------------------------------------
-- ******* CALL TYPE END *******
-------------------------------------

----------------------------------------
-- *********** COUNTRY START **********
----------------------------------------

Declare @CountryIDTable table (CountryID varchar(100) )

insert into @CountryIDTable
select * from FN_ParseValueList ( @CountryIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from @CountryIDTable where ISNUMERIC(CountryID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End

-------------------------------------------------------------------
-- Check to ensure that all the Country IDs passed are valid values
-------------------------------------------------------------------
		
if exists ( 
				select 1 
				from @CountryIDTable 
				where CountryID not in
				(
					Select CountryID
					from tb_Country
					where flag & 1 <> 1
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------
-- *********** COUNTRY END **********
----------------------------------------

-----------------------------------------------
-- *********** SERVICE LEVEL START **********
-----------------------------------------------

Declare @ServiceLevelIDTable table (ServiceLevelID varchar(100) )

insert into @ServiceLevelIDTable
select * from FN_ParseValueList ( @ServiceLevelIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from @ServiceLevelIDTable where ISNUMERIC(ServiceLevelID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Service Level IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End

-----------------------------------------------------------------------
-- If a Value of 0 is being passed then set the service level as NULL,
-- indicating that it is applicable for all the service levels
-----------------------------------------------------------------------

Declare @AllServiceLevelsFlag int = 0

if exists ( select 1 from @ServiceLevelIDTable where convert(int ,ServiceLevelID) = 0)
Begin

		set @AllServiceLevelsFlag = 1

End

Else
Begin

		-------------------------------------------------------------------------
		-- Check to ensure that all the Service Level IDs passed are valid values
		-------------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from @ServiceLevelIDTable 
						where ServiceLevelID not in
						(
							Select ServiceLevelID
							from tb_ServiceLevel
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Service Level IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

		End

End

--------------------------------------------
-- *********** SERVICE LEVEL END **********
--------------------------------------------

------------------------------------------------------------------------
-- Check that the date range for the new Rating Scenario should be within 
-- the date range of agreement being active
------------------------------------------------------------------------

Declare @AgreementBeginDate datetime,
        @AgreementEndDate datetime

select @AgreementBeginDate = BeginDate,
       @AgreementEndDate = EndDate
From tb_Agreement
where AgreementId = @AgreementID

if ( @BeginDate <  @AgreementBeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario(s) cannot begin before the Agreement'
	set @ResultFlag = 1
	Return 1


End

Else
Begin

	if ( @AgreementEndDate is not NULL ) -- Loop 1
	Begin
	        ---------------------------------------------------------------
	 		-- Agreement has ended, but the Scenario is still active infinitely
			---------------------------------------------------------------

			if ( @EndDate is NULL ) -- Loop 2 
			Begin

					set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate , 120) + ' ) , but Rating Scenario(s) is active infinitely' 
					set @ResultFlag = 1
					Return 1

			End -- End Loop 2

			Else -- Loop 3
			Begin

			        -----------------------------------------------------------------
					 -- Agreement has ended, but the Scenario is still active infinitely
					 ----------------------------------------------------------------

					if ( @EndDate is NULL ) -- Loop 4
					Begin 

							set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but Rating Scenario(s) is active infinitely' 
							set @ResultFlag = 1
							Return 1

					End -- End Loop 4

					Else -- Loop 5
					Begin

							-----------------------------------------------
							 -- Agreement has ended before the Scenario end date
							 ----------------------------------------------

							if ( @EndDate > @AgreementEndDate ) -- Loop 6
							Begin

									set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but Rating Scenario(s) is ending later on ( ' + convert(varchar(10) , @EndDate, 120) + ' )'
									set @ResultFlag = 1
									Return 1

							End -- End Loop 6
							
					End -- End Loop 5

			End -- End Loop 3

	End -- End Loop 1

End


---------------------------------------------------------------------
-- Get all the relevant combinations depending on the selected data
-- in the wizard
---------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllRatingScenarioCombinations') )
	Drop table #TempAllRatingScenarioCombinations

select @AgreementID as AgreementID, 
       TBL1.CommercialTrunkID , TBL1.CommercialTrunk,
	   100 as Percentage,
	   TBL2.CallTypeID , TBL2.CallType,
	   TBL3.CountryID , TBL3.Country,
	   TBL4.DirectionID , TBL4.Direction,
	   @BeginDate as BeginDate , @EndDate as EndDate,
	   TBL5.TariffTypeID , TBL5.TariffType,
	   TBL6.RatePlanID , TBL6.RatePlan 
into #TempAllRatingScenarioCombinations	         
from 
(
	Select tbl2.TrunkID as CommercialTrunkID , tbl2.Trunk as CommercialTrunk
	from @CommercialTrunkList tbl1
	inner join tb_trunk tbl2 on tbl1.CommercialTrunkID = tbl2.TrunkID
) TBL1
cross join
(
	Select tbl2.CallTypeID , tbl2.CallType
	from @CallTypeList tbl1
	inner join tb_CallType tbl2 on tbl1.CallTypeID = tbl2.CallTypeID
) TBL2
cross join
(
	Select tbl2.CountryID  , tbl2.Country 
	from @CountryIDTable tbl1
	inner join tb_Country tbl2 on tbl1.CountryID = tbl2.CountryID
) TBL3
cross join
(
	Select tbl2.DirectionID  , tbl2.Direction 
	from @DirectionList tbl1
	inner join tb_Direction tbl2 on tbl1.DirectionID = tbl2.DirectionID
) TBL4
cross join
(
	Select TariffTypeID  , TariffType 
	from tb_TariffType
	Where TariffTypeID = 2 -- BILATERAL
) TBL5
cross join
(
	Select RatePlanID  , RatePlan 
	from tb_RatePlan
	Where RatePlanID = -2
) TBL6


---------------------------------------------------------------------
-- If this is to be applied for All Service Levels , then pass the 
-- value as 0 for Service Level
---------------------------------------------------------------------

if ( @AllServiceLevelsFlag = 1 )
Begin

	select AgreementID, 
		   CommercialTrunkID , CommercialTrunk,
		   Percentage,
		   CallTypeID , CallType,
		   CountryID , Country,
		   DirectionID , Direction,
		   BeginDate , EndDate,
		   TariffTypeID , TariffType,
		   RatePlanID ,RatePlan,
		   0 as ServiceLevelID , 'All Service Level' as ServiceLevel
	From #TempAllRatingScenarioCombinations	

End
Else
Begin

	select AgreementID, 
		   CommercialTrunkID , CommercialTrunk,
		   Percentage,
		   CallTypeID , CallType,
		   CountryID , Country,
		   tbl1.DirectionID , tbl1.Direction,
		   BeginDate , EndDate,
		   TariffTypeID , TariffType,
		   RatePlanID ,RatePlan,
		   tbl2.ServiceLevelID , tbl2.ServiceLevel
	From #TempAllRatingScenarioCombinations tbl1
	inner join tb_ServiceLevel tbl2 on tbl1.DirectionID = tbl2.DirectionID 
	inner join @ServiceLevelIDTable tbl3 on tbl2.ServiceLevelID = convert(int ,tbl3.ServiceLevelID)


End


--------------------------------------------------------
-- Drop all the temporary tables created during the process
-----------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllRatingScenarioCombinations') )
	Drop table #TempAllRatingScenarioCombinations


Return 0
GO
