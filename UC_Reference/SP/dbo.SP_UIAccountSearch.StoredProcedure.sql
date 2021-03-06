USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountSearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIAccountSearch] 
(
    @Account varchar(60) = NULL,
    @AccountType varchar(60) = NULL,
    @Company varchar(60) = NULL,
    @StatusID int
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000),
	@Clause3 varchar(1000)


if (( @Account is not Null ) and ( len(@Account) = 0 ) )
	set @Account = NULL

if (( @AccountType is not Null ) and ( len(@AccountType) = 0 ) )
	set @AccountType = NULL

if (( @Company is not Null ) and ( len(@Company) = 0 ) )
	set @Company = NULL


if ( ( @Account <> '_') and charindex('_' , @Account) <> -1 )
Begin

	set @Account = replace(@Account , '_' , '[_]')

End

if ( ( @AccountType <> '_') and charindex('_' , @AccountType) <> -1 )
Begin

	set @AccountType = replace(@AccountType , '_' , '[_]')

End

if ( ( @Company <> '_') and charindex('_' , @Company) <> -1 )
Begin

	set @Company = replace(@Company , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.AccountID , tbl1.Account '+
              ' From tb_Account tbl1 ' +
	      ' inner join tb_Accounttype tbl2 on tbl1.AccountTypeID = tbl2.AccountTypeID ' +
	      ' inner join tb_Company tbl3 on tbl1.CompanyID = tbl3.COmpanyID ' +
	      ' where tbl1.Flag & 1 <> 1 '  +
	      Case
		   When @StatusID =  1 then ' and tbl1.Flag & 32 <> 32 '
		   When @StatusID =  2 then ' and tbl1.Flag & 32 = 32 '
		   Else ''
	      End
	      
	      

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


set @Clause2 = 
               Case
		   When (@AccountType is NULL) then ''
		   When (@AccountType = '_') then ' and tbl2.AccountType like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@AccountType) =  1 ) and ( @AccountType = '%') ) then ''
		   When ( right(@AccountType ,1) = '%' ) then ' and tbl2.AccountType like ' + '''' + substring(@AccountType,1 , len(@AccountType) - 1) + '%' + ''''
		   Else ' and tbl2.AccountType like ' + '''' + @AccountType + '%' + ''''
	       End


set @Clause3 = 
               Case
		   When (@Company is NULL) then ''
		   When (@Company = '_') then ' and tbl3.Company like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@Company) =  1 ) and ( @Company = '%') ) then ''
		   When ( right(@Company ,1) = '%' ) then ' and tbl3.Company like ' + '''' + substring(@Company,1 , len(@Company) - 1) + '%' + ''''
		   Else ' and tbl3.Company like ' + '''' + @Company + '%' + ''''
	       End




-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2 + @Clause3

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Account' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
