USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanAssociatedNumberPlan]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanAssociatedNumberPlan]
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

---------------------------------------------------
-- create a temporary table to store the data
-- This is done delibrately to ensure that either
-- empty table or result set is returned
-- HANDLE THE REQUIREMENT FOR GUI
----------------------------------------------------

create table #TempAssociatedNP
(
	NumberPlan varchar(100),
	NumberPlanAbbrv varchar(60),
	NumberPlanType varchar(100)
)

------------------------------------------------------------------
-- Depending on the combinations, get the approipriate information
------------------------------------------------------------------

if ((@DirectionID = 2) and (@ProductcatalogID = -4) ) -- Outbound Vendor Based Rate Plan
Begin

        insert into #TempAssociatedNP (NumberPlan , NumberPlanAbbrv , NumberPlanType)
		Select np.NumberPlan , np.NumberPlanAbbrv , npt.NumberPlanType
		from UC_Commerce.dbo.tb_source src
		inner join tb_numberplan np on src.sourceid = np.ExternalCode
		inner join tb_NumberPlanType npt on np.NumberPlanTypeID = npt.NumberPlanTypeID
		where src.rateplanID = @RatePlanID
		and src.SourceTypeID = -1 -- Vendor Source

End

if ((@DirectionID = 2) and (@ProductcatalogID = -2) ) -- Outbound Reference Based Rate Plan
Begin

        insert into #TempAssociatedNP (NumberPlan , NumberPlanAbbrv , NumberPlanType)
		Select np.NumberPlan , np.NumberPlanAbbrv , npt.NumberPlanType
		from tb_numberplan np 
		inner join tb_NumberPlanType npt on np.NumberPlanTypeID = npt.NumberPlanTypeID
		where np.numberplanid = -1 -- OB numbering Plan

End

if ((@DirectionID = 1) and (@ProductcatalogID = -2) ) -- Inbound Reference Based Rate Plan
Begin

        insert into #TempAssociatedNP (NumberPlan , NumberPlanAbbrv , NumberPlanType)
		Select np.NumberPlan , np.NumberPlanAbbrv , npt.NumberPlanType
		from tb_numberplan np 
		inner join tb_NumberPlanType npt on np.NumberPlanTypeID = npt.NumberPlanTypeID
		where np.numberplanid = -2 -- IB numbering Plan

End

if ((@DirectionID = 1) and (@ProductcatalogID = -5) ) -- Inbound Customer Based Rate Plan
Begin

        insert into #TempAssociatedNP (NumberPlan , NumberPlanAbbrv , NumberPlanType)
		Select np.NumberPlan , np.NumberPlanAbbrv , npt.NumberPlanType
		from UC_Commerce.dbo.tb_source src
		inner join tb_numberplan np on src.sourceid = np.ExternalCode
		inner join tb_NumberPlanType npt on np.NumberPlanTypeID = npt.NumberPlanTypeID
		where src.rateplanID = @RatePlanID
		and src.SourceTypeID = -3 -- Customer Source

End


select NumberPlan , NumberPlanAbbrv , NumberPlanType
from #TempAssociatedNP

-------------------------------------------
-- Drop temporary tables post processing
-------------------------------------------

Drop table #TempAssociatedNP

Return 0
GO
