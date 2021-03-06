USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  Procedure [dbo].[SP_UIRatePlanGetDetails] 
(
	@RatePlanID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


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

Select tbl1.RatePlanID ,  tbl1.RatePlan , tbl1.RatePlanAbbrv, tbl2.AgreementID , tbl2.Agreement,
       tbl3.Direction , tbl3.DirectionID , tbl4.RatePlanGroupID , tbl4.RatePlanGroup,
	   tbl5.CurrencyID , tbl5.Currency , tbl6.ProductCatalogID , tbl6.ProductCatalog,
	   tbl1.IncreaseNoticePeriod , tbl1.DecreaseNoticePeriod , tbl1.BeginDate,
	   tbl1.EndDate, tbl1.ModifiedDate,
	   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
from tb_RatePlan tbl1
inner join tb_Agreement tbl2 on tbl1.AgreementID = tbl2.AgreementID
inner join tb_Direction tbl3 on tbl1.DirectionID = tbl3.DirectionID
inner join tb_RatePlanGroup tbl4 on tbl1.RatePlanGroupID = tbl4.RatePlanGroupID
inner join tb_Currency tbl5 on tbl1.CurrencyID = tbl5.CurrencyID
inner join tb_ProductCatalog tbl6 on tbl1.ProductCataLogID = tbl6.ProductCatalogID
where RatePlanID = @RatePlanID 


Return 0

GO
