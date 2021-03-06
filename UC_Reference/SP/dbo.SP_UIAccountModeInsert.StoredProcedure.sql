USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountModeInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAccountModeInsert]
(
	@AccountID int,
	@Period int,
	@AccountModeTypeID int,
	@Comment varchar(1000),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag  = 0
set @ErrorDescription = NULL


------------------------------------------------------------
-- Check to see, if Account ID is NULL or an invalid value
------------------------------------------------------------

if ( (@AccountID is NULL) or  not exists (select 1 from tb_Account where AccountID = @AccountID))
Begin

	set @ErrorDescription = 'ERROR !!!!AccountID is NULL or does not exist in the system'
	set @ResultFlag = 1
	return 1

End

-------------------------------------------------------------------
-- The oldest period for which the record can be created is the 
-- minimum Agreement start date for an account. One cannot back date 
-- further than that
-------------------------------------------------------------------
Declare @MinBeginDate Datetime,
		@MinPeriod int

select  min(BeginDate)
from tb_Agreement
where accountID = @AccountID 
and flag &1 = 0


set @MinPeriod = convert(int ,
							convert(varchar(4) ,year(@MinBeginDate)) + 
							right( '0' + convert(varchar(2) ,month(@MinBeginDate)) ,2)
						)

if (@Period < @MinPeriod)
Begin

	set @ErrorDescription = 'ERROR!!! Period for the Account Mode cannot be back dated more than the minimum begin date for the agreement'
	set @ResultFlag = 1
	return 1

End

----------------------------------------------------------------------------------
-- Check to see if an entry already exists in the system for Period and Account
----------------------------------------------------------------------------------

if exists ( select 1 from tb_AccountMode where AccountID = @AccountID and [Period] = @Period)
Begin

	set @ErrorDescription = 'ERROR!!! Record already exists in the system for Account and Period'
	set @ResultFlag = 1
	return 1

End

---------------------------------------------------------------
-- Check to ensure that the AccountMode Type is a valid value
---------------------------------------------------------------

if not exists (select 1 from tb_AccountModeType where AccountModeTypeID = @AccountModeTypeID and flag&1 = 0)
Begin

	set @ErrorDescription = 'ERROR !!!! Account Mode Type passed is not a valid value'
	set @ResultFlag = 1
	return 1

End


-------------------------------------------------------------------
-- Insert record into the tb_AccountMode table for the new period
-------------------------------------------------------------------

Begin Try

		insert into tb_AccountMode
		(
			AccountID,
			AccountModeTypeID,
			[Period],
			Comment,
			ModifiedDate,
			ModifiedByID
		)
		values
		(
			@AccountID,
			@AccountModeTypeID,
			@Period,
			@Comment,
			getdate(),
			@UserID
		)


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! During insertion of new Account Mode Period record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch


GO
