USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create  PROCEDURE [dbo].[SP_UIAccountInsert]
  (
	@ActiveStatusID int,
	@BuyerID int,		
	@SellerID int,		
	@ContactPersonID int,
	@Account varchar(60),
	@AccountAbbrv varchar(30),
	@AccountNumber varchar(30),
	@AccountTypeID int,
	@CreditLimit money,
	@Deposit money,
	@Address1 varchar(50),
	@Address2 varchar(50),
	@City varchar(50),
	@State varchar(50),
	@Zip varchar(50),
	@CountryID int,
	@Phone varchar(50),
	@Fax varchar(50),
	@Comment varchar(8000), 
	@CompanyID int,		
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ReturnFlag int output
  )

AS

set @ReturnFlag = 0
set @ErrorDescription = NULL

-----------------------------------------------------------------
-- Length of comment section should be less than 3000 characters
-----------------------------------------------------------------

if	len(@Comment) > 3000
Begin

	set @ErrorDescription = 'Please make sure that length of comments is less than 3000 characters. Currently length is : ' + convert(varchar(20) , len(@Comment)) + ' charcters' 
	set @ReturnFlag = 1
	return 1

End


------------------------------------------------------------------
-- Check if duplicate combination already exists for Account ,
-- Account Abbrv and Account number
------------------------------------------------------------------

if exists (
			select * from tb_Account
			where AccountNumber = @AccountNumber
				or Account = @Account
				or AccountAbbrv = @AccountAbbrv
		  )
Begin

	set @ErrorDescription = 'ERROR !!!! Duplicate account attributes, as there is already an account existing in the system with same name, abbreviation and number' 
	set @ReturnFlag = 1
	return 1

End----------------------------------------------------------------- Check Phone number and Fax are syntactically correct values---------------------------------------------------------------if ( (@Phone is not null ) and ( dbo.FN_CheckPhoneNumber(@Phone) <> 0 ))Begin	set @ErrorDescription = 'ERROR !!!! Phone number provided is not syntactically correct'
	set @ReturnFlag = 1
	return 1Endif ( (@Fax is not null ) and ( dbo.FN_CheckPhoneNumber(@Fax) <> 0 ))Begin	set @ErrorDescription = 'ERROR !!!! FAX number provided is not syntactically correct'
	set @ReturnFlag = 1
	return 1End-------------------------------------------------------------- Insert record into database for new account creation------------------------------------------------------------
Begin Try

	INSERT INTO tb_Account
  		(
		BuyerID,		
		SellerID,		
		ContactPersonID,
		Account,
		AccountAbbrv,
		AccountNumber,
		AccountTypeID,
		CreditLimit,
		Deposit,
		Address1,
		Address2,
		City,
		State,
		Zip,
		CountryID,
		Phone,
		Fax,
		Comment,
		CompanyID,              
		ModifiedDate,
		ModifiedByID,
		Flag
		)
	VALUES
	  	(
		@BuyerID,		
		@SellerID,		
		@ContactPersonID,
		ltrim(@Account),
		ltrim(@AccountAbbrv),
		ltrim(@AccountNumber),
		@AccountTypeID,
		@CreditLimit,
		@Deposit,
		@Address1,
		@Address2,
		@City,
		@State,
		@Zip,
		@CountryID,
		@Phone,
		@Fax,
		@Comment,
		@CompanyID,		 
		getdate(),
		@UserID,
		Case
			When @ActiveStatusID = 2 then 32
			Else 0
		End
		)

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!!! During Account creation. ' + ERROR_MESSAGE()
	set @ReturnFlag = 1
	return 1
	
End Catch

return 0













GO
