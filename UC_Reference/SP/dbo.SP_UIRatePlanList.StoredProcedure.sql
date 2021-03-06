USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIRatePlanList]
(
    @RatePlan varchar(60) = NULL,
	@AgreementID int = NULL,
	@DirectionID int = NULL
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
              ' From tb_RatePlan tbl1 ' +
			  ' inner join tb_Productcatalog tbl2 on tbl1.ProductcatalogID = tbl2.ProductCatalogID ' +
			  ' inner join tb_ProductCatalogType tbl3 on tbl2.ProductCatalogTypeID = tbl3.ProductCatalogTypeID ' +
			  ' where tbl1.flag & 1 <> 1 ' +
			  ' and tbl3.ProductCatalogTypeID = -2 ' + -- Only hubbing rating rate plans
			  Case
					When @AgreementID is NULL then ''
					Else ' and tbl1.AgreementID = ' + convert(varchar(20) , @AgreementID) 

			  End +
			  Case
					When @DirectionID is NULL then ''
					Else ' and tbl1.DirectionID in ( ' + convert(varchar(20) ,	@DirectionID) + ', 3)' 

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

----------------------------------------
-- Create temporary table to store data 
----------------------------------------

create table #TempRaterPlanUnsorted ( RaterPlanID int , RaterPlan varchar(60) )

create table #TempRaterPlanSorted ( RecordID int identity(1,1) ,RaterPlanID int , RaterPlan varchar(60) )

insert into #TempRaterPlanUnsorted
Exec (@SQLStr)

------------------------------------------------------------
-- Insert record for 'NOT APPLICABLE' rate plan into the
-- rate Plan List
------------------------------------------------------------

insert into #TempRaterPlanUnsorted
Select RatePlanID , RatePlan
from tb_RatePlan
where RatePlanID = -2 -- (Not Applicable Rate Plan)
and DirectionID = 3 -- Bidirectional
and flag & 1 <> 1

Insert into #TempRaterPlanSorted ( RaterPlanID , RaterPlan )
select RaterPlanID , RaterPlan
from #TempRaterPlanUnsorted
where RaterPlanID < 0
order by RaterPlanID

Insert into #TempRaterPlanSorted ( RaterPlanID , RaterPlan )
select RaterPlanID , RaterPlan
from #TempRaterPlanUnsorted
where RaterPlanID > 0
order by RaterPlan

select RaterPlanID as ID , RaterPlan as Name
from #TempRaterPlanSorted
order by RecordID

---------------------------------------------
-- Drop temporary tables created in process
---------------------------------------------

Drop table #TempRaterPlanUnsorted
Drop table #TempRaterPlanSorted

Return


Return





GO
