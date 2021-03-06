USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIEntityGroupUpdate]
(
    @EntityGroupID int,
	@EntityGroup varchar(60),
	@EntityGroupAbbrv varchar(20),
	@EntityGroupTypeID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------
-- Ensure that Entity group ID is not NULL and a valid value
-------------------------------------------------------------

if (@EntityGroupID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_EntityGroup where EntityGroupID = @EntityGroupID )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group ID does not exist in the system'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------------------------
-- Check to ensure that the entity group type is a valid
-- value
----------------------------------------------------------

if ( ( @EntityGroupTypeID is NULL ) or (@EntityGroupTypeID not in (-2 , -3 , -4)) )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group Type ID is NULL or not a valid value'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------
-- Entity Group name and Abbrv cannot be NULL
------------------------------------------------

if ( ( @EntityGroup is NULL ) or (@EntityGroupAbbrv is NULL ) )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group Name or Abbreviation is NULL'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------
-- Get the existing values for the Entity Group
---------------------------------------------------

Declare @OldEntityGroupTypeID int

Select @OldEntityGroupTypeID = EntityGroupTypeID
from tb_EntityGroup
where EntityGroupID = @EntityGroupID
        
----------------------------------------------------------------------------
--  If the entity group type is being changed from previous type, then
-- ensure that no memebers are assigned to the entity group for a different
-- group type
-----------------------------------------------------------------------------

if ( @OldEntityGroupTypeID <> @EntityGroupTypeID )
Begin

		if exists ( select 1 from tb_EntityGroupMember where EntityGroupID = @EntityGroupID )
		Begin

				set @ErrorDescription = 'ERROR !!! Cannot change the type of the Group when it has members of differfent type associated'
				set @ResultFlag = 1
				Return 1

		End

End

----------------------------------------------------------------------------
-- Check to ensure that the group name and group type combination
-- is unique
----------------------------------------------------------------------------

if exists ( select 1 from tb_EntityGroup where ltrim(rtrim(EntityGroup)) = @EntityGroup and EntityGroupTypeID = @EntityGroupTypeID and EntityGroupID <>  @EntityGroupID)
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group and Entity Group Type combination is not unique. Please change the Entity Group Name'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------
-- update record for the Entity Group into database
---------------------------------------------------------

Begin Try

		Update tb_EntityGroup
		set EntityGroup = @EntityGroup,
		EntityGroupAbbrv = @EntityGroupAbbrv,
		EntityGroupTypeID = @EntityGroupTypeID,
		ModifiedDate = Getdate(),
		ModifiedByID = @UserID
		Where EntityGroupID = @EntityGroupID


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Updating Entity Group record information. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch

GO
