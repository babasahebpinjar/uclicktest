USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorSourceUpdate]    Script Date: 5/2/2020 6:18:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIVendorSourceUpdate]
(
    @VendorSourceID int,
	@Source varchar(60),
	@SourceAbbrv varchar(30),
	@StatusID int,
	@Note varchar(8000) = NULL,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-----------------------------------------------------------------
-- Check to ensure that Vendor Source ID ias not NULL or invalid
-----------------------------------------------------------------

if ( ( @VendorSourceID is Null) or not exists (select 1 from tb_Source where SourceID = @VendorSourceID and SourcetypeId = -1) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

----------------------------------------------
-- Set the Source Type to -1 (Vendor Source)
----------------------------------------------

Declare @SourceTypeID int = -1 -- Hard coded to -1  which is source id for Vendor Source

-------------------------------------------------------
-- Check to ensure that Source and Abbrv are not NULL
-------------------------------------------------------

set @Source = ltrim(rtrim(@Source))
set @SourceAbbrv = ltrim(rtrim(@SourceAbbrv))

if ( (@Source is NULL) or (len(@Source) = 0) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source Name cannot be NULL or blank'
	set @ResultFlag = 1
	return 1

End

if ( (@SourceAbbrv is NULL) or (len(@SourceAbbrv) = 0) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source Abbreviation cannot be NULL or blank'
	set @ResultFlag = 1
	return 1

End


if ( ( @StatusID is Null) or not exists (select 1 from UC_Reference.dbo.tb_ActiveStatus where ActiveStatusID = @StatusID) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Status ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------
-- Check to ensure that Source and Source Type are unique
--------------------------------------------------------------

if exists ( select 1 from tb_Source where ltrim(rtrim([source])) = @Source and SourceTypeID = @SourceTypeID and SourceID <> @VendorSourceID)
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source Name and Source Type combination already exists'
	set @ResultFlag = 1
	return 1

End



---------------------------------------------------------------
-- Insert Record into the database for the new Vendor Source
---------------------------------------------------------------
Declare @NoteID int

select @NoteID = NoteID
from tb_Source
where SourceID = @VendorSourceID

Begin Transaction VSR

Begin Try

        ------------------------------
		-- Record in TB_NOTE table
		------------------------------

		update tb_Note
		set Content = @Note,
		    ModifiedDate = GetDate(),
			ModifiedByID = @UserID
		Where NoteID = @NoteID

        ------------------------------
		-- Record in TB_SOURCE table
		------------------------------

		update tb_Source
		set ActiveStatusID = @StatusID,
			[Source] = @Source,
			SourceAbbrv = @SourceAbbrv,
			ModifiedDate = GetDate(),
			ModifiedByID = @UserID 
		Where SourceID = @VendorSourceID	  

	   
End Try


Begin Catch


	set @ErrorDescription = 'ERROR !!!! While updating Vendor Source. ' + ERROR_MESSAGE()
	Rollback Transaction VSR
	set @ResultFlag = 1
	return 1

End Catch

Commit Transaction VSR

Return 0



GO
