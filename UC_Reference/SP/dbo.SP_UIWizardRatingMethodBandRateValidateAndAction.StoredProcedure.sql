USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingMethodBandRateValidateAndAction]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingMethodBandRateValidateAndAction]
(
	@SessionID varchar(36),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

-- ACTION INSERT
--	Values are:
		-- WizardStep = 1
		-- VariableDataType = int
		-- VariableName = RatingMethodID
		-- VariableValue = RatingMethodID
		-- Attribute1 = RateDimension1Band
		-- Atrribute2 = RateDimension2Band
		-- Attribute3 = RateDimension3Band
		-- Attribute4 = RateDimension4Band
		-- Attribute5 = RateDimension5Band
		-- Attribute6 = RateItemID
		-- Attribute7  = NULL


-- ACTION UPDATE
--	Values are:
		-- WizardStep = 2
		-- VariableDataType = int
		-- VariableName = RatingMethodID
		-- VariableValue = RatingMethodID
		-- Attribute1 = RateDimension1Band
		-- Atrribute2 = RateDimension2Band
		-- Attribute3 = RateDimension3Band
		-- Attribute4 = RateDimension4Band
		-- Attribute5 = RateDimension5Band
		-- Attribute6 = RateItemID
	    -- Attribute7  = RateNumberIdentifierID


-- ACTION DELETE
--	Values are:
		-- WizardStep = 3
		-- VariableDataType = int
		-- VariableName = RatingMethodID
		-- VariableValue = RatingMethodID
		-- Attribute1 = NULL
		-- Atrribute2 = NULL
		-- Attribute3 = NULL
		-- Attribute4 = NULL
		-- Attribute5 = NULL
		-- Attribute6 = NULL
	    -- Attribute7  = RateNumberIdentifierID

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------------
-- Validate to ensure that session ID is not NULL and exists in the master
-- wizard table
----------------------------------------------------------------------------

if ( 
		( @SessionID is NULL )
		or
		not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Rating Method Band Rate Action' and WizardStep in (1,2,3))
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
		and WizardName = 'Rating Method Band Rate Action' 
		and WizardStep in (1,2,3)
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
and WizardName = 'Rating Method Band Rate Action' 
and WizardStep in (1,2,3)

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

------------------------------------------------------------------------------
-- Check to ensure that the Rate Item is of the type RATE TYPE and is not NULL
-------------------------------------------------------------------------------

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rating Method Band Rate Action' 
				and WizardStep in (1,2)
				and Attribute6 is NULL
          )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Tier attached to dimension band is NULL for one or more records'
		set @ResultFlag = 1
		Return 1

End


if exists (
				select 1
				from wtb_Wizard_MassSetup tbl1
				inner join tb_RateItem tbl2 on convert(int , tbl1. Attribute6) = tbl2.RateItemID
				where tbl1.SessionID = @SessionID
				and tbl1.WizardName = 'Rating Method Band Rate Action' 
				and tbl1.WizardStep in (1,2)
				and tbl2.RateItemTypeID <> 1 -- RATE TYPE item
          )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Tier attached to dimension band is not of the type RATE TYPE'
		set @ResultFlag = 1
		Return 1

End

------------------------------------------------------------------------------
-- Validate to ensure that all the rate dimension templates attached to the
-- rating method are same as the rate dimesnion templates , whose dimension 
-- bands are being allocated to rate tiers
------------------------------------------------------------------------------

Declare @VarRateDimensionTemplateID int,
        @DimensionCounter int = 1

Create Table #TempAllowedDimensionTemplates
(
	RateDimensionTemplate1ID int,
	RateDimensionTemplate2ID int,
	RateDimensionTemplate3ID int,
	RateDimensionTemplate4ID int,
	RateDimensionTemplate5ID int
)

insert into #TempAllowedDimensionTemplates values (NULL , NULL , NULL , NULL , NULL )

Declare Allowed_RateDimenstionTemplate_Cur Cursor For
select convert(int ,tbl1.ItemValue) 
from tb_RatingMethodDetail tbl1
inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
where tbl2.RateItemTypeID = 3 -- Dimension rate Item
and tbl1.RatingMethodID = @RatingMethodID
order by tbl1.Number

Open Allowed_RateDimenstionTemplate_Cur  
Fetch Next From Allowed_RateDimenstionTemplate_Cur
Into @VarRateDimensionTemplateID

While @@FETCH_STATUS = 0   
Begin  

		if (@DimensionCounter = 1) 
		Begin    
			update #TempAllowedDimensionTemplates set RateDimensionTemplate1ID = @VarRateDimensionTemplateID
		End

		if (@DimensionCounter = 2)   
		Begin     
			update #TempAllowedDimensionTemplates set RateDimensionTemplate2ID = @VarRateDimensionTemplateID
		End

		if (@DimensionCounter = 3)    
		Begin    
			update #TempAllowedDimensionTemplates set RateDimensionTemplate3ID = @VarRateDimensionTemplateID
		End

		if (@DimensionCounter = 4)   
		Begin     
			update #TempAllowedDimensionTemplates set RateDimensionTemplate4ID = @VarRateDimensionTemplateID
		End

		if (@DimensionCounter = 5)    
		Begin    
			update #TempAllowedDimensionTemplates set RateDimensionTemplate5ID = @VarRateDimensionTemplateID
		End

        set @DimensionCounter = @DimensionCounter + 1

		Fetch Next From Allowed_RateDimenstionTemplate_Cur
		Into @VarRateDimensionTemplateID

End

Close Allowed_RateDimenstionTemplate_Cur
DeAllocate Allowed_RateDimenstionTemplate_Cur

select db1.RateDimensionTemplateID as RateDimensionTemplate1ID,
       db2.RateDimensionTemplateID as RateDimensionTemplate2ID,
	   db3.RateDimensionTemplateID as RateDimensionTemplate3ID,
	   db4.RateDimensionTemplateID as RateDimensionTemplate4ID,
	   db5.RateDimensionTemplateID as RateDimensionTemplate5ID
into #TempRateNumberIdentifier
from wtb_Wizard_MassSetup tbl1
left join tb_RateDimensionBand as db1 on convert(int ,tbl1.Attribute1) = db1.RateDimensionBandID
left join tb_RateDimensionBand as db2 on convert(int ,tbl1.Attribute2) = db2.RateDimensionBandID
left join tb_RateDimensionBand as db3 on convert(int ,tbl1.Attribute3) = db3.RateDimensionBandID
left join tb_RateDimensionBand as db4 on convert(int ,tbl1.Attribute4) = db4.RateDimensionBandID
left join tb_RateDimensionBand as db5 on convert(int ,tbl1.Attribute5) = db5.RateDimensionBandID
where tbl1.SessionID = @SessionID
and tbl1.WizardName = 'Rating Method Band Rate Action' 
and tbl1.WizardStep in (1,2) -- Insert and update operation
and convert(int , tbl1.VariableValue) = @RatingMethodID

--select * from #TempAllowedDimensionTemplates
--select * from #TempRateNumberIdentifier

if exists ( 
				select 1 
				from #TempRateNumberIdentifier
				where ltrim(rtrim(isnull(RateDimensionTemplate1ID , '9999'))) + '|' +
				ltrim(rtrim(isnull(RateDimensionTemplate2ID , '9999'))) + '|' +
				ltrim(rtrim(isnull(RateDimensionTemplate3ID , '9999'))) + '|' +
				ltrim(rtrim(isnull(RateDimensionTemplate4ID , '9999'))) + '|' +
				ltrim(rtrim(isnull(RateDimensionTemplate5ID , '9999'))) 
				not in
				(
					select ltrim(rtrim(isnull(RateDimensionTemplate1ID , '9999'))) + '|' +
					ltrim(rtrim(isnull(RateDimensionTemplate2ID , '9999'))) + '|' +
					ltrim(rtrim(isnull(RateDimensionTemplate3ID , '9999'))) + '|' +
					ltrim(rtrim(isnull(RateDimensionTemplate4ID , '9999'))) + '|' +
					ltrim(rtrim(isnull(RateDimensionTemplate5ID , '9999')))
					from #TempAllowedDimensionTemplates
				)			
          )
Begin

		set @ErrorDescription = 'ERROR !!!Rate Dimension Template of dimension bands not same as the dimension templates associated with Rating Method '
		set @ResultFlag = 1
		drop table #TempAllowedDimensionTemplates
		drop table #TempRateNumberIdentifier
		Return 1

End

drop table #TempAllowedDimensionTemplates
drop table #TempRateNumberIdentifier

----------------------------------------------------------------------------
-- Validate to ensure that the combination of dimension bands and rate tiers 
-- is unique
----------------------------------------------------------------------------

select ltrim(rtrim(isnull(Attribute1 , '9999'))) + '|' +
ltrim(rtrim(isnull(Attribute2 , '9999'))) + '|' +
ltrim(rtrim(isnull(Attribute3 , '9999'))) + '|' +
ltrim(rtrim(isnull(Attribute4 , '9999'))) + '|' +
ltrim(rtrim(isnull(Attribute5 , '9999'))) + '|' +
ltrim(rtrim(Attribute6)) as DimensionBandRate
into #TempDimensionBandRate
from wtb_Wizard_MassSetup
where SessionID = @SessionID
and WizardName = 'Rating Method Band Rate Action' 
and WizardStep in (1,2) -- Insert and Update records


if exists (
				select 1
				from
				(
					select count(*) as TotalRecords , DimensionBandRate
					from #TempDimensionBandRate
					group by DimensionBandRate
					having count(1) > 1
				) tbl1			
          )
Begin

		set @ErrorDescription = 'ERROR !!! Multiple records exist for dimension band(s) and Rate tier combination '
		set @ResultFlag = 1
		drop table #TempDimensionBandRate
		Return 1

End


if exists (
				select 1
				from
				(
					select count(ltrim(rtrim(Attribute6))) as TotalRecords,
					ltrim(rtrim(isnull(Attribute1 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute2 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute3 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute4 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute5 , '9999'))) as DimensionBand
					from wtb_Wizard_MassSetup
					where SessionID = @SessionID
					and WizardName = 'Rating Method Band Rate Action' 
					and WizardStep in (1,2) -- Insert and Update records
					group by ltrim(rtrim(isnull(Attribute1 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute2 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute3 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute4 , '9999'))) + '|' +
					ltrim(rtrim(isnull(Attribute5 , '9999')))
					having count(1) > 1
				) tbl1			
          )
Begin

		set @ErrorDescription = 'ERROR!!! Same dimension band assigned to multiple Rate Tiers '
		set @ResultFlag = 1
		drop table #TempDimensionBandRate
		Return 1

End

if exists (
				select 1
				from
				(
					select count(*) as TotalRecords,
					ltrim(rtrim(Attribute6 )) as RateTier
					from wtb_Wizard_MassSetup
					where SessionID = @SessionID
					and WizardName = 'Rating Method Band Rate Action' 
					and WizardStep in (1,2) -- Insert and Update records
					group by ltrim(rtrim(Attribute6 ))
					having count(1) > 1
				) tbl1			
          )
Begin

		set @ErrorDescription = 'ERROR!!! Rate Tier assigned to multiple dimesion bands '
		set @ResultFlag = 1
		drop table #TempDimensionBandRate
		Return 1

End

Drop table #TempDimensionBandRate

---------------------------------------------------------------
-- Open Session to perfrom the neccessary actions, and commit
-- or Rollback in one block
---------------------------------------------------------------

Begin Transaction ActionPerform

-------------
-- DELETION
-------------
Begin Try

    Create table #TempRateNumberIdentifierDelete (RateNumberIdentifierID int )

	insert into #TempRateNumberIdentifierDelete
	select convert(int , Attribute7 )
	from wtb_Wizard_MassSetup
	where SessionID = @SessionID
	and WizardName = 'Rating Method Band Rate Action' 
	and WizardStep= 3 -- Delete

	Delete tbl1
	from tb_RateNumberIdentifier tbl1
	inner join #TempRateNumberIdentifierDelete tbl2 on tbl1.RateNumberIdentifierID = tbl2.RateNumberIdentifierID

	Drop table #TempRateNumberIdentifierDelete

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! While deleting Rating Method Band Rate. '+ERROR_MESSAGE()
		set @ResultFlag = 1

		Drop table #TempRateNumberIdentifierDelete

		Rollback Transaction ActionPerform

		Return 1

End Catch


-------------
-- UPDATE
-------------
Begin Try

    Create table #TempRateNumberIdentifierUpdate 
	(
		RateNumberIdentifierID int,
		RateDimension1BandID int,
		RateDimension2BandID int,
		RateDimension3BandID int,
		RateDimension4BandID int,
		RateDimension5BandID int,
		RatingMethodID int,
		RateItemID int,
		UserID int
	)

	insert into #TempRateNumberIdentifierUpdate
	(
		RateNumberIdentifierID,
		RateDimension1BandID ,
		RateDimension2BandID ,
		RateDimension3BandID ,
		RateDimension4BandID ,
		RateDimension5BandID ,
		RatingMethodID ,
		RateItemID ,
		UserID 
	)
	select convert(int , Attribute7 ),
	convert(int , Attribute1 ),
	convert(int , Attribute2 ),
	convert(int , Attribute3 ),
	convert(int , Attribute4 ),
	convert(int , Attribute5 ),
	convert(int ,VariableValue),
	convert(int , Attribute6 ),
	UserID
	from wtb_Wizard_MassSetup
	where SessionID = @SessionID
	and WizardName = 'Rating Method Band Rate Action' 
	and WizardStep= 2 -- Update

	update tbl1
	set tbl1.RateDimension1BandID = tbl2.RateDimension1BandID,
	    tbl1.RateDimension2BandID = tbl2.RateDimension2BandID,
	    tbl1.RateDimension3BandID = tbl2.RateDimension3BandID,
		tbl1.RateDimension4BandID = tbl2.RateDimension4BandID,
		tbl1.RateDimension5BandID = tbl2.RateDimension5BandID,
		tbl1.RateItemID = tbl2.RateItemID,
		tbl1.ModifiedDate = getdate(),
		tbl1.ModifiedByID = tbl2.UserID
	from tb_RateNumberIdentifier tbl1
	inner join #TempRateNumberIdentifierUpdate tbl2 on tbl1.RateNumberIdentifierID= tbl2.RateNumberIdentifierID

	Drop table #TempRateNumberIdentifierUpdate

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! While updating Rating Method Band Rate. '+ERROR_MESSAGE()
		set @ResultFlag = 1

		Drop table #TempRateNumberIdentifierUpdate

		Rollback Transaction ActionPerform

		Return 1

End Catch


-------------
-- INSERT
-------------
Begin Try

	insert into tb_RateNumberIdentifier
	(
		RateDimension1BandID ,
		RateDimension2BandID ,
		RateDimension3BandID ,
		RateDimension4BandID ,
		RateDimension5BandID ,
		RatingMethodID ,
		RateItemID ,
		ModifiedByID,
		ModifiedDate,
		Flag 
	)
	select
	convert(int , Attribute1 ),
	convert(int , Attribute2 ),
	convert(int , Attribute3 ),
	convert(int , Attribute4 ),
	convert(int , Attribute5 ),
	convert(int ,VariableValue),
	convert(int , Attribute6 ),
	UserID,
	getdate(),
	0
	from wtb_Wizard_MassSetup
	where SessionID = @SessionID
	and WizardName = 'Rating Method Band Rate Action' 
	and WizardStep= 1 -- Insert

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! While inserting Rating Method Band Rate. '+ERROR_MESSAGE()
		set @ResultFlag = 1

		Rollback Transaction ActionPerform

		Return 1

End Catch

Commit Transaction ActionPerform

Return 0
GO
