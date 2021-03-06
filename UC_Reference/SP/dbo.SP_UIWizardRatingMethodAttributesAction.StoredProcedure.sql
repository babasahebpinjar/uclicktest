USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingMethodAttributesAction]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingMethodAttributesAction]
(
	@SessionID varchar(36),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

--	Values are:
        -- WizardName = Rating Method Attributes
		-- WizardStep = 1
		-- UserID  = UserID
		-- IsMultiRecord = 1
		-- VariableDataType = int
		-- VariableName = RatingMethodID
		-- VariableValue = RatingMethodID
		-- Attribute1 = RateItemID
		-- Atrribute2 = ItemValue
		-- Attribute3 = Item Number


set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------------
-- Validate to ensure that session ID is not NULL and exists in the master
-- wizard table
----------------------------------------------------------------------------

if ( 
		( @SessionID is NULL )
		or
		not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Rating Method Attributes' and WizardStep = 1)
   )
Begin

		set @ErrorDescription = 'ERROR !!! Session ID is null or not a valid value'
		set @ResultFlag = 1
		Return 1


End

-------------------------------------------------------------------
-- Validate to ensure that the session does not contain records for
-- more than one Rating Method
-------------------------------------------------------------------

if (
     ( 
		select count(distinct VariableValue)
		from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and WizardName = 'Rating Method Attributes' 
		and WizardStep = 1
	 ) > 1
   )
Begin

		set @ErrorDescription = 'ERROR !!! Multiple Rating Method provided to wizard for Action under one session'
		set @ResultFlag = 1
		Return 1


End

Declare @RatingMethodID int

select @RatingMethodID = convert(int , VariableValue )
from wtb_Wizard_MassSetup
where SessionID = @SessionID
and WizardName = 'Rating Method Attributes' 
and WizardStep = 1

-----------------------------------------------------------
-- Make sure that the rating method exists in the system 
-----------------------------------------------------------

if not exists ( select 1 from tb_RatingMethod where RatingMethodID =  @RatingMethodID)
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method passed to action wizard does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

-----------------------------------------------------------------
-- Make sure the Rating Method being edited is not a default
-----------------------------------------------------------------

if ( @RatingMethodID < 0 )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot make change to a default rating method via user interface. Please check with administrator'
		set @ResultFlag = 1
		Return 1	

End

------------------------------------------------------------------
-- Ensure that all the Rate Items defined under the Rate Structure
-- of Rating Method are available in this action session of the
-- wizard
-------------------------------------------------------------------

Declare @RateStructureID int

select @RateStructureID = RateStructureID
from tb_RatingMethod
where RatingMethodID = @RatingMethodID

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rating Method Attributes' 
				and WizardStep = 1
				and convert(int, Attribute1) not in
				(
					select tbl1.RateItemID 
					from tb_RateStructureRateItem tbl1
					inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
					where tbl1.RateStructureID = @RateStructureID
					and tbl2.RateItemTypeID not in (1,4,5) 
					and tbl1.flag & 1 <> 1
					and tbl2.Flag & 1 <> 1

				)
		  )
Begin

		set @ErrorDescription = 'ERROR !!! One or more Rate Items mentioned in wizard are not associated with the Rating Method definition '
		set @ResultFlag = 1
		Return 1

End


if exists (

				select 1 
				from tb_RateStructureRateItem tbl1
				inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
				where tbl1.RateStructureID = @RateStructureID
				and tbl2.RateItemTypeID not in (1,4,5) 
				and tbl1.flag & 1 <> 1
				and tbl2.Flag & 1 <> 1
				and tbl1.RateItemID not in
				(
					select convert(int, Attribute1)
					from wtb_Wizard_MassSetup
					where SessionID = @SessionID
					and WizardName = 'Rating Method Attributes' 
					and WizardStep = 1
				)
		  )
Begin

		set @ErrorDescription = 'ERROR !!! One or more Rate Items associated with the Rating Method definition are not passed to the action wizard'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------------------------
