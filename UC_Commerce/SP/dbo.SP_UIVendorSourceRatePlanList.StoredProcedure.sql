USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorSourceRatePlanList]    Script Date: 5/2/2020 6:18:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorSourceRatePlanList]
(
    @RatePlan varchar(60) = NULL,
	@AccountID int = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


set @RatePlan = rtrim(ltrim(@RatePlan))

if (( @RatePlan is not Null ) and ( len(@RatePlan) = 0 ) )
	set @RatePlan = NULL

if ( ( @RatePlan <> '_') and charindex('_' , @RatePlan) <> -1 )
Begin

	set @RatePlan = replace(@RatePlan , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.RatePlanID as ID , tbl1.RatePlan as Name '+
              ' From UC_Reference.dbo.tb_RatePlan tbl1 ' +
			  ' inner join UC_Reference.dbo.tb_Productcatalog tbl2 on tbl1.ProductcatalogID = tbl2.ProductCatalogID ' +
			  ' inner join UC_Reference.dbo.tb_ProductCatalogType tbl3 on tbl2.ProductCatalogTypeID = tbl3.ProductCatalogTypeID ' +
			  ' inner join UC_Reference.dbo.tb_Agreement tbl4 on tbl1.AgreementID = tbl4.AgreementID ' +
			  ' where tbl1.flag & 1 <> 1 ' +
			  ' and tbl3.ProductCatalogTypeID = -2 ' + -- Only hubbing rating rate plans
			  ' and tbl1.ProductCatalogID = -4 ' + -- Vendor Destination Rating
			  Case
					When @AccountID is NULL then ''
					Else ' and tbl4.AccountID = ' + convert(varchar(20) , @AccountID) 

			  End 


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
		   When (@RatePlan is NULL) then ''
		   When (@RatePlan = '_') then ' and tbl1.RatePlan like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@RatePlan) =  1 ) and ( @RatePlan = '%') ) then ''
		   When ( right(@RatePlan ,1) = '%' ) then ' and tbl1.RatePlan like ' + '''' + substring(@RatePlan,1 , len(@RatePlan) - 1) + '%' + ''''
		   Else ' and tbl1.RatePlan like ' + '''' + @RatePlan + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 
set @SQLStr = @SQLStr + ' order by tbl1.RatePlan'

Exec (@SQLStr)


Return





GO
