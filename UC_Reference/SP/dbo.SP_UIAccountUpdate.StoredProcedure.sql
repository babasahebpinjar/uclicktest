USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_UIAccountUpdate]
  (
    @AccountID int,
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

if ( @AccountID is null )
Begin

		set @ErrorDescription = 'ERROR !!! AccountID cannot be NULL. Please pass a valid value'
		set @ReturnFlag = 1
		Return 1

End

if not exists ( select 1 from tb_Account where AccountID = @AccountID )
Begin

		set @ErrorDescription = 'ERROR !!! Account does not exist in the system. Please check details'
		set @ReturnFlag = 1
		Return 1

End


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
			where ( AccountNumber = @AccountNumber
				or Account = @Account
				or AccountAbbrv = @AccountAbbrv )
				and AccountId <> @AccountID
		  )
Begin

	set @ErrorDescription = 'ERROR !!!! Duplicate account attributes, as there is already an account existing in the system with same name, abbreviation and number' 
	set @ReturnFlag = 1
	return 1

End

---------------------------------------------------------------
-- Check Phone number and Fax are syntactically correct values
---------------------------------------------------------------

if ( (@Phone is not null ) and ( dbo.FN_CheckPhoneNumber(@Phone) <> 0 ))
Begin

	set @ErrorDescription = 'ERROR !!!! Phone number provided is not syntactically correct'
	set @ReturnFlag = 1
	return 1

End


if ( (@Fax is not null ) and ( dbo.FN_CheckPhoneNumber(@Fax) <> 0 ))
Begin

	set @ErrorDescription = 'ERROR !!!! FAX number provided is not syntactically correct'
	set @ReturnFlag = 1
	return 1

End

----------------------------------------------------
-- Get the old status of the Account to match with
-- new status
----------------------------------------------------

Declare @OldActiveStatusID int

select @OldActiveStatusID = 
            Case
				When Flag & 32 = 32 then 2
				Else 1
			End
from tb_Account
where accountid = @AccountID

-----------------------------------------------------
-- Update record into database for existing account 
-----------------------------------------------------

Begin Try

	Update tb_Account
  	set
		BuyerID = @BuyerID,		
		SellerID =  @SellerID,		
		ContactPersonID = @ContactPersonID,
		Account = ltrim(@Account),
		AccountAbbrv = ltrim(@AccountAbbrv),
		AccountNumber = ltrim(@AccountNumber),
		AccountTypeID  = @AccountTypeID,
		CreditLimit = @CreditLimit,
		Deposit = @Deposit,
		Address1 = @Address1,
		Address2 = @Address2,
		City = @City,
		State = @State,
		Zip = @Zip,
		CountryID = @CountryID,
		Phone = @Phone,
		Fax = @Fax,
		Comment = @Comment,
		CompanyID = @CompanyID,              
		ModifiedDate = getdate(),
		ModifiedByID = @UserID,
		Flag = 
		    Case
			   When @OldActiveStatusID <> @ActiveStatusID Then
					Case
						When @ActiveStatusID = 2 then Flag + 32
						Else Flag -32
					End
			   Else Flag
			End
		where AccountID = @AccountID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!!! During Account update. ' + ERROR_MESSAGE()
	set @ReturnFlag = 1
	return 1
	
End Catch

return 0














GO
