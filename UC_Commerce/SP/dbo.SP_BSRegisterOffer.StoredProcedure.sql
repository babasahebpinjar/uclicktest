USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRegisterOffer]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSRegisterOffer]
(
	@SourceID int,
	@ExternalOfferFileName varchar(1000),
	@OfferContent varchar(50),
	@OfferTypeID int,
	@OfferDate DateTime ,
	@UserID int,
	@OfferID int Output,
	@ResultFlag int Output,
	@ErrorDescription varchar(2000) Output
)
As

Declare @FileExists int,
        @ExternalOfferFileNameOnly varchar(500),
		@cmd varchar(2000),
		@ResultFlag2 int,
		@ErrorDescription2 varchar(2000),
		@ParseOfferFileName varchar(1000),
		@ParseOfferFileNameOnly varchar(500),
		@ParseOfferLogFileName varchar(1000)

set @ResultFlag = 0
set @ErrorDescription = NULL

-------------------------------------------------------------------------------
-- Check to see that the SourceID exists in the system and is not a NULL value
-------------------------------------------------------------------------------

if (@SourceID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! SourceID cannot be a NULL value'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_source where sourceID = @SourceID ) 
Begin

	set @ErrorDescription = 'ERROR !!! SourceID does not exist in the system'
	set @ResultFlag = 1
	Return 1

End

-----------------------------------------------------------------------
-- Make sure that all the other parameters are also not NULL and valid
-- values
-----------------------------------------------------------------------

------------------------------
-- External Offer File Name
------------------------------

if (@ExternalOfferFileName is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Name of offer file to be uploaded cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------
-- Check to ensure that the file exists in the system
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @ExternalOfferFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'ERROR !!! Offer file with the name  and path : (' + @ExternalOfferFileName + ') does not exist or is not accessible'
	set @ResultFlag = 1
	Return 1	

End 

-------------------
-- Offer Content
-------------------

if (@OfferContent is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Offer Content type cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if (@OfferContent not in ('AZ' , 'PR' , 'FC') )
Begin

	set @ErrorDescription = 'ERROR !!! Value for Offer Content is not correct. Valid values are (AZ/FC/PR) '
	set @ResultFlag = 1
	Return 1

End

---------------
-- Offer Type
---------------

if (@OfferTypeID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Offer Type ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End


if not exists ( select 1 from tb_OfferType where OfferTypeID = @OfferTypeID ) 
Begin

	set @ErrorDescription = 'ERROR !!! Offer Type does not exist in the system'
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------------
-- Ensure that the mapping exists for the source type and
-- offer type passed to the procedure
--------------------------------------------------------------

Declare @SourceTypeID int,
        @SourceType varchar(100),
		@OfferType varchar(100)

select @SourceTypeID = SourceTypeID
from tb_Source
where sourceID = @SourceID

select @SourceType = Sourcetype
from tb_SourceType
where SourceTypeID = @SourceTypeID

Select @OfferType = OfferType
from tb_OfferType
where OfferTypeID = @OfferTypeID

if not exists ( select 1 from tb_OfferType where OfferTypeID = @OfferTypeID and SourceTypeID = @SourceTypeID )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot have offer type as : (' + @OfferType + ') for Source Type : (' + @SourceType + ')'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------------------------------------
--  Ensure that no other entry exists in the system for the same
-- offer date and SourceID
----------------------------------------------------------------------

if exists ( select 1 from tb_offer where sourceID = @SourceID and OfferDate = @OfferDate )
Begin

	set @ErrorDescription = 'ERROR !!! The offer is duplicate as entry already exists for the offer date and source'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------------
-- Get the name of the External offer file from the complete
-- name
----------------------------------------------------------------

if ( charindex('\' ,reverse(@ExternalOfferFileName)) <> 0 )
Begin

	select @ExternalOfferFileNameOnly =  reverse(substring(reverse(@ExternalOfferFileName) , 1, charindex('\' ,reverse(@ExternalOfferFileName)) - 1))

End

if ( @ExternalOfferFileNameOnly is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot extract the name of offer file from complete file name : (' + @ExternalOfferFileName + ')'
	set @ResultFlag = 1
	Return 1

End

-----------------------------------------
-- Call the essential procedure to parse
-- the offer file
-----------------------------------------

if (@OfferTypeID = -1 ) -- Vendor Offer
Begin

        set @ResultFlag2 = 0
		set @ErrorDescription2 = NULL

		Exec SP_BSParseVendorOfferFile @SourceID,
		                               @ExternalOfferFileName , 
		                               @ParseOfferFileName Output , 
									   @ParseOfferLogFileName Output,
									   @ResultFlag2 Output , 
									   @ErrorDescription2 Output

        if (@ResultFlag2 <> 0 ) 
		Begin

				set @ErrorDescription = @ErrorDescription2
				set @ResultFlag = 1

				--------------------------------------------------------
				-- Delete all residual files before exiting the process
				--------------------------------------------------------

				Exec('del ' + '"' + @ParseOfferFileName + '"')

				Return 1


		End

End

---------------------------------------------------------------
-- Get the name of the External offer file from the complete
-- name
----------------------------------------------------------------

if ( charindex('\' ,reverse(@ParseOfferFileName)) <> 0 )
Begin

	select @ParseOfferFileNameOnly =  reverse(substring(reverse(@ParseOfferFileName) , 1, charindex('\' ,reverse(@ParseOfferFileName)) - 1))

End

if ( @ParseOfferFileNameOnly is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot extract the name of parsed offer file from complete file name : (' + @ParseOfferFileName + ')'
	set @ResultFlag = 1
	Return 1

End


------------------------------------------------------------------
-- Insert record into the tb_Offer table for the parsed offer file
-- and register in the system
------------------------------------------------------------------

Begin Transaction ins_Offr

Begin Try

		---------------------------
		-- TB_OFFER SCHEMA
		---------------------------

		Insert into tb_Offer
		(
			ExternalOfferFileName,
			OfferFileName,
			OfferDate,
			OfferTypeID,
			SourceID,
			OfferContent,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		values
		(
			@ExternalOfferFileNameOnly ,
			@ParseOfferFileNameOnly,
			@OfferDate,
			@OfferTypeID,
			@SourceID,
			@OfferContent,
			getdate(),
			@UserID,
			0
		)

		set @OfferID  = @@IDENTITY

		---------------------------
		-- TB_WORKFLOW SCHEMA
		---------------------------

		insert into tb_offerWorkflow
		(
			OfferID,
			OfferStatusID,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Values
		(
			@OfferID,
			1 ,-- Created
			getdate(),
			@UserID,
			0
		)

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! During insertion of record for new offer.'+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Rollback Transaction ins_Offr
	Return 1

End Catch

Commit Transaction ins_Offr
 
Return 0
GO
