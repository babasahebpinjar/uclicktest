USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAccountGroupMembers]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UIGetAccountGroupMembers]
(
	@AccountGroupID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------
-- Check to ensure that Account Group is valid and not NULL
------------------------------------------------------------

if ( @AccountGroupID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Account Group ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


if not exists ( select 1 from tb_EntityGroup where EntityGroupID  = @AccountGroupID and EntityGroupTypeID = -3 )
Begin

	set @ErrorDescription = 'ERROR !!! Account Group ID does not exist or is not valid'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------------------------
-- Return the list of accounts, which are part of the group and which
-- are currently available
-----------------------------------------------------------------------

select tbl2.AccountID , tbl2.Account , '1' as AccountStatus
from tb_EntityGroupMember tbl1
inner join tb_Account tbl2 on tbl1.InstanceID = tbl2.AccountID
where EntityGroupID = @AccountGroupID

union

select AccountID , Account , '0' as AccountStatus
from tb_Account
where flag & 1 <> 1
and flag & 32 <> 32 -- All Active Accounts
and AccountID not in
(
	select instanceID
	from tb_EntityGroupMember tbl1
	inner join tb_EntityGroup tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
	where tbl2.EntityGroupTypeId = -3 -- All Account Entity Group
)

return 0

GO
