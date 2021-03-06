USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountryDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICountryDelete]
(
    @CountryID int,
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

---------------------------------------------------------
-- Check if there exists any destination associated with 
-- the country
---------------------------------------------------------


if exists (
				select 1
				from tb_Destination 
				where countryid = @CountryID
          )
Begin

		set  @ResultFlag = 1
		set  @ErrorDescription = 'ERROR !!! There are dial codes existing for country being deleted from system'
		Return 1

End


---------------------------------
-- Delete record for country 
---------------------------------

Begin Try

		Delete from tb_country
		where countryid = @CountryID


End Try

Begin Catch

		set  @ResultFlag = 1 
		set  @ErrorDescription = 'ERROR !!! Deleting record for country. '+ ERROR_MESSAGE()
		Return 1	

End Catch

Return 0

GO
