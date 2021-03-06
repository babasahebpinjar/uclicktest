USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetDestinationGroupMembers]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UIGetDestinationGroupMembers]
(
	@DestinationGroupID int,
	@NumberPlanID int,
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

if ( @DestinationGroupID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Destination Group ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


if not exists ( select 1 from tb_EntityGroup where EntityGroupID  = @DestinationGroupID and EntityGroupTypeID = -2 )
Begin

	set @ErrorDescription = 'ERROR !!! Destination Group ID does not exist or is not valid'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------------------
-- Return the list of Destinations, which are part of the group and which
-- are currently available
--------------------------------------------------------------------------

select tbl2.DestinationID , tbl2.Destination + ' (' + tbl3.NumberPlanAbbrv + ')' as Destination , '1' as DestinationStatus
from tb_EntityGroupMember tbl1
inner join tb_Destination tbl2 on tbl1.InstanceID = tbl2.DestinationID
inner join tb_Numberplan tbl3 on tbl2.NumberPlanID = tbl3.NumberPlanID
where EntityGroupID = @DestinationGroupID
and NumberPlanTypeID = 1 -- Reference Number Plans
and tbl2.NumberplanID = 
	Case
		When @NumberPlanID = 0 Then tbl2.NumberplanID
		Else @NumberPlanID
	End

union

select tbl2.DestinationID , tbl2.Destination + ' (' + tbl3.NumberPlanAbbrv + ')' as Destination , '0' as DestinationStatus
from tb_Destination tbl2 
inner join tb_Numberplan tbl3 on tbl2.NumberPlanID = tbl3.NumberPlanID
where NumberPlanTypeID = 1 -- Reference Number Plans
and tbl2.NumberplanID = 
	Case
		When @NumberPlanID = 0 Then tbl2.NumberplanID
		Else @NumberPlanID
	End
and tbl2.DestinationID not in
(
	select instanceID
	from tb_EntityGroupMember tbl1
	inner join tb_EntityGroup tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
	where tbl2.EntityGroupTypeId = -2 -- Destination Entity Group
)
and tbl2.Flag & 1 <> 1

return 0

GO
