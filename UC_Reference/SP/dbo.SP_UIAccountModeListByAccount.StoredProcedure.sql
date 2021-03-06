USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountModeListByAccount]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAccountModeListByAccount]
(
	@AccountID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


---------------------------------------------
-- Check if Account ID is NULL or invalid
---------------------------------------------

if ((@AccountID is NULL) or not exists (select 1 from tb_Account where accountID = @AccountID))
Begin

		set @ErrorDescription = 'ERROR !!!! Account ID is NULL or it does not exist in the system'
		set @ResultFlag = 1
		return 1

End


------------------------------------------------------------------
-- Return the result set with each record being marked as 
-- Historic , Current or Future
------------------------------------------------------------------

Declare @CurrentPeriod int = convert(int ,convert(varchar(4) ,year(getdate())) + right( '0' + convert(varchar(2) ,month(getdate())) ,2))

Select tbl1.AccountModeID, 
	   [Period] , 
	   tbl2.AccountModeType as Mode,
	   tbl1.Comment,
	   tbl1.ModifiedDate,
	   isnull(tbl3.Name , 'User Unknown') as ModifiedBy,
	   Case
			When tbl1.Period < @CurrentPeriod Then 1
			When  tbl1.Period > @CurrentPeriod Then 3
			Else 2
	   End as RecordType
from tb_AccountMode tbl1
inner join tb_AccountModeType tbl2 on tbl1.AccountModeTypeID = tbl2.AccountModeTypeID
left join UC_Admin.dbo.tb_Users tbl3 on tbl1.ModifiedByID = tbl3.UserID
where AccountID = @AccountID
order by tbl1.Period

return 0
GO
