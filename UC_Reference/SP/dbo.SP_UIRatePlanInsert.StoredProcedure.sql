USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanInsert]
(
	@RatePlan varchar(60),
	@RatePlanAbbrv varchar(50),
	@AgreementID int,
	@DirectionID int,
	@RatePlanGroupID int,
	@CurrencyID int,
	@ProductCataLogID int,
	@IncreaseNoticePeriod int,
	@DecreaseNoticePeriod int,
	@BeginDate Date,
	@EndDate Date,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int Output	
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-----------------------------------------------
-- Check and validate all the input parameters
-----------------------------------------------

if ( @AgreementID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End

if ( @DirectionID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Direction ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End

if ( @RatePlanGroupID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End

if ( @CurrencyID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Currency ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End

if ( @ProductCataLogID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Product Catalog ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End




if ( @BeginDate is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be NULL'
	set @ResultFlag = 1
	Return 1


End

if not exists (select 1 from tb_agreement where AgreementID =  @AgreementID)
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID is not valid and doesnot exist in the system'
	set @ResultFlag = 1
	Return 1


End

if not exists ( Select 1 from tb_direction where DirectionID = @DirectionID  )
Begin

	set @ErrorDescription = 'ERROR !!! Direction ID is not valid and doesnot exist in the system'
	set @ResultFlag = 1
	Return 1


End

if not exists ( Select 1 from tb_RatePlanGroup where RatePlanGroupID = @RatePlanGroupID  )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group ID is not valid and doesnot exist in the system'
	set @ResultFlag = 1
	Return 1


End

if not exists ( Select 1 from tb_Currency where CurrencyID = @CurrencyID  ) 
Begin

	set @ErrorDescription = 'ERROR !!! Currency ID is not valid and doesnot exist in the system'
	set @ResultFlag = 1
	Return 1


End

if not exists ( Select 1 from tb_ProductCatalog where ProductCatalogID = @ProductCataLogID  )
Begin

	set @ErrorDescription = 'ERROR !!! Product Catalog ID is not valid and doesnot exist in the system'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------------
-- Check that rate plan name and abbreviation are not NULL
----------------------------------------------------------------

if ((@RatePlan is NULL) or (@RatePlanAbbrv is NULL))
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan name or abbreviation cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

-------------------------------------------
-- Check validity of Begin and End Dates
-------------------------------------------

if (( @EndDate is not NULL ) and ( @BeginDate >= @EndDate ))
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be greater or equal to End Date'
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------------
-- Make sure that either Increase or DEcrease period are NULL
-- or are values greater than 0
--------------------------------------------------------------

if ((@IncreaseNoticePeriod is not NULL) and ( @IncreaseNoticePeriod <= 0 ))
Begin

	set @ErrorDescription = 'ERROR !!! Increase Notice Period has to be a value greater than 0'
	set @ResultFlag = 1
	Return 1

End

if ((@DecreaseNoticePeriod is not NULL) and ( @DecreaseNoticePeriod <= 0 ))
Begin

	set @ErrorDescription = 'ERROR !!! Decrease Notice Period has to be a value greater than 0'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------------
-- Check to ensure that no rate plan exists in the system
-- with the same name
------------------------------------------------------------

if exists ( select 1 from tb_rateplan where rtrim(ltrim(RatePlan)) = @RatePlan)
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan name is not unique'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------------------
-- Ensure that the Rate Plan direction is either inbound or outbound
---------------------------------------------------------------------

if ( @DirectionID not in (1,2) )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan can only be configured for Inbound or Outbound direction'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------------
-- Ensure that the product catalog should match the direction
-- of the rate plan
---------------------------------------------------------------

if ((@DirectionID = 1) and (@ProductCataLogID = -4 ) )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot select Vendor Destination Rating Product Catalog for Inbound Rate Plan'
	set @ResultFlag = 1
	Return 1

End

if ((@DirectionID = 2) and (@ProductCataLogID = -5 ) )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot select Customer Destination Rating Product Catalog for Outbound Rate Plan'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------------------------
-- Check that the date range for the new Rate Plan should be within 
-- the date -- range of agreement being active
------------------------------------------------------------------------

Declare @AgreementBeginDate datetime,
        @AgreementEndDate datetime

select @AgreementBeginDate = BeginDate,
       @AgreementEndDate = EndDate
From tb_Agreement
where AgreementId = @AgreementID

if ( @BeginDate <  @AgreementBeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan cannot begin before the Agreement'
	set @ResultFlag = 1
	Return 1


End

Else
Begin

	if ( @AgreementEndDate is not NULL ) -- Loop 1
	Begin
	        ---------------------------------------------------------------
	 		-- Agreement has ended, but the Rate Plan is still active infinitely
			---------------------------------------------------------------

			if ( @EndDate is NULL ) -- Loop 2 
			Begin

					set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but Rate Plan is active infinitely' 
					set @ResultFlag = 1
					Return 1

			End -- End Loop 2

			Else -- Loop 3
			Begin

			        ---------------------------------------------------------------------
					 -- Agreement has ended, but the Rate Plan is still active infinitely
					 --------------------------------------------------------------------

					if ( @EndDate is NULL ) -- Loop 4
					Begin 

							set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate,120) + ' ) , but Rate Plan is active infinitely' 
							set @ResultFlag = 1
							Return 1

					End -- End Loop 4

					Else -- Loop 5
					Begin

							------------------------------------------------------
							 -- Agreement has ended before the Rate Plan end date
							 -----------------------------------------------------

							if ( @EndDate > @AgreementEndDate ) -- Loop 6
							Begin

									set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but Rate Plan is ending later on ( ' + convert(varchar(10) , @EndDate , 120) + ' )'
									set @ResultFlag = 1
									Return 1

							End -- End Loop 6
							
					End -- End Loop 5

			End -- End Loop 3

	End -- End Loop 1

End


---------------------------------------------------------
-- Insert record into database for the new rate plan
---------------------------------------------------------

Begin Try

	insert into tb_RatePlan
	(
		RatePlan,
		RatePlanAbbrv,
		AgreementID,
		DirectionID,
		RatePlanGroupID,
		CurrencyID,
		ProductCataLogID,
		IncreaseNoticePeriod,
		DecreaseNoticePeriod,
		BeginDate,
		EndDate,
		ModifiedDate,
		ModifiedByID,
		Flag
	)
	Values
	(
		@RatePlan,
		@RatePlanAbbrv,
		@AgreementID,
		@DirectionID,
		@RatePlanGroupID,
		@CurrencyID,
		@ProductCataLogID,
		@IncreaseNoticePeriod,
		@DecreaseNoticePeriod,
		@BeginDate,
		@EndDate,
		GetDate(),
		@UserID,
		0
	)

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Creating new rate plan record.'+  ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch

Return 0
GO
