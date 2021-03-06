USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIEntityGroupInsert]
(
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

----------------------------------------------------------------------------
-- Check to ensure that the group name and group type combination
-- is unique
----------------------------------------------------------------------------

if exists ( select 1 from tb_EntityGroup where ltrim(rtrim(EntityGroup)) = @EntityGroup and EntityGroupTypeID = @EntityGroupTypeID )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group and Entity Group Type combination is not unique. Please change the Entity Group Name'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------
-- Insert record for the new Entity Group into database
---------------------------------------------------------

Begin Try

	insert into tb_EntityGroup
	( EntityGroup , EntityGroupAbbrv , EntityGroupTypeID , ModifiedDate , ModifiedByID )
	Values
	( @EntityGroup , @EntityGroupAbbrv , @EntityGroupTypeID , GetDate() , @UserID )


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Creating new Entity Group record. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch

GO
