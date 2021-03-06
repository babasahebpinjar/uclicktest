USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateDelete]
(
       @RateDimensionTemplateID int,
       @ErrorDescription varchar(2000) output,
       @ResultFlag int output
)
As
 
set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------------
-- Make sure that Rate Dimension Template ID is not NULL and Valid
-------------------------------------------------------------------

if ( @RateDimensionTemplateID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Template ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RateDimensionTemplate where RateDimensionTemplateID = @RateDimensionTemplateID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rate Dimension Template ID passed as input. Rate Dimension Template does not exist'
	set @ResultFlag = 1
	Return 1


End

-------------------------------------------------------------
-- Cannot delete Default Rate Dimension Templates from the
-- system
--------------------------------------------------------------

if  exists (  select 1 from tb_RateDimensionTemplate where RateDimensionTemplateID = @RateDimensionTemplateID and RateDimensionTemplateID < 0)
Begin

	set @ErrorDescription = 'ERROR !!! Cannot delete a default Rating Dimension Template'
	set @ResultFlag = 1
	Return 1


End


-------------------------------------------------------------
-- Ensure that there is no Rating Method associated with the
-- Rate Dimension Template.
-------------------------------------------------------------

if exists (
				select 1
				from tb_RatingMethodDetail tbl1
				inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
				inner join tb_RateItemType tbl3 on tbl2.RateItemTypeID = tbl3.RateItemTypeID
				where tbl3.RateItemTypeID = 3 -- Dimension Template
				and convert(int , tbl1.ItemValue) = @RateDimensionTemplateID
          )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete the Rate Dimension Template as it is associated to one or more Rating Method'
		set @ResultFlag = 1
		Return 1

End


Declare @RateDimensionID int

select @RateDimensionID = RateDimensionID
from tb_RateDimensionTemplate
where RateDimensionTemplateID = @RateDimensionTemplateID

------------------------------------
-- Delete records from :
-- DimensioBand Detail
-- Dimension Band
-- Dimension Template
-- for the Rate Dimension Template ID
--------------------------------------

Begin Transaction DeleteRD

Begin Try

		--------------------------
		-- DIMENSION BAND DETAIL
		--------------------------

       if ( @RateDimensionID = 1 )
	   Begin
 
				Delete tbl1
				from tb_DateTimeBandDetail tbl1
				inner join tb_RateDimensionBand tbl2 on tbl1.DateTimeBandID =  tbl2.RateDimensionBandID
				inner join tb_RateDimensionTemplate tbl3 on tbl2.RateDimensionTemplateID = tbl3.RateDimensionTemplateID
				where tbl3.RateDimensionTemplateID = @RateDimensionTemplateID

		End

		Else
		Begin

				Delete tbl1
				from tb_RateDimensionBandDetail tbl1
				inner join tb_RateDimensionBand tbl2 on tbl1.RateDimensionBandID =  tbl2.RateDimensionBandID
				inner join tb_RateDimensionTemplate tbl3 on tbl2.RateDimensionTemplateID = tbl3.RateDimensionTemplateID
				where tbl3.RateDimensionTemplateID = @RateDimensionTemplateID

		End

		---------------------
		-- DIMENSION BAND
		---------------------

		Delete tbl1
		from tb_RateDimensionBand tbl1
		inner join tb_RateDimensionTemplate tbl2 on tbl1.RateDimensionTemplateID = tbl2.RateDimensionTemplateID
		where tbl2.RateDimensionTemplateID = @RateDimensionTemplateID

		--------------------------
		-- DIMENSION TEMPLATE
		--------------------------

		Delete from tb_RateDimensionTemplate
		where RateDimensionTemplateID = @RateDimensionTemplateID

End Try
 
Begin Catch
 
        set  @ResultFlag = 1
        set  @ErrorDescription = 'ERROR !!! Deleting record for Rate Dimension Template. '+ ERROR_MESSAGE()
		Rollback Transaction DeleteRD
        Return 1     
 
End Catch

Commit Transaction DeleteRD
 
Return 0
GO
