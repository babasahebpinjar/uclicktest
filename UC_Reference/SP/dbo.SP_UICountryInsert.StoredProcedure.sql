USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountryInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UICountryInsert]
(
	@Country varchar(60),
	@CountryAbbrv varchar(60),
	@CountryCode varchar(100),
	@CountryTypeID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------------
-- Check to ensure that Country name , abbrv and code are not NULL
------------------------------------------------------------------

if ( ( @Country is null ) or ((@Country is not NULL) and (len(ltrim(rtrim(@Country))) = 0) ))
Begin

	set @ErrorDescription = 'ERROR!!! Country Cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End


if ( ( @CountryAbbrv is null ) or ((@CountryAbbrv is not NULL) and (len(ltrim(rtrim(@CountryAbbrv))) = 0) ))
Begin

	set @ErrorDescription = 'ERROR!!! Country Abbreviation Cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End


if ( ( @CountryCode is null ) or ((@CountryCode is not NULL) and (len(ltrim(rtrim(@CountryCode))) = 0) ))
Begin

	set @ErrorDescription = 'ERROR!!! Country Code Cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End


--------------------------------------------------------------
-- Check to ensure that the country name and abbreviation are
-- unique
--------------------------------------------------------------

if exists ( select 1 from tb_country where country = ltrim(rtrim(@Country)) or countryabbrv = ltrim(rtrim(@CountryAbbrv)) )
Begin

	set @ErrorDescription = 'ERROR!!! Country name or abbreviation have to be unique'
	set @ResultFlag = 1
	return 1

End

-------------------------------------------------------
-- Parse the Country code to ensure that the codes
-- are valid
------------------------------------------------------

Declare @Tempstring varchar(100) = @CountryCode

while ( len(@Tempstring) > 0 )
Begin

if ( isnumeric(substring(@Tempstring , 1 , 1)) = 0 )
Begin

	----------------------------------------------
	-- Only numeric values and comma allowed
	----------------------------------------------

	set  @ResultFlag = 1 -- Invalid Value
	set  @ErrorDescription = 'ERROR !!! Country code contains non numerical characters'
	set  @Tempstring = '' -- Set string length to 0  
	Return 1	



End

set @Tempstring = substring(@Tempstring , 2 , len(@Tempstring))

End

-----------------------------------------------------------------
-- Parse the country code list and store in a temporary table
-----------------------------------------------------------------

Create table #DialCodeList (DialCode varchar(100) )

insert into #DialCodeList
select * from dbo.FN_ParseCountryCodeList(@CountryCode)

set @CountryCode = NULL

SELECT @CountryCode = COALESCE(@CountryCode + ', ', '') + DialCode 
FROM #DialCodeList

Drop table #DialCodeList

-----------------------------------------------
-- Insert the data into the tb_Country table 
-----------------------------------------------

Begin Try

		insert into tb_country
		( Country , CountryAbbrv ,  CountryCode , CountryTypeID , ModifiedDate , ModifiedByID , Flag)
		values
		( @Country , @CountryAbbrv, @CountryCode , @CountryTypeID , getdate() , @UserID , 0 )


End Try

Begin Catch

		set  @ResultFlag = 1 
		set  @ErrorDescription = 'ERROR !!! Inserting record for new country. '+ ERROR_MESSAGE()
		Return 1	

End Catch

Return 0
GO
