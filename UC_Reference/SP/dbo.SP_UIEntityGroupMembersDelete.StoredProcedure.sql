USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupMembersDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIEntityGroupMembersDelete]
(
	@EntityGroupID int,
	@UserID int,
	@ErrorDEscription varchar(2000) output,
	@ResultFlag int output
)
As

if ( @EntityGroupID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Entity Group ID cannot be NULL'
		set @ResultFlag = 1
		Return 1
End

if not exists (select 1 from tb_EntityGroup where EntityGroupID = @EntityGroupID)
Begin

		set @ErrorDescription = 'ERROR !!! Entity Group ID does not exist or is invalid'
		set @ResultFlag = 1
		Return 1
End


Begin Try

	Delete from tb_EntityGroupMember
	where EntityGroupID = @EntityGroupID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Deleting members from the entity group.' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch

Return 0
GO
