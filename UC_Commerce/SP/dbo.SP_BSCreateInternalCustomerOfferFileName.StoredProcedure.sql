USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCreateInternalCustomerOfferFileName]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSCreateInternalCustomerOfferFileName]
(
	@SourceID int,
	@OfferFileName varchar(1000) Output,
	@ResultFlag int output,
	@ErrorDescription varchar(2000) output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------------------------
-- Check to see that the SourceID exists in the system and is not a NULL value
-------------------------------------------------------------------------------

if (@SourceID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! SourceID cannot be a NULL value'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_source where sourceID = @SourceID and SourceTypeID = -3 )  -- Source of the type Vendor
Begin

	set @ErrorDescription = 'ERROR !!! SourceID does not exist in the system'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------
-- Build the name of the offer file, that will
-- be registered in the system as internal name
------------------------------------------------------

Declare @Source varchar(60)

Select @Source = [Source]
from tb_Source
where sourceID = @SourceID

set @OfferFileName = Replace(Replace(Replace(convert(varchar(30) ,getdate() , 120) , ' ' , '') , '-' , '') , ':' , '') + '_' + Replace(@Source , ' ' , '') + '.offr'

Return 0
GO