-- Ensure there are no multiple entries in the wizard for any
-- rate item
---------------------------------------------------------------------

if exists (
             select 1 
			 from
             (
				select count(*) as TotalRecords, Attribute1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rating Method Attributes' 
				and WizardStep = 1
				Group by Attribute1
				having count(1) > 1
			 ) tbl1
          )
Begin

		set @ErrorDescription = 'ERROR !!! One or more Rate Items associated with the Rating Method definition have multiple values passed to the action wizard'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------
-- Ensure that all the attributes are either NULL or Numeric
-- values, unless it is a dimension template
-------------------------------------------------------------

if exists (
				select 1
				from tb_RateStructureRateItem tbl1
				inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
				inner join wtb_Wizard_MassSetup tbl3 on tbl1.RateItemID = convert(int , Attribute1)
				where tbl1.RateStructureID = @RateStructureID
				and tbl2.RateItemTypeID = 3 -- Rate Dimension Item Type
				and tbl3.SessionID = @SessionID
				and tbl3.WizardName = 'Rating Method Attributes' 
				and 
				  ( 
				     tbl3.Attribute2 is NULL
					 or
					 (
						 tbl3.Attribute2 is not NULL
						 and
						 ISNUMERIC(tbl3.Attribute2) = 0
					 )
				  )
		  )
Begin

		set @ErrorDescription = 'ERROR !!! Dimension type Rate Item cannot be NULL or invalid non numerical value  '
		set @ResultFlag = 1
		Return 1

End

if exists (
				select 1
				from tb_RateStructureRateItem tbl1
				inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
				inner join wtb_Wizard_MassSetup tbl3 on tbl1.RateItemID = convert(int , Attribute1)
				where tbl1.RateStructureID = @RateStructureID
				and tbl2.RateItemTypeID <> 3 -- Not Rate Dimension Item Type
				and tbl3.SessionID = @SessionID
				and tbl3.WizardName = 'Rating Method Attributes' 
				and tbl3.Attribute2 is not NULL
				and isnumeric(tbl3.Attribute2)  =  0
				 
		  )
Begin

		set @ErrorDescription = 'ERROR !!! One or more Rating Method Items have invalid non numerical values  '
		set @ResultFlag = 1
		Return 1

End

------------------------------------------------------------
-- Check the validity of any associated Dimension Template
------------------------------------------------------------

Declare @VarRateDimensionTemplateID int,
        @ErrorDecription2 varchar(2000),
		@ResultFlag2 int

Declare Validate_Rdt_Cur Cursor For
select convert(int , Attribute2)
from wtb_Wizard_MassSetup tbl1  
inner join tb_RateItem tbl2 on convert(int , tbl1.Attribute1) = tbl2.RateItemID 
where tbl2.RateItemTypeID = 3 -- Rate Dimension Item Type
and tbl1.SessionID = @SessionID
and tbl1.WizardName = 'Rating Method Attributes' 

OPEN Validate_Rdt_Cur   
FETCH NEXT FROM Validate_Rdt_Cur
INTO @VarRateDimensionTemplateID

WHILE @@FETCH_STATUS = 0   
BEGIN 

	  Begin Try

			set @ErrorDecription2 = NULL
			set @ResultFlag2 = 0

			Exec SP_UIRateDimensionTemplateValidate @VarRateDimensionTemplateID ,@ErrorDecription2 Output , @ResultFlag2 output

			if (@ResultFlag2 <> 0 )
			Begin

					set @ErrorDescription = @ErrorDecription2 + ' Exception during configuration of Rating method attributes'
					set @ResultFlag = 1

					CLOSE Validate_Rdt_Cur  
					DEALLOCATE Validate_Rdt_Cur

					Return 1
			End

	  End Try

	  Begin Catch

			set @ErrorDescription = 'ERROR !!! Exception while validating associated dimension templates of rating method'
			set @ResultFlag = 1

			CLOSE Validate_Rdt_Cur  
			DEALLOCATE Validate_Rdt_Cur

			Return 1

	  End Catch
       

	   FETCH NEXT FROM Validate_Rdt_Cur
	   INTO @VarRateDimensionTemplateID
 
