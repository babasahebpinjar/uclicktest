USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UINumberPlanList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UINumberPlanList]
(
	@NumberPlan varchar(100) = NULL , 
	@NumberPlanTypeID int
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @NumberPlan is not Null ) and ( len(@NumberPlan) = 0 ) )
	set @NumberPlan = NULL

if ( ( @NumberPlan <> '_') and charindex('_' , @NumberPlan) <> -1 )
Begin

	set @NumberPlan = replace(@NumberPlan , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.NumberPlanID as ID, tbl1.NumberPlan as Name'+
              ' From tb_NumberPlan tbl1 ' +
			  ' where flag & 1 <> 1 '  +
			  ' and numberplantypeid = ' + convert(varchar(20) , @NumberPlanTypeID)


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
			   When (@NumberPlan is NULL) then ''
			   When (@NumberPlan = '_') then ' and tbl1.Numberplan like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@NumberPlan) =  1 ) and ( @NumberPlan = '%') ) then ''
			   When ( right(@NumberPlan ,1) = '%' ) then ' and tbl1.Numberplan like ' + '''' + substring(@NumberPlan,1 , len(@NumberPlan) - 1) + '%' + ''''
			   Else ' and tbl1.Numberplan like ' + '''' + @NumberPlan + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.NumberPlan ' 

--print @SQLStr

Exec (@SQLStr)


Return
GO
