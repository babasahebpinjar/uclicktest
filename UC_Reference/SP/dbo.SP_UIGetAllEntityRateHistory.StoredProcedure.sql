USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAllEntityRateHistory]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetAllEntityRateHistory]
(
	@RatePlanID int,
	@DestinationID int,
	@CallTypeID int,
	@SelectDate Date,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0
	

-----------------------------------------------------------------------------
-- Check to ensure that the RatePlan ID is not NULL and exists in the system
-----------------------------------------------------------------------------

if ( @RatePlanID is null )
Begin
		set @ErrorDescription = 'ERROR !!! Rate Plan ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_RatePlan where RatePlanID = @RatePlanID )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Plan does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

----------------------------------------------------------------------
-- Check to ensure that DestinationID is not NULL and present in the
-- number plan associated with the rate plan
----------------------------------------------------------------------

if ( @DestinationID is null )
Begin
		set @ErrorDescription = 'ERROR !!! Destination ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_Destination where DestinationID = @DestinationID )
Begin

		set @ErrorDescription = 'ERROR !!! Destination does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

Declare @NumberPlanID int

select @NumberPlanID = NumberPlanID
from tb_Destination
where DestinationID = @DestinationID

if ( @NumberPlanID > 0 )  -- Could be a Vendor or a customer destination
Begin

		if not exists (
					  		select 1
							from uc_Commerce.dbo.tb_Source src
							inner join tb_numberplan np on src.SourceID = np.ExternalCode
							where src.RatePlanID = @RatePlanID
							and np.numberplanID = @NumberPlanID
					  )
		Begin

				set @ErrorDescription = 'ERROR !!! Destination is not associated to the Rate Plan'
				set @ResultFlag = 1
				Return 1

		End



End

-----------------------------------------------------------
-- Ensure that Call Type ID is not NULL and a valid value
-----------------------------------------------------------

if ( @CallTypeID is null )
Begin
		set @ErrorDescription = 'ERROR !!! CallType ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_CallType where CallTypeID = @CallTypeID )
Begin

		set @ErrorDescription = 'ERROR !!! CallType does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

-----------------------------------------------------------------
-- Return the appropriate result set for the input parameters
-----------------------------------------------------------------

select rt.BeginDate , rt.EndDate , rm.RatingMethod,
       ri.RateItemDescription + '-' + '(' + rdb.RateDimensionBand + ')' as RateType,
	   rtd.Rate,
	   Case
			When rt.EndDate is not NULL Then
				 Case
						When @SelectDate  > rt.EndDate then 'Historical'
						When @SelectDate  <= rt.EndDate then 
							Case
								When @SelectDate between rt.BeginDate and rt.EndDate then 'Current'
								Else 'Future'
							End
				 End
			When  rt.EndDate is NULL Then
				 Case
						When @SelectDate between rt.BeginDate and isnull(rt.EndDate ,@SelectDate)  then 'Current'
						Else 'Future'					
				 End
		
	   End as RateStatus
from tb_rate rt
inner join tb_ratedetail rtd on rt.rateid = rtd.rateid
inner join tb_RateNumberIdentifier rni on rtd.RateTypeID = rni.RateItemID and rt.RatingMethodID = rni.RatingMethodID
inner join tb_RateDimensionBand rdb on rni.RateDimension1BandID = rdb.RateDimensionBandID 
inner join tb_RateItem ri on rni.RateItemID = ri.RateItemID
inner join tb_RatingMethod rm on rt.RatingMethodID = rm.RatingMethodID
where rt.rateplanID = @RatePlanID
and DestinationID = @DestinationID
and calltypeID = @CallTypeID
order by rt.begindate desc

Return 0

GO
