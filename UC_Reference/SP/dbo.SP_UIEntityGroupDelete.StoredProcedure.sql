USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIEntityGroupDelete]
(
	@EntityGroupID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------
-- Ensure that Entity Group ID is a valid value
--------------------------------------------------

if ( @EntityGroupID is NULl )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_EntityGroup where EntityGroupID = @EntityGroupID )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group ID does not exist'
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------------------------------
-- Make sure to delete the group and all the corresponding members of the group
--------------------------------------------------------------------------------

Begin transaction DeleteEG

Begin Try

	Delete from tb_EntityGroupMember
	where EntityGroupID = @EntityGroupID

	Delete from tb_EntityGroup
	where EntityGroupID = @EntityGroupID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Deleting records for entity group.'+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Rollback transaction DeleteEG
	Return 1

End Catch

Commit Transaction DeleteEG

Return 0
GO
