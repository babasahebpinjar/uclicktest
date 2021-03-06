USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodDelete]
(
       @RatingMethodID int,
       @ErrorDescription varchar(2000) output,
       @ResultFlag int output
)
As
 
set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------------
-- Make sure that Rating Method ID is not NULL and Valid
-------------------------------------------------------------------

if ( @RatingMethodID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RatingMethod where RatingMethodID = @RatingMethodID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rating Method ID passed as input. Rating Method does not exist'
	set @ResultFlag = 1
	Return 1


End

-------------------------------------------------------------
-- Cannot delete Default Rating Methods from the
-- system
--------------------------------------------------------------

if  exists (  select 1 from tb_RatingMethod where RatingMethodID = @RatingMethodID and RatingMethodID < 0)
Begin

	set @ErrorDescription = 'ERROR !!! Cannot delete a default Rating Method'
	set @ResultFlag = 1
	Return 1


End


-------------------------------------------------------------
-- Ensure that there is no Rating Method associated with the
-- Rating Method.
-------------------------------------------------------------
if exists (
				Select 1 
				from tb_Rate tbl1
				where tbl1.RatingMethodID = @RatingMethodID
	        )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete the Rating Method as it is associated to one or more rates'
		set @ResultFlag = 1
		Return 1

End

------------------------------------
-- Delete records from :
-- Rating Method Detail
-- Rating Method
--------------------------------------

Begin Transaction DeleteRM

Begin Try

		-------------------------
		-- RATING METHOD DETAIL
		-------------------------

		Delete from tb_RatingMethodDetail 
		where RatingMethodID = @RatingMethodID

		-------------------------
		-- RATE NUMBER IDENTIFIER
		-------------------------

		Delete from tb_RateNumberIdentifier 
		where RatingMethodID = @RatingMethodID

		--------------------------
		-- RATING METHOD
		--------------------------

		Delete from tb_RatingMethod
		where RatingMethodID = @RatingMethodID

End Try
 
Begin Catch
 
        set  @ResultFlag = 1
        set  @ErrorDescription = 'ERROR !!! Deleting record for Rating Method. '+ ERROR_MESSAGE()
		Rollback Transaction DeleteRM
        Return 1     
 
End Catch

Commit Transaction DeleteRM
 
Return 0
GO
