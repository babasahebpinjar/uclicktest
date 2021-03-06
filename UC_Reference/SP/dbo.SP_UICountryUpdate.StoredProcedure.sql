USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountryUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICountryUpdate]
(
    @CountryID int,
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

-------------------------------------------------------
-- Check the validity of the COUNTRYID passed to the 
-- API
-------------------------------------------------------

if ( ( @CountryID is null ) )
Begin

	set @ErrorDescription = 'ERROR!!! CountryID Cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End

if not exists (select 1 from tb_country where countryid = @CountryID )
Begin

	set @ErrorDescription = 'ERROR!!! No record exists for the country ID'
	set @ResultFlag = 1
	return 1

End

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

if exists ( select 1 from tb_country where ( country = ltrim(rtrim(@Country)) or countryabbrv = ltrim(rtrim(@CountryAbbrv))) and countryid <> @CountryID )
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
			set  @ErrorDescription = 'ERROR !!! Country code contains non numerical characters or spaces'
			set  @Tempstring = '' -- Set string length to 0  
			Return 1	



		End

		set @Tempstring = substring(@Tempstring , 2 , len(@Tempstring))

End


-------------------------------------------------------
-- Get the old list of country codes to ensure that
-- no dialed digits exist in the system, associated 
-- to these country codes, which are being removed
-- during the update process
-------------------------------------------------------
Declare @OldCountryCode varchar(100)

select @OldCountryCode = CountryCode
from tb_country
where countryid = @CountryID


Create table #OldDialCodeList (DialCode varchar(100)  collate SQL_Latin1_General_CP1_CI_AI)

insert into #OldDialCodeList
select * from dbo.FN_ParseCountryCodeList(@OldCountryCode)


-----------------------------------------------------------------
-- Parse the country code list and store in a temporary table
-----------------------------------------------------------------

Create table #DialCodeList (DialCode varchar(100) Collate SQL_Latin1_General_CP1_CI_AI )

insert into #DialCodeList
select * from dbo.FN_ParseCountryCodeList(@CountryCode)


-------------------------------------------------
-- Remove those country codes from the old list,
-- which are part of the update
-------------------------------------------------

delete from #OldDialCodeList
where DialCode in
(
	select DialCode
	from #DialCodeList
)


Select distinct dd.dialeddigits
into #tempDestination
from tb_Destination dest
inner join tb_dialeddigits dd on dest.destinationid = dd.destinationid
where dest.countryid = @CountryID

if exists (
				select 1
				from #tempDestination tbl1,
				#OldDialCodeList tbl2
				where substring(tbl1.dialeddigits, 1 , len(tbl2.DialCode) )  = tbl2.DialCode 
          )
Begin

		set  @ResultFlag = 1
		set  @ErrorDescription = 'ERROR !!! There are dial codes existing for country code(s) being removed from edited country'
		Return 1

End


---------------------------------------------------
-- Build a syntactically correct country code list
---------------------------------------------------

set @CountryCode = NULL

SELECT @CountryCode = COALESCE(@CountryCode + ', ', '') + DialCode 
FROM #DialCodeList

Drop table #DialCodeList
Drop table #tempDestination
Drop table #OldDialCodeList

-----------------------------------------------
-- Update the data into the tb_Country table 
-----------------------------------------------

Begin Try

		update tb_country
		set Country  = @Country,
		    CountryAbbrv  = @CountryAbbrv, 
			CountryCode = @CountryCode , 
			CountryTypeID  = @CountryTypeID, 
			ModifiedDate = getdate(), 
			ModifiedByID = @UserID , 
			Flag = 0
		where countryid = @CountryID


End Try

Begin Catch

		set  @ResultFlag = 1 
		set  @ErrorDescription = 'ERROR !!! Updating record for country. '+ ERROR_MESSAGE()
		Return 1	

End Catch

Return 0

GO
