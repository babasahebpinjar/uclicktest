USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingDimensionActionDateTime]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingDimensionActionDateTime]
(
	@SessionID varchar(36),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

-- ACTION INSERT
--	Values are:
		-- WizardStep = 2
		-- VariableDataType = int
		-- VariableName = RateDimensionTemplateID
		-- VariableValue = RateDimensionTemplateID
		-- Attribute1 = DateTimeBandID
		-- Atrribute2 = EventYear
		-- Attribute3 = EventMonth
		-- Attribute4 = EventDay
		-- Attribute5 = EventWeekDay
		-- Attribute6 = FromField
	    -- Attribute7  = ToField

-- ACTION UPDATE
--	Values are:
		-- WizardStep = 3
		-- VariableDataType = int
		-- VariableName = RateDimensionTemplateID
		-- VariableValue = RateDimensionTemplateID
		-- Attribute1 = DateTimeBandID
		-- Atrribute2 = EventYear
		-- Attribute3 = EventMonth
		-- Attribute4 = EventDay
		-- Attribute5 = EventWeekDay
		-- Attribute6 = FromField
	    -- Attribute7  = ToField
		-- Attribute8 = DateTimeBandDetailID

-- ACTION DELETE
--	Values are:
		-- WizardStep = 4
		-- VariableDataType = int
		-- VariableName = RateDimensionTemplateID
		-- VariableValue = RateDimensionTemplateID
		-- Attribute1 = DateTimeBandID
		-- Attribute8 = DateTimeBandDetailID

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------------
-- Validate to ensure that session ID is not NULL and exists in the master
-- wizard table
----------------------------------------------------------------------------

if ( 
		( @SessionID is NULL )
		or
		not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Date And Time Dimension Action' and WizardStep in (2,3,4))
   )
Begin

		set @ErrorDescription = 'ERROR !!! Session ID is null or not a valid value'
		set @ResultFlag = 1
		Return 1


End

-------------------------------------------------------------------
-- Validate to ensure that the session does not contain records for
-- more than one Rate Dimension Template
-------------------------------------------------------------------

if (
     ( 
		select count(distinct VariableValue)
		from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and WizardName = 'Date And Time Dimension Validate' 
		and WizardStep in (2,3,4)
	 ) > 1
   )
Begin

		set @ErrorDescription = 'ERROR !!! Multiple Rate Dimension Template provided to wizard for Action under one session'
		set @ResultFlag = 1
		Return 1


End

Declare @RateDimensionTemplateID int

select @RateDimensionTemplateID = convert(int , VariableValue )
from wtb_Wizard_MassSetup
where SessionID = @SessionID
and WizardName = 'Date And Time Dimension Action' 
and WizardStep in (2,3,4)

------------------------------------------------------------------------------
-- Validate to ensure that all the distinct DatetimeBandIDs exist in the
-- system under the mentioned Rate Dimension Template
------------------------------------------------------------------------------

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Date And Time Dimension Action' 
				and WizardStep in (2,3,4)
				and convert(int, Attribute1) not in
				(
					select RateDimensionBandID
					from tb_RateDimensionBand
					where RateDimensionTemplateID = @RateDimensionTemplateID
				)
		  )
Begin

		set @ErrorDescription = 'ERROR !!! One or more Rate Dimension Bands mentioned in wizard does not belong to the Rate Dimension Template '
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------------
-- Incase of Update or Delete Action, the DatetimeBandDeTailID
-- should be not NULL and valid value
-------------------------------------------------------------------


if exists (
     			select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Date And Time Dimension Action' 
				and WizardStep in (3,4) -- Update or Delete
				and Attribute8 is NULL
          )
Begin

		set @ErrorDescription = 'ERROR !!! Dimension Band Detail ID cannot be NULL for UPDATE or DELETE action '
		set @ResultFlag = 1
		Return 1


End

--------------------------------------------------------------------
-- Incase of Update or Delete Action, the DatetimeBandDeTailID
-- should belong to the Date Time Band for the dimension Template
--------------------------------------------------------------------

if exists (
     			select 1
				from wtb_Wizard_MassSetup tbl1
				inner join tb_DateTimeBandDetail tbl2 on convert(int , Attribute1) = tbl2.DateTimeBandID
				                    and convert(int , Attribute8) = tbl2.DateTimeBandDetailID
				where SessionID = @SessionID
				and WizardName = 'Date And Time Dimension Action' 
				and WizardStep = 4 -- Delete
				and tbl2.DateTimeBandDetailID is NULL
          )
Begin

		set @ErrorDescription = 'ERROR !!! Date Time Band Detail provided for deletion does not belong to the Dimension Template'
		set @ResultFlag = 1
		Return 1


End

--------------------------------------------------------------------------
-- Check the To and From Field Values in case of insertion or update
-- to ensure they are valid
--------------------------------------------------------------------------

if exists (
				select 1 
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Date And Time Dimension Action' 
				and WizardStep in (2,3)
				and 
				(
					dbo.FN_ValidateTimeBandFormat(Attribute6) = 1
					or
					dbo.FN_ValidateTimeBandFormat(Attribute7) = 1
				)
		  )
