USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingDimensionValidateOthers]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingDimensionValidateOthers]
(
	@SessionID varchar(36),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------------
-- Validate to ensure that session ID is not NULL and exists in the master
-- wizard table
----------------------------------------------------------------------------

if ( 
		( @SessionID is NULL )
		or
		not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Rate Dimension Validate' and WizardStep = 1)
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
		and WizardName = 'Rate Dimension Validate'
		and WizardStep = 1
	 ) > 1
   )
Begin

		set @ErrorDescription = 'ERROR !!! Multiple Rate Dimension Template provided to wizard for validation under one session'
		set @ResultFlag = 1
		Return 1


End

Declare @RateDimensionTemplateID int

select @RateDimensionTemplateID = convert(int , VariableValue )
from wtb_Wizard_MassSetup
where SessionID = @SessionID
and WizardName = 'Rate Dimension Validate'
and WizardStep = 1

--select @RateDimensionTemplateID as RateDimensionTemplateID

------------------------------------------------------------------------------
-- Validate to ensure that all the distinct DatetimeBandIDs exist in the
-- system under the mentioned Rate Dimension Template
------------------------------------------------------------------------------

if exists (
				select 1
				from wtb_Wizard_MassSetup
				where SessionID = @SessionID
				and WizardName = 'Rate Dimension Validate' 
				and WizardStep = 1
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

-------------------------------------------------------------
-- Extract the Dimension Band Details and store them in a 
-- temporary table for performing all validations
-------------------------------------------------------------

Create Table #TempDimensionBandDetails
(
	RateDimensionBandID int,
	FromField varchar(30),
	ToField varchar(30),
	ApplyFrom int
)

insert into #TempDimensionBandDetails
(
	RateDimensionBandID ,
	FromField,
	ToField ,
	ApplyFrom
)
select
 Attribute1,
 Attribute2,
 Attribute3,
 Attribute4
from wtb_Wizard_MassSetup
where SessionID = @SessionID
and WizardName = 'Rate Dimension Validate' 
and WizardStep = 1

--select *
--from #TempDimensionBandDetails

------------------------------------------------------
-- Make sure that FROM Fields are not NULL values
------------------------------------------------------

if exists ( Select 1 from #TempDimensionBandDetails where FromField is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! From Field for Band details cannot be NULL '
		set @ResultFlag = 1
		Drop table #TempDimensionBandDetails
		Return 1

End


--------------------------------------------------------------
-- Make sure that FROM and TO Fields are of the Numeric Type
--------------------------------------------------------------

if exists ( Select 1 from #TempDimensionBandDetails where isnumeric(rtrim(ltrim(FromField))) = 0 or isnumeric(rtrim(ltrim(isnull(ToField, 0)))) = 0 )
Begin

		set @ErrorDescription = 'ERROR !!! From and To Fields for Band details have to be numeric values '
		set @ResultFlag = 1
		Drop table #TempDimensionBandDetails
		Return 1

End

-----------------------------------------------------------------------
-- Make sure that FROM and TO Fields are values greater than equal to 0
-----------------------------------------------------------------------

if exists ( Select 1 from #TempDimensionBandDetails where convert(int ,FromField) < 0 or isnull(convert(int ,ToField ), 0) < 0 )
Begin

		set @ErrorDescription = 'ERROR !!! From and To Fields for Band details should be greater than or equal to 0 '
		set @ResultFlag = 1
		Drop table #TempDimensionBandDetails
		Return 1

End

--------------------------------------------------------
-- Make sure that FROM  Field is less than TO Field 
---------------------------------------------------------

if exists ( Select 1 from #TempDimensionBandDetails where convert(int ,FromField) >= isnull(convert(int ,ToField),convert(int, FromField + 1)) )
Begin

		set @ErrorDescription = 'ERROR !!! From  Field cannot be greater or equal to the TO Field for Band details '
		set @ResultFlag = 1
		Drop table #TempDimensionBandDetails
		Return 1

End

----------------------------------------------------------------
-- Make sure that APPLYFROM field is Greater than or equal to 0 
----------------------------------------------------------------

if exists ( Select 1 from #TempDimensionBandDetails where isnull(ApplyFrom, 0) < 0 )
Begin

		set @ErrorDescription = 'ERROR !!! Apply From field for Band details shoud be NULL or a numerical positive value '
		set @ResultFlag = 1
		Drop table #TempDimensionBandDetails
		Return 1

End

Create Table #TempDimensionBandDetailsProcessing
(
	RecordID int identity(1,1),
	FromField int,
	ToField int,
	ApplyFrom int
)

Insert into #TempDimensionBandDetailsProcessing
select 	convert(int,FromField) , convert(int ,ToField) , ApplyFrom	 
from #TempDimensionBandDetails
order by convert(int ,FromField)


if ( (select count(*) from #TempDimensionBandDetailsProcessing )  > 1 ) -- Multiple Band Details 
Begin

		Declare @MaxRecordID int,
		        @MinRecordID int

		select @MaxRecordID = max(RecordID),
		       @MinRecordID = min(RecordID)
		from #TempDimensionBandDetailsProcessing

		if exists (
						select 1 
						from #TempDimensionBandDetailsProcessing tbl1
						inner join  #TempDimensionBandDetailsProcessing tbl2 on tbl1.RecordID + 1 = tbl2.RecordID
									and isnull(tbl1.ToField , 0) <> convert(int ,tbl2.FromField)
						where tbl1.RecordID <> @MaxRecordID
		          )
		Begin

				set @ErrorDescription = 'ERROR !!! Missing or overlapping band details' 
				set @ResultFlag = 1
				
				drop table #TempDimensionBandDetailsProcessing
				drop table #TempDimensionBandDetails

				Return 1

		End
			       

End


----------------------------------------------------------------
-- Post completion delete the temporary tables created
----------------------------------------------------------------

Drop table #TempDimensionBandDetailsProcessing
Drop table #TempDimensionBandDetails

Return 0
GO
