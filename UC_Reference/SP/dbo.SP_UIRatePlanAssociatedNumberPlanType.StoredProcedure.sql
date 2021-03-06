USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanAssociatedNumberPlanType]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanAssociatedNumberPlanType]
(
	@RatePlanID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription  = NULL
set @ResultFlag = 0

-------------------------------------------------------------------------------
-- Check to ensure that the rate plan ID is not NULL and exists in the system
-------------------------------------------------------------------------------

if ( @RatePlanID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End

if not exists (select 1 from tb_RatePlan where RatePlanID =  @RatePlanID)
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan ID is not valid and doesnot exist in the system'
	set @ResultFlag = 1
	Return 1


End

------------------------------------------------------------------
-- Get product catalog information of the rate plan to determine 
-- number plan
------------------------------------------------------------------

Declare @ProductCatalogID int,
        @DirectionID int

select @ProductCatalogID = ProductcatalogID,
       @DirectionID = DirectionID
from tb_RatePlan
where rateplanId = @RatePlanID

------------------------------------------------------------------
-- Depending on the combinations, get the approipriate information
------------------------------------------------------------------

if ((@DirectionID = 2) and (@ProductcatalogID = -4) ) -- Outbound Vendor Based Rate Plan
Begin

        Select 1 as ID , 'Reference Destination Rating' as Name
		union
		Select 2 as ID , 'Vendor Destination Rating'

End

if ((@DirectionID = 2) and (@ProductcatalogID = -2) ) -- Outbound Reference Based Rate Plan
Begin

		Select 1 as ID , 'Reference Destination Rating' as Name

End

if ((@DirectionID = 1) and (@ProductcatalogID = -5) ) -- Inbound Customer Based Rate Plan
Begin

        Select 1 as ID , 'Reference Destination Rating' as Name
		union
		Select 3 as ID , 'Customer Destination Rating'

End

if ((@DirectionID = 1) and (@ProductcatalogID = -2) ) -- Inbound Reference Based Rate Plan
Begin

		Select 1 as ID , 'Reference Destination Rating' as Name

End



Return 0
GO
