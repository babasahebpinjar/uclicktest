USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICompanySearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICompanySearch]
(
    @CompanyLetters varchar(60) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @CompanyLetters is not Null ) and ( len(@CompanyLetters) = 0 ) )
	set @CompanyLetters = NULL

if ( ( @CompanyLetters <> '_') and charindex('_' , @CompanyLetters) <> -1 )
Begin

	set @CompanyLetters = replace(@CompanyLetters , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.CompanyId , tbl1.Company , tbl1.ModifiedDate , UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser '+
              ' From tb_Company tbl1 ' +
	      ' where flag & 1 <> 1 ' 


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@CompanyLetters is NULL) then ''
		   When (@CompanyLetters = '_') then ' and tbl1.Company like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@CompanyLetters) =  1 ) and ( @CompanyLetters = '%') ) then ''
		   When ( right(@CompanyLetters ,1) = '%' ) then ' and tbl1.Company like ' + '''' + substring(@CompanyLetters,1 , len(@CompanyLetters) - 1) + '%' + ''''
		   Else ' and tbl1.Company like ' + '''' + @CompanyLetters + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Company ' 

--print @SQLStr

Exec (@SQLStr)

Return



GO
