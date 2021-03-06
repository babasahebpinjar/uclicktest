USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencySearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICurrencySearch]
(
	@Currency varchar(60) =  NULL
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @Currency is not Null ) and ( len(@Currency) = 0 ) )
	set @Currency = NULL

if ( ( @Currency <> '_') and charindex('_' , @Currency) <> -1 )
Begin

	set @Currency = replace(@Currency , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.CurrencyID  as ID, tbl1.Currency as Name '+
              ' From tb_Currency tbl1 ' +
	          ' where tbl1.Flag & 1 <> 1 '  


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
			   When (@Currency is NULL) then ''
			   When (@Currency = '_') then ' and tbl1.Currency like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@Currency) =  1 ) and ( @Currency = '%') ) then ''
			   When ( right(@Currency ,1) = '%' ) then ' and tbl1.Currency like ' + '''' + substring(@Currency,1 , len(@Currency) - 1) + '%' + ''''
			   Else ' and tbl1.Currency like ' + '''' + @Currency + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Currency' 

--print @SQLStr

Exec (@SQLStr)

Return 0
GO