END   

CLOSE Validate_Rdt_Cur  
DEALLOCATE Validate_Rdt_Cur

----------------------------------------------------------
-- Perform Rate item specific validations to ensure data
-- integrity
----------------------------------------------------------

---------------------
-- MINIMUM RATE ITEM
---------------------
------------------------------------------------------
-- Value should be NULL or greater than equal to zero
------------------------------------------------------

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rating Method Attributes' 
				and WizardStep = 1
				and convert(int, Attribute1)  = 201
				and convert(int , Attribute2) is not NULL
				and convert(int , Attribute2) < 0
				 
		  )
Begin

		set @ErrorDescription = 'ERROR !!! Minimum Value should either be NULL or Greater than equal to zero '
		set @ResultFlag = 1
		Return 1

End

---------------------
-- MAXIMUM RATE ITEM
---------------------
-------------------------------------------------------------------------------------
-- Value should be NULL or greater than equal to zero and should be more than MINIMUM
-------------------------------------------------------------------------------------

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rating Method Attributes' 
				and WizardStep = 1
				and convert(int, Attribute1)  = 204
				 
		  )
Begin

        Declare @Maximum int,
		        @Minimum int

		Select @Maximum = convert(int , Attribute2)
		from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and WizardName = 'Rating Method Attributes' 
		and WizardStep = 1
		and convert(int, Attribute1)  = 204

		Select @Minimum = convert(int , Attribute2)
		from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and WizardName = 'Rating Method Attributes' 
		and WizardStep = 1
		and convert(int, Attribute1)  = 201

		if ( @Maximum is not NULL and @Maximum < 0 )
		Begin

				set @ErrorDescription = 'ERROR !!! Maximum Value should either be NULL or Greater than equal to zero '
				set @ResultFlag = 1
				Return 1

		End


		if ( @Minimum is not NULL and @Minimum > @Maximum)
		Begin

				set @ErrorDescription = 'ERROR !!! Maximum Value should be greater than the Minimum Value '
				set @ResultFlag = 1
				Return 1

		End

End

---------------------------------------------
-- INITIAL and ADDITIONAL ROUNDING RATE ITEMS
---------------------------------------------
--------------------------------------------------------
-- Value should be NULL or greater than equal to ONE
--------------------------------------------------------

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rating Method Attributes' 
				and WizardStep = 1
				and convert(int, Attribute1) in (202, 203)
				and convert(int , Attribute2) is not NULL
				and convert(int , Attribute2) < 1
				 
		  )
Begin

		set @ErrorDescription = 'ERROR !!! Initial and Additional Rounding should either be NULL or Greater Than equal to 1  '
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------
-- TREAT MAXIMUM AS DURATION CAP Rate Item
--------------------------------------------

----------------------------------------
-- Acceptable Values are:
-- 1. 1 only if Maximum is not NULL
-- 2. Default Value 0
----------------------------------------

if exists ( 
			select 1
			from wtb_Wizard_MassSetup
			where SessionID = @SessionID
			and WizardName = 'Rating Method Attributes' 
			and WizardStep = 1
			and convert(int, Attribute1) = 217
		  )
