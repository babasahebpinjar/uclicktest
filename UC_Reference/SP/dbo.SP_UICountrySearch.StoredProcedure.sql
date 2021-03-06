USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountrySearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICountrySearch]
(
    @Country varchar(60) = NULL,
	@CountryCode varchar(100) = NULL,
	@CountryTypeID int
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@Clause2 varchar(1000)


set @Country = rtrim(ltrim(@Country))
set @CountryCode = rtrim(ltrim(@CountryCode))

if (( @Country is not Null ) and ( len(@Country) = 0 ) )
	set @Country = NULL

if ( ( @Country <> '_') and charindex('_' , @Country) <> -1 )
Begin

	set @Country = replace(@Country , '_' , '[_]')

End


if (( @CountryCode is not Null ) and ( len(@CountryCode) = 0 ) )
	set @CountryCode = NULL

if ( ( @CountryCode <> '_') and charindex('_' , @CountryCode) <> -1 )
Begin

	set @CountryCode = replace(@CountryCode , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.CountryID , tbl1.Country , tbl1.CountryAbbrv , tbl1.CountryCode , tbl2.CountryType , tbl1.ModifiedDate , UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser '+
              ' From tb_country tbl1 ' +
			  ' inner join tb_countrytype tbl2 on tbl1.countrytypeid = tbl2.countrytypeid ' +
			  ' where tbl1.flag & 1 <> 1 ' +
			  Case
					When @CountryTypeID = 0 then ''
					Else ' and tbl2.CountryTypeId = ' + convert(varchar(20) , @CountryTypeID) 

			  End


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


set @Clause2 = 
               Case
		   When (@CountryCode is NULL) then ''
		   When (@CountryCode = '_') then ' and tbl1.CountryCode like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@CountryCode) =  1 ) and ( @CountryCode = '%') ) then ''
		   When ( right(@CountryCode ,1) = '%' ) then ' and tbl1.CountryCode like ' + '''' + substring(@CountryCode,1 , len(@CountryCode) - 1) + '%' + ''''
		   Else ' and tbl1.CountryCode like ' + '''' + @CountryCode + '%' + ''''
	       End



-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Country , tbl1.CountryCode' 

--print @SQLStr

Exec (@SQLStr)

Return




GO
