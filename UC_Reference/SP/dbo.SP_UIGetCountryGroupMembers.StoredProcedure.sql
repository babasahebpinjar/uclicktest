USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCountryGroupMembers]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_UIGetCountryGroupMembers]
(
	@CountryGroupID int,
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

if ( @CountryGroupID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Country Group ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


if not exists ( select 1 from tb_EntityGroup where EntityGroupID  = @CountryGroupID and EntityGroupTypeID = -4 )
Begin

	set @ErrorDescription = 'ERROR !!! Country Group ID does not exist or is not valid'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------------------
-- Return the list of Countries, which are part of the group and which
-- are currently available
--------------------------------------------------------------------------

select tbl2.CountryID , tbl2.Country , '1' as CountryStatus
from tb_EntityGroupMember tbl1
inner join tb_Country tbl2 on tbl1.InstanceID = tbl2.CountryID
where EntityGroupID = @CountryGroupID

union

select CountryID , Country , '0' as CountryStatus
from tb_Country 
where flag & 1 <> 1
and CountryID not in
(
	select instanceID
	from tb_EntityGroupMember tbl1
	inner join tb_EntityGroup tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
	where tbl2.EntityGroupTypeId = -4 -- Country Entity Group
)

return 0

GO
