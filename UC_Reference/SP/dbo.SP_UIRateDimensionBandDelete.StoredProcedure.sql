USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionBandDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionBandDelete]
(
       @RateDimensionBandID int,
       @ErrorDescription varchar(2000) output,
       @ResultFlag int output
)
As
 
set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------------
-- Make sure that Rate Dimension Band ID is not NULL and Valid
-------------------------------------------------------------------

if ( @RateDimensionBandID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Band ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RateDimensionBand where RateDimensionBandID = @RateDimensionBandID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rate Dimension Band ID passed as input. Rate Dimension Band does not exist'
	set @ResultFlag = 1
	Return 1


End


if exists (  
				select 1 
				from tb_RateDimensionBand tbl1
				inner join tb_RateDimensionTemplate tbl2 on tbl1.RateDimensionTemplateID = tbl2.RateDimensionTemplateID
				where tbl1.RateDimensionBandID = @RateDimensionBandID
				and tbl2.RateDimensionTemplateID < 0 
		  )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot delete information for a default dimension Template. Please contact Administrator'
	set @ResultFlag = 1
	Return 1


End


-------------------------------------------------------------
-- Ensure that there is no Rating Method associated with the
-- Rate Dimension Template.
-------------------------------------------------------------

-------------------------------------------------------------
-- Ensure that there is no Rating Method associated with the
-- Rate Dimension Band.
-------------------------------------------------------------
if exists (
				Select 1 
				from tb_RateDimensionBand tbl1 
				inner join tb_RateNumberIdentifier tbl2 on 
					(
						tbl1.RateDimensionBandID = tbl2.RateDimension1BandID
						or
						tbl1.RateDimensionBandID = tbl2.RateDimension2BandID
						or
						tbl1.RateDimensionBandID = tbl2.RateDimension3BandID
						or
						tbl1.RateDimensionBandID = tbl2.RateDimension4BandID
						or
						tbl1.RateDimensionBandID = tbl2.RateDimension5BandID
					)
				where tbl1.RateDimensionBandID = @RateDimensionBandID
	        )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete the Rate Dimension Band as it is associated to a Rating Method'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------
-- Ensure that there is no Band Detail associated with the
-- Rate Dimension Band.
-------------------------------------------------------------

Declare @RateDimensionID int

select @RateDimensionID = RateDimensionID
from tb_RateDimensionTemplate tbl1
inner join tb_RateDimensionBand tbl2 on tbl1.RateDimensionTemplateID = tbl2.RateDimensionTemplateID
where tbl2.RateDimensionBandID = @RateDimensionBandID

if ( @RateDimensionID = 1 )
Begin
 
	if exists ( Select 1 from tb_DateTimeBandDetail where DateTimeBandID = @RateDimensionBandID )
	Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete the Rate Dimension Band as it is associated to a date time band detail'
		set @ResultFlag = 1
		Return 1

	End

End

Else
Begin
 
	if exists ( Select 1 from tb_RateDimensionBandDetail where RateDimensionBandID = @RateDimensionBandID )
	Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete the Rate Dimension Band as it is associated to a Dimension band detail'
		set @ResultFlag = 1
		Return 1

	End

End

------------------------------------
-- Delete records from Dimension Band
--------------------------------------

Begin Try

		Delete from tb_RateDimensionBand 
		where RateDimensionBandID = @RateDimensionBandID


End Try
 
Begin Catch
 
        set  @ResultFlag = 1
        set  @ErrorDescription = 'ERROR !!! Deleting record for Rate Dimension Band. '+ ERROR_MESSAGE()
        Return 1     
 
End Catch

 
Return 0
GO
