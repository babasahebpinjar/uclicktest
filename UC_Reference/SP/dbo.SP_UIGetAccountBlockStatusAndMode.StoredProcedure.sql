USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAccountBlockStatusAndMode]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIGetAccountBlockStatusAndMode]
(
	@AccountID int,
	@BlockStatus int Output , -- 0 Unblocked , 1 Blocked
	@AccountMode int Output  -- -1 Postpaid , -2 Prepaid
)
As

Declare @CurrPeriod int = convert(int ,replace(convert(varchar(7) , getdate() , 120), '-' , ''))

Select @AccountMode = AccountModeTypeID
from tb_AccountMode
where AccountID = @AccountID
and Period = @CurrPeriod

set @AccountMode = isNULL(@AccountMode , -1) -- Default the value to Post paid in case no records are found

if exists (Select 1 from tb_Trunk where TrunkTypeID <> 9 and AccountID = @AccountID and Flag & 64 <> 64 ) -- Oner or more unblock trunks exist
	set @BlockStatus = 0

Else
	set @BlockStatus = 1

Return 0



GO
