USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountModeUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UIAccountModeUpdate]
(
    @AccountModeID int,
	@AccountModeTypeID int,
	@Comment varchar(1000),
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As


Declare @AccountID int

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------
-- Check if AccountModeID is NULL or not
---------------------------------------

if (@AccountModeID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Account Mode ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End

----------------------------------------------------------------
-- Ensure that the Account Mode Type ID is not NULL or invalid
-- value
----------------------------------------------------------------

if ( (@AccountModeTypeID is NULL) or not exists (select 1 from tb_AccountModeType where AccountModeTypeID = @AccountModeTypeID and flag & 1 = 0))
Begin

	set @ErrorDescription = 'ERROR !!! Account Mode Type is either NULL or the value does not exist in the system'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------
-- Account Mode Type can only be updated for Future Periods
-- Comment can be updated for all the periods
--------------------------------------------------------------

Declare @CurrPeriod int  = convert(int ,convert(varchar(4) ,year(getdate())) + right( '0' + convert(varchar(2) ,month(getdate())) ,2)),
        @RecPeriod int,
		@RecAccountModeTypeID int

select @RecPeriod = [Period],
       @RecAccountModeTypeID = AccountModeTypeID
from tb_AccountMode
where AccountModeID = @AccountModeID


if ((@RecPeriod <= @CurrPeriod ) and  (@RecAccountModeTypeID <> @AccountModeTypeID))
Begin

	set @ErrorDescription = 'ERROR !!! Cannot change the Account Mode Type for historical or current period. Change only allowed for future period(s)'
	set @ResultFlag = 1
	return 1

End


---------------------------------------------------------
-- Update information for the record in the database
---------------------------------------------------------

Begin Try

	update tb_AccountMode
	set AccountModeTypeID = @AccountModeTypeID,
		Comment = @Comment,
		ModifiedDate = Getdate(),
		ModifiedByID = @UserID
     where AccountModeID  = @AccountModeID


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! During update of Account Mode record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch



GO
