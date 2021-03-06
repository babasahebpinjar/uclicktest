USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountList]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIAccountList] 
(
    @Account varchar(60) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)



if (( @Account is not Null ) and ( len(@Account) = 0 ) )
	set @Account = NULL


if ( ( @Account <> '_') and charindex('_' , @Account) <> -1 )
Begin

	set @Account = replace(@Account , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.AccountID  as ID, tbl1.Account as Name '+
              ' From UC_Reference.dbo.tb_Account tbl1 ' +
	          ' where tbl1.Flag & 1 <> 1 '  +
			  ' and tbl1.Flag & 32 <> 32 '
  
	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@Account is NULL) then ''
		   When (@Account = '_') then ' and tbl1.Account like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@Account) =  1 ) and ( @Account = '%') ) then ''
		   When ( right(@Account ,1) = '%' ) then ' and tbl1.Account like ' + '''' + substring(@Account,1 , len(@Account) - 1) + '%' + ''''
		   Else ' and tbl1.Account like ' + '''' + @Account + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Account' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