Begin

		Declare @TreatMaxAsCapFlag int

		select @TreatMaxAsCapFlag = convert(int, Attribute2) 
		from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and WizardName = 'Rating Method Attributes' 
		and WizardStep = 1
		and convert(int, Attribute1) = 217

		if (@TreatMaxAsCapFlag is NULL)
				set @TreatMaxAsCapFlag = 0 -- Default Value as 0

		if ( @TreatMaxAsCapFlag = 1  )
		Begin

				if exists(
								select 1
								from wtb_Wizard_MassSetup
								where SessionID = @SessionID
								and WizardName = 'Rating Method Attributes' 
								and WizardStep = 1
								and convert(int, Attribute1)  = 204
						 )
				Begin

						if (
								(
									select convert(int , Attribute2)
									from wtb_Wizard_MassSetup
									where SessionID = @SessionID
									and WizardName = 'Rating Method Attributes' 
									and WizardStep = 1
									and convert(int, Attribute1)  = 204
								) is NULL
							)
						Begin

								set @ErrorDescription = 'ERROR !!! Treat Maximum Duration as CAP cannot be enabled when Maximum Rate Item is NULL  '
								set @ResultFlag = 1
								Return 1

						End

				End

				Else
				Begin

						set @ErrorDescription = 'ERROR !!! Treat Maximum Duration as CAP is being send to Wizard for configuration while Maximum Rate Item is missing  '
						set @ResultFlag = 1
						Return 1

				End				

		End

End

----------------------------------------------------------
-- GROUP AND SUB GROUP VOLUME COMMITMENT Rate Items
----------------------------------------------------------

------------------------------------------
-- Values can be NULL or greater than 0
------------------------------------------

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rating Method Attributes' 
				and WizardStep = 1
				and convert(int, Attribute1) in (206, 207)
				and convert(int , Attribute2) is not NULL
				and convert(int , Attribute2) <= 0
				 
		  )
Begin

		set @ErrorDescription = 'ERROR !!! Group and Sub Group Volume commitment should either be NULL or Greater than 0  '
		set @ResultFlag = 1
		Return 1

End

---------------------------------------------------------
-- Check to ensure the dimension rate items that have 
-- been passed to the wizard are of the correct
-- dimension type
---------------------------------------------------------

if exists (
				Select 1 
				from tb_RateStructureRateItem tbl1
				inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
				where tbl1.RateStructureID = @RateStructureID
				and tbl2.RateItemTypeID = 3 -- Rate Dimensions
          )
Begin

		  Create Table #TempRatingMethodDimensions (RateItemID int, ItemValue int)

		  insert into  #TempRatingMethodDimensions
		  select  convert(int , tbl1.Attribute1) , convert(int , tbl1.Attribute2)
		  from wtb_Wizard_MassSetup tbl1
		  inner join tb_RateItem tbl2 on convert(int , tbl1.Attribute1) = tbl2.RateItemID
		  where tbl1.SessionID = @SessionID
		  and tbl1.WizardName = 'Rating Method Attributes' 
		  and tbl1.WizardStep = 1
		  and tbl2.RateItemTypeID = 3

		 if exists(  
					  select 1
					  from #TempRatingMethodDimensions tbl1
					  inner join tb_RateDimension tbl3 on (tbl1.RateItemID - 300) = tbl3.RateDimensionID
					  inner join tb_RateDimensionTemplate tbl4 on tbl1.ItemValue = tbl4.RateDimensionTemplateID
					  inner join tb_RateDimension tbl5 on tbl4.RateDimensionID = tbl5.RateDimensionID
					  where tbl3.RateDimensionID <>  tbl5.RateDimensionID
				  )
		 Begin


				set @ErrorDescription = 'ERROR !!! The Dimension Template attached to the Rating method is not as per the correct dimension type in the definition  '
				set @ResultFlag = 1
				drop table #TempRatingMethodDimensions
				Return 1

		 End

	     drop table #TempRatingMethodDimensions

End

------------------------------------------------------------------------
-- Insert or update rating method details depending on whether entry
-- exists or not
------------------------------------------------------------------------

Declare @VarRateItemID int,
        @VarItemValue int,
		@VarItemNumber int,
		@OldRatingDimensionTemplateID int

Begin Transaction RMD_Trans

Declare RatingMethodDetail_Cur Cursor For
select convert(int, Attribute1) , convert(int , Attribute2) , convert(int , Attribute3)
from wtb_Wizard_MassSetup
where SessionID = @SessionID
and WizardName = 'Rating Method Attributes' 
and WizardStep = 1

