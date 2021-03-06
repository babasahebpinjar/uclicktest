USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountryList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICountryList]
(
    @Country varchar(60) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@Clause2 varchar(1000)


set @Country = rtrim(ltrim(@Country))

if (( @Country is not Null ) and ( len(@Country) = 0 ) )
	set @Country = NULL

if ( ( @Country <> '_') and charindex('_' , @Country) <> -1 )
Begin

	set @Country = replace(@Country , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.CountryID as ID, tbl1.Country as Name'+
              ' From tb_country tbl1 ' +
			  ' where tbl1.flag & 1 <> 1 '


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@Country is NULL) then ''
				   When (@Country = '_') then ' and tbl1.Country like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@Country) =  1 ) and ( @Country = '%') ) then ''
				   When ( right(@Country ,1) = '%' ) then ' and tbl1.Country like ' + '''' + substring(@Country,1 , len(@Country) - 1) + '%' + ''''
				   Else ' and tbl1.Country like ' + '''' + @Country + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Country ' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
