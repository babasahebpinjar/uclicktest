USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateInsertFromSource]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateInsertFromSource]
(
	@RateDimensionTemplateSourceID int,
	@RateDimensionTemplate varchar(100),
	@UserID int,
	@RateDimensionTemplateID int Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0
set @RateDimensionTemplateID = NULL

-------------------------------------------------------------------
-- Make sure that Rate Dimension Template ID is not NULL and Valid
-------------------------------------------------------------------

if ( @RateDimensionTemplateSourceID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Template ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RateDimensionTemplate where RateDimensionTemplateID = @RateDimensionTemplateSourceID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rate Dimension Template ID passed as input for source Template. Rate Dimension Template does not exist'
	set @ResultFlag = 1
	Return 1


End

if exists (  select 1 from tb_RateDimensionTemplate where rtrim(ltrim(RateDimensionTemplate)) = rtrim(ltrim(@RateDimensionTemplate)))
Begin

	set @ErrorDescription = 'ERROR !!! Rate Dimension template already exists by the name : (' + @RateDimensionTemplate + ')'
	set @ResultFlag = 1
	Return 1


End

-----------------------------------------------------
-- Get the Rate Dimension ID of the Source Template
-----------------------------------------------------

Declare @RateDimensionID int

Select @RateDimensionID = RateDimensionID
from tb_RateDimensionTemplate
where RateDimensionTemplateID = @RateDimensionTemplateSourceID


-----------------------------------------------------------------
-- Insert data into related rate dimension template tables, using
-- data from the source template
-----------------------------------------------------------------

------------------------------------------------------
-- Insert the Rate Dimension Template Data in the DB
------------------------------------------------------

Begin Transaction InsRDT

Begin Try

    ------------------------------------
	-- Tb_RateDimensionTemplate
	------------------------------------

	insert into tb_RateDimensionTemplate
	(
		RateDimensionTemplate,
		RateDimensionID,
		ModifiedDate,
		ModifiedByID,
		Flag	
	)
	Select @RateDimensionTemplate,
	       RateDimensionID,
		   GETDATE(),
		   @UserID,
		   0
	from tb_RateDimensionTemplate
	where RateDimensionTemplateID = @RateDimensionTemplateSourceID

	set @RateDimensionTemplateID = @@IDENTITY -- ID of the newly created Rate Dimension Template

	----------------------------
	-- tb_RateDimensionBand
	----------------------------

	insert into tb_RateDimensionBand
	(
		RateDimensionBand,
		RateDimensionBandAbbrv,
		RateDimensionTemplateID,
		ModifiedDate,
		ModifiedByID,
		Flag
	)
	Select RateDimensionBand , 
	       RateDimensionBandAbbrv , 
		   @RateDimensionTemplateID , 
		   GETDATE(),
		   @UserID,
		   0
	from tb_RateDimensionBand
	where RateDimensionTemplateID = @RateDimensionTemplateSourceID


	-------------------------------------------------------------
	-- Insert the Band details depending on the Dimension Type
	-------------------------------------------------------------

	if (@RateDimensionID = 1 ) -- Date and Time Dimension Template
	Begin
	  
	        insert into tb_DateTimeBandDetail
			(
				DateTimeBandID,
				EventYear,
				EventDay,
				EventMonth,
				EventWeekDay,
				FromField,
				ToField,
				ModifiedDate,
				ModifiedByID,
				Flag
			)
			select trg.RateDimensionBandID , srcBD.EventYear,
			       srcBD.EventDay , srcBD.EventMonth,
				   srcBD.EventWeekDay, srcBD.FromField,
				   srcBD.ToField, GetDate() , @UserID , 0
			from tb_DateTimeBandDetail srcBD
			inner join tb_RateDimensionBand src on srcBD.DateTimeBandID = src.RateDimensionBandID
			inner join tb_RateDimensionBand trg on trg.RateDimensionBand = src.RateDimensionBand
			where src.RateDimensionTemplateID = @RateDimensionTemplateSourceID
			and trg.RateDimensionTemplateID = @RateDimensionTemplateID

	End

	Else
	Begin

	        insert into tb_RateDimensionBandDetail
			(
				RateDimensionBandID,
				FromField,
				ToField,
				ApplyFrom,
				ModifiedDate,
				ModifiedByID,
				Flag
			)
			select trg.RateDimensionBandID , srcBD.FromField,
				   srcBD.ToField, srcBD.ApplyFrom , Getdate() , @UserID , 0
			from tb_RateDimensionBandDetail srcBD
			inner join tb_RateDimensionBand src on srcBD.RateDimensionBandID = src.RateDimensionBandID
			inner join tb_RateDimensionBand trg on trg.RateDimensionBand = src.RateDimensionBand
			where src.RateDimensionTemplateID = @RateDimensionTemplateSourceID
			and trg.RateDimensionTemplateID = @RateDimensionTemplateID


	End


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While inserting new Rate Dimension Template record from Source Template. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Rollback  Transaction InsRDT
	Return 1

End Catch


Commit Transaction InsRDT



GO
