USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPersonInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIPersonInsert]
(
	@PersonTypeID int,
	@LastName varchar(50),
	@MI varchar(1) = NULL,
	@FirstName varchar(50),
	@Address1 varchar(50) = NULL,
	@Address2 varchar(50)  = NULL,
	@City varchar(30) = NULL,
	@State varchar(32) = NULL,
	@Zip varchar(16) = NULL,
	@Country varchar(50) = NULL,
	@WorkPhone varchar(30) = NULL,
	@HomePhone varchar(30) = NULL,
	@CellPhone varchar(30) = NULL,
	@Pager varchar(30) = NULL,
	@WorkFax varchar(30) = NULL,
	@HomeFax varchar(30) = NULL,
	@EmailAddress varchar(50),
	@Salutation varchar(16),
	@Company varchar(50) = NULL,
	@Title varchar(50) = NULL,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As


Declare @StatusFlag int = 0

set @ResultFlag = 0
set @ErrorDescription = NULL

---------------------------------------------------------
-- Ensure that the following fields do not have NULL
-- or blank values:
-- First Name
-- Last Name
-- Salutation
-- Email Address
---------------------------------------------------------

if ( (@LastName is NULL) or  ( (@LastName is not NULL) and (len(@LastName) = 0) ) )
Begin

		set @ErrorDescription = 'ERROR !!! Last Name of the person is compulsory'
		set @ResultFlag = 1
		Return 1

End

if ( (@FirstName is NULL) or  ( (@FirstName is not NULL) and (len(@FirstName) = 0) ) )
Begin

		set @ErrorDescription = 'ERROR !!! First Name of the person is compulsory'
		set @ResultFlag = 1
		Return 1

End

if ( (@Salutation is NULL) or  ( (@Salutation is not NULL) and (len(@Salutation) = 0) ) )
Begin

		set @ErrorDescription = 'ERROR !!! Salutation of the person is compulsory'
		set @ResultFlag = 1
		Return 1

End

if ( (@EmailAddress is NULL) or  ( (@EmailAddress is not NULL) and (len(@EmailAddress) = 0) ) )
Begin

		set @ErrorDescription = 'ERROR !!! Email Address of the person is compulsory'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------------
-- Make sure that First name and Last name are syntactically correct
--------------------------------------------------------------------

if (dbo.FN_ValidatePersonName(@FirstName) = 1)
Begin

		set @ErrorDescription = 'ERROR !!! First name contains invalid or special characters'
		set @ResultFlag = 1
		Return 1

End

if (dbo.FN_ValidatePersonName(@LastName) = 1)
Begin

		set @ErrorDescription = 'ERROR !!! Last name contains invalid or special characters'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------------
-- Make sure that the email ID of the person is syntactically valid
-------------------------------------------------------------------

set @StatusFlag = 0

if (dbo.FN_ValidateEmailAddress(@EmailAddress) =  1)
Begin

		set @ErrorDescription = 'ERROR !!! Email Address is not valid. Please check and correct the same'
		set @ResultFlag = 1
		Return 1

End

---------------------------------------------------------------------
-- Make sure that home, cell, work, fax and pager phone numbers are 
-- syntactically correct
---------------------------------------------------------------------

if  ( ( @WorkPhone is not NULL ) and ( dbo.FN_CheckPhoneNumber(@WorkPhone) = 1 ) )
Begin

		set @ErrorDescription = 'ERROR !!! Work Phone number should be empty or a valid value containing only - and + non numeric characters'
		set @ResultFlag = 1
		Return 1

End

if  ( ( @HomePhone is not NULL ) and ( dbo.FN_CheckPhoneNumber(@HomePhone) = 1 ) )
Begin

		set @ErrorDescription = 'ERROR !!! Home Phone number should be empty or a valid value containing only - and + non numeric characters'
		set @ResultFlag = 1
		Return 1

End

if  ( ( @CellPhone is not NULL ) and ( dbo.FN_CheckPhoneNumber(@CellPhone) = 1 ) )
Begin

		set @ErrorDescription = 'ERROR !!! Cell Phone number should be empty or a valid value containing only - and + non numeric characters'
		set @ResultFlag = 1
		Return 1

End

if  ( ( @Pager is not NULL ) and ( dbo.FN_CheckPhoneNumber(@Pager) = 1 ) )
Begin

		set @ErrorDescription = 'ERROR !!! Pager number should be empty or a valid value containing only - and + non numeric characters'
		set @ResultFlag = 1
		Return 1

End

if  ( ( @WorkFax is not NULL ) and ( dbo.FN_CheckPhoneNumber(@WorkFax) = 1 ) )
Begin

		set @ErrorDescription = 'ERROR !!! Work FAX number should be empty or a valid value containing only - and + non numeric characters'
		set @ResultFlag = 1
		Return 1

End

if  ( ( @HomeFax is not NULL ) and ( dbo.FN_CheckPhoneNumber(@HomeFax) = 1 ) )
Begin

		set @ErrorDescription = 'ERROR !!! Home FAX number should be empty or a valid value containing only - and + non numeric characters'
		set @ResultFlag = 1
		Return 1

End


------------------------------------------------------------
-- Insert entry into the TB_PERSON table for the new record
------------------------------------------------------------

Begin Try

		insert into tb_person
		(	 
			 PersonTypeID ,
			 LastName ,
			 MI ,
			 FirstName ,
			 Address1 ,
			 Address2 ,
			 City ,
			 State ,
			 Zip ,
			 Country ,
			 WorkPhone ,
			 HomePhone ,
			 CellPhone ,
			 Pager ,
			 WorkFax ,
			 HomeFax ,
			 EmailAddress ,
			 Salutation ,
			 Company ,
			 Title ,
			 CreatedDate ,
			 CreatedByID ,
			 ModifiedDate,
			 ModifiedByID
		)
		Values
		(
			@PersonTypeID,
			@LastName ,
			@MI ,
			@FirstName ,
			@Address1 ,
			@Address2 ,
			@City ,
			@State ,
			@Zip ,
			@Country ,
			@WorkPhone ,
			@HomePhone ,
			@CellPhone ,
			@Pager ,
			@WorkFax ,
			@HomeFax ,
			@EmailAddress ,
			@Salutation ,
			@Company ,
			@Title ,
			GetDate(),
			@UserID,
			GetDate(),
			@USerID
		)	

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! While creating new person record. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch


Return 0
GO
