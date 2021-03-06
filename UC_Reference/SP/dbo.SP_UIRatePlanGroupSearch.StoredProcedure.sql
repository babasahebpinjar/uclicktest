USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanGroupSearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIRatePlanGroupSearch]
(
	@RatePlanGroup varchar(60) =  NULL
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @RatePlanGroup is not Null ) and ( len(@RatePlanGroup) = 0 ) )
	set @RatePlanGroup = NULL

if ( ( @RatePlanGroup <> '_') and charindex('_' , @RatePlanGroup) <> -1 )
Begin

	set @RatePlanGroup = replace(@RatePlanGroup , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.RatePlanGroupID  as ID, tbl1.RatePlanGroup as Name '+
              ' From tb_RatePlanGroup tbl1 ' +
	          ' where tbl1.Flag & 1 <> 1 '  


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
			   When (@RatePlanGroup is NULL) then ''
			   When (@RatePlanGroup = '_') then ' and tbl1.RatePlanGroup like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@RatePlanGroup) =  1 ) and ( @RatePlanGroup = '%') ) then ''
			   When ( right(@RatePlanGroup ,1) = '%' ) then ' and tbl1.RatePlanGroup like ' + '''' + substring(@RatePlanGroup,1 , len(@RatePlanGroup) - 1) + '%' + ''''
			   Else ' and tbl1.RatePlanGroup like ' + '''' + @RatePlanGroup + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.RatePlanGroup' 

--print @SQLStr

Exec (@SQLStr)

Return 0
GO