Begin

		set @ErrorDescription = 'ERROR !!! One or more band details provided for insertion or update are invalid. Time bands should be defined in (HH:MM:SS) format '
		set @ResultFlag = 1
		Return 1

End

---------------------------------------------------------------
-- Open Session to perfrom the neccessary actions, and commit
-- or Rollback in one block
---------------------------------------------------------------

Begin Transaction ActionPerform

-------------
-- DELETION
-------------
Begin Try

    Create table #TempBandDetailDelete (DateTimeBandDetailID int )

	insert into #TempBandDetailDelete
	select convert(int , Attribute8 )
	from wtb_Wizard_MassSetup
	where SessionID = @SessionID
	and WizardName = 'Date And Time Dimension Action' 
	and WizardStep= 4 -- Delete

	Delete tbl1
	from tb_DateTimeBandDetail tbl1
	inner join #TempBandDetailDelete tbl2 on tbl1.DateTimeBandDetailID = tbl2.DateTimeBandDetailID

	Drop table #TempBandDetailDelete

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! While deleting dimension band detail. '+ERROR_MESSAGE()
		set @ResultFlag = 1

		Drop table #TempBandDetailDelete

		Rollback Transaction ActionPerform

		Return 1

End Catch


-------------
-- UPDATE
-------------
Begin Try

    Create table #TempBandDetailUpdate 
	(
		DateTimeBandDetailID int,
		DateTimeBandID int,
		EventYear int,
		EventMonth int,
		EventDay int,
		EventWeekDay int,
		FromField int,
		ToField int,
		UserID int
	)

	insert into #TempBandDetailUpdate
	(
		DateTimeBandDetailID,
		DateTimeBandID,
		EventYear ,
		EventMonth,
		EventDay,
		EventWeekDay,
		FromField,
		ToField,
		UserID
	)
	select convert(int , Attribute8 ),
	convert(int , Attribute1 ),
	convert(int , Attribute2 ),
	convert(int , Attribute3 ),
	convert(int , Attribute4 ),
	convert(int , Attribute5 ),
	convert(int ,substring(Attribute6 , 1,2) * 3600 ) + convert(int ,substring(Attribute6 , 4,2) * 60 )  + convert(int ,substring(Attribute6 , 7,2)),
	convert(int ,substring(Attribute7 , 1,2) * 3600 ) + convert(int ,substring(Attribute7 , 4,2) * 60 )  + convert(int ,substring(Attribute7 , 7,2)),
	UserID
	from wtb_Wizard_MassSetup
	where SessionID = @SessionID
	and WizardName = 'Date And Time Dimension Action' 
	and WizardStep= 3 -- Update

	update tbl1
	set tbl1.DateTimeBandID = tbl2.DateTimeBandID,
	    tbl1.EventYear = tbl2.EventYear,
	    tbl1.EventMonth = tbl2.EventMonth,
		tbl1.EventDay = tbl2.EventDay,
		tbl1.EventWeekDay = tbl2.EventWeekDay,
		tbl1.ToField = tbl2.ToField,
		tbl1.FromField = tbl2.FromField,
		tbl1.ModifiedDate = getdate(),
		tbl1.ModifiedByID = tbl2.UserID
	from tb_DateTimeBandDetail tbl1
	inner join #TempBandDetailUpdate tbl2 on tbl1.DateTimeBandDetailID = tbl2.DateTimeBandDetailID

	Drop table #TempBandDetailUpdate

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! While updating dimension band detail(s). '+ERROR_MESSAGE()
		set @ResultFlag = 1

		Drop table #TempBandDetailUpdate

		Rollback Transaction ActionPerform

		Return 1

End Catch


-------------
-- INSERT
-------------
Begin Try

	insert into tb_DateTimeBandDetail
	(
		DateTimeBandID,
		EventYear ,
		EventMonth,
		EventDay,
		EventWeekDay,
		FromField,
		ToField,
		ModifiedDate,
		ModifiedByID,
		flag
	)
	select convert(int , Attribute1 ),
	convert(int , Attribute2 ),
	convert(int , Attribute3 ),
	convert(int , Attribute4 ),
	convert(int , Attribute5 ),
	convert(int ,substring(Attribute6 , 1,2) * 3600 ) + convert(int ,substring(Attribute6 , 4,2) * 60 )  + convert(int ,substring(Attribute6 , 7,2)),
	convert(int ,substring(Attribute7 , 1,2) * 3600 ) + convert(int ,substring(Attribute7 , 4,2) * 60 )  + convert(int ,substring(Attribute7 , 7,2)),
	getdate(),
	UserID,
	0
	from wtb_Wizard_MassSetup
	where SessionID = @SessionID
	and WizardName = 'Date And Time Dimension Action' 
	and WizardStep= 2 -- Insert

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! While inserting new dimension band detail(s). '+ERROR_MESSAGE()
		set @ResultFlag = 1

		Rollback Transaction ActionPerform

		Return 1

End Catch

Commit Transaction ActionPerform

Return 0
GO
