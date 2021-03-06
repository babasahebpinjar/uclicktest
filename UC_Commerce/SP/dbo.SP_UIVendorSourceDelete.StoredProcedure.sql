USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorSourceDelete]    Script Date: 5/2/2020 6:18:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorSourceDelete]
(
	@SourceID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


------------------------------------------------------------------
-- Check to ensure that the VendorSourceID is not null or invalid
------------------------------------------------------------------

if ( ( @SourceID is Null) or not exists (select 1 from tb_Source where SourceID = @SourceID and SourcetypeId = -1) )
Begin

	set @ErrorDescription = 'ERROR !!!! Source ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

------------------------------------------------------------------------------
-- Get details for the source to confirm if there are any offers associated
------------------------------------------------------------------------------

if exists ( select 1 from tb_offer where SourceID = @SourceID and OfferTypeID = -1 )
Begin


	set @ErrorDescription = 'ERROR !!!! Cannot delete as Vendor Source has one more more offers associated'
	set @ResultFlag = 1
	return 1		


End


-------------------------------------------------
-- Delete the vendor source from the system
-------------------------------------------------

Begin Try

	Delete from tb_Source
	where sourceID = @SourceID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!!! During deletion of vendor Source. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1	

End Catch

Return 0
GO