Open RatingMethodDetail_Cur   
Fetch Next From RatingMethodDetail_Cur
Into @VarRateItemID  , @VarItemValue , @VarItemNumber

While @@FETCH_STATUS = 0   
Begin  

		Begin Try

				if exists ( 
				            select 1 
				            from tb_RatingmethodDetail 
							where RatingMethodID = @RatingMethodID
							and RateItemID = @VarRateItemID
						  ) -- Already existing record
				Begin

				        --------------------------------------------------------------------
						-- If the item to be updated is of the type dimension, then we need
						-- to check if lod value and new value are same. If they are different
						-- then we need to check, if there is any rate assigned to the rating
						-- method. Following can happen:
						-- No Rate attached, so system shoud allow to update and remove data
						-- from tbRateNumberIdentifier
						-- Rate attached so action should fail
						---------------------------------------------------------------------

						---------------------------------------------------
						-- Check if the rate item is of the type dimension
						---------------------------------------------------

						if exists ( 
						             select 1
									 from tb_RateItem
									 where RateItemID= @VarRateItemID 
									 and RateItemTypeID =  3-- Dimension

								  )
						Begin

						       -------------------------------------------------
							   -- Check if the old and new value are the same or
							   -- not
							   -------------------------------------------------

							   select @OldRatingDimensionTemplateID = convert(int , ItemValue)
							   from tb_RatingMethodDetail
							   where RatingMethodID = @RatingMethodID
							   and RateItemID = @VarRateItemID
							   	   
								if ( @VarItemValue <> @OldRatingDimensionTemplateID)
								Begin

										--------------------------------------------------------
										-- Need to check if there are any rates assigned to the
										-- rating method.
										---------------------------------------------------------

										if exists ( 
													  select 1 
													  from tb_rate
													  where RatingmethodID = @RatingMethodID
												  )
										Begin

												set @ErrorDescription = 'ERROR !!! Cannot change the associated rate dimension template as the rating method is being used for one or more rates '
												set @ResultFlag = 1

												Rollback Transaction RMD_Trans

												CLOSE RatingMethodDetail_Cur  
												DEALLOCATE RatingMethodDetail_Cur

												Return 1

										End

										----------------------------------------------------------
										-- If no rates associated, then delete the entries from
										-- tb_RateNumberIdentifier table for old dimension template
										----------------------------------------------------------

										Else
										Begin

												Delete from tb_RateNumberIdentifier
												where RatingmethodID = @RatingMethodID

										End


								End

								----------------------------------------------------
								-- If there is no change in new and old value then
								-- move on to the next rate item
								----------------------------------------------------
								Else
								Begin

										GOTO FETCHNEXTREC

								End

						End

						update tb_RatingmethodDetail
						set ItemValue = @VarItemValue
						where RatingMethodID = @RatingMethodID
						and RateItemID = @VarRateItemID

				End

				Else -- New record
				Begin

						insert into tb_RatingmethodDetail
						( RatingMethodID , Number , ItemValue , RateItemID , ModifiedDate , ModifiedByID , Flag )
						Values
						(@RatingMethodID , @VarItemNumber , @VarItemValue , @VarRateItemID , getdate() , @UserID , 0)

				End


		End Try

		Begin Catch

				set @ErrorDescription = 'ERROR !!! While updating attributes for Rating Method. '+ ERROR_MESSAGE()
				set @ResultFlag = 1

				Rollback Transaction RMD_Trans

				CLOSE RatingMethodDetail_Cur  
				DEALLOCATE RatingMethodDetail_Cur

				Return 1

		End Catch

FETCHNEXTREC:

		Fetch Next From RatingMethodDetail_Cur
		Into @VarRateItemID  , @VarItemValue, @VarItemNumber

End


CLOSE RatingMethodDetail_Cur  
DEALLOCATE RatingMethodDetail_Cur

Commit Transaction RMD_Trans


Return 0
GO
