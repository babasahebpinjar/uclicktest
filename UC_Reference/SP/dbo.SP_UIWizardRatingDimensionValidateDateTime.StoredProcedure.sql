USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingDimensionValidateDateTime]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingDimensionValidateDateTime]
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
		not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Date And Time Dimension Validate' and WizardStep = 1)
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
and WizardName = 'Date And Time Dimension Validate' 
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
				and WizardName = 'Date And Time Dimension Validate' 
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
-- Extract the Date Dimensions and store them in a temporary
-- table for performing all validations
-------------------------------------------------------------

Create Table #TempDateTimeBandDetails
(
	DateTimeBandID int,
	EventYear int,
	EventMonth int ,
	EventDay int,
	EventWeekDay int,
	FromField varchar(8),
	ToField varchar(8),
	FromFieldValidity int,
	ToFieldValidity int
)

insert into #TempDateTimeBandDetails
(
	DateTimeBandID ,
	EventYear ,
	EventMonth  ,
	EventDay ,
	EventWeekDay ,
	FromField,
	ToField ,
	FromFieldValidity,
	ToFieldValidity
)
select
 Attribute1,
 Attribute2,
 Attribute3,
 Attribute4,
 Attribute5,
 Attribute6,
 Attribute7,
 dbo.FN_ValidateTimeBandFormat(Attribute6),
 dbo.FN_ValidateTimeBandFormat(Attribute7)
from wtb_Wizard_MassSetup
where SessionID = @SessionID
and WizardName = 'Date And Time Dimension Validate' 
and WizardStep = 1

--select *
--from #TempDateTimeBandDetails

--------------------------------------------------------------
-- Check to ensure that TO and FROM fields are valid values
--------------------------------------------------------------

if exists ( select 1 from #TempDateTimeBandDetails where FromFieldValidity = 1 or ToFieldValidity = 1 )
Begin

		set @ErrorDescription = 'ERROR !!! One or more Rate Dimension Bands have invalid Band details. Time bands should be defined in (HH:MM:SS) format '
		set @ResultFlag = 1
		Drop table #TempDateTimeBandDetails
		Return 1

End


-------------------------------------------------------------
-- Check to ensure that multipe records do not exist for the 
-- same combination of Band , Year , Month , Day , Day Of Week 
-- and Band Details
--------------------------------------------------------------

if exists (
			select count(*) as TotalRecords ,
			DateTimeBandID,
		    EventYear ,
			EventMonth  ,
			EventDay ,
			EventWeekDay ,
			FromField,
			ToField
			from #TempDateTimeBandDetails
			group by DateTimeBandID,
			EventYear ,
			EventMonth  ,
			EventDay ,
			EventWeekDay ,
			FromField,
			ToField
			having count(1) > 1
          )
Begin

		set @ErrorDescription = 'ERROR !!! More than one record exist for the combination of Band , Year , Month , Day , Day Of Week and Band Details '
		set @ResultFlag = 1
		Drop table #TempDateTimeBandDetails
		Return 1

End

------------------------------------------------
-- Open a Cursor to run Validation on the data
------------------------------------------------

Declare @VarEventYear int,
        @VarEventMonth int,
		@VarEventDay int,
		@VarEventWeekDay int,
		@VarDateTimeBand varchar(1000)

Create Table #TempDateTimeBandDetailsProcessing
(
    RecordID int identity(1,1),
	EventYear int,
	EventMonth int ,
	EventDay int,
	EventWeekDay int,
	FromField int,
	ToField int
)
		
Declare DateTime_Validate_Cur Cursor For
select distinct isnull(EventYear,0) ,	EventMonth ,EventDay ,EventWeekDay
from #TempDateTimeBandDetails

Open DateTime_Validate_Cur
Fetch Next from DateTime_Validate_Cur
Into @VarEventYear ,@VarEventMonth ,@VarEventDay ,@VarEventWeekDay

While @@FETCH_STATUS = 0
Begin
       
	    Delete from #TempDateTimeBandDetailsProcessing

        Insert into #TempDateTimeBandDetailsProcessing
		select 	EventYear ,	EventMonth ,EventDay , EventWeekDay ,
				convert(int ,substring(FromField , 1,2) * 3600 ) + convert(int ,substring(FromField , 4,2) * 60 )  + convert(int ,substring(FromField , 7,2)), 
				convert(int ,substring(ToField , 1,2) * 3600 ) + convert(int ,substring(ToField , 4,2) * 60 )  + convert(int ,substring(ToField , 7,2))	 
        from #TempDateTimeBandDetails
		where EventYear = @VarEventYear
		and EventMonth = @VarEventMonth
		and EventDay = @VarEventDay
		and EventWeekDay = @VarEventWeekDay
		order by convert(int ,substring(FromField , 1,2) * 3600 ) + convert(int ,substring(FromField , 4,2) * 60 )  + convert(int ,substring(FromField , 7,2))


		select @VarDateTimeBand =
       'Year : ' +  case when @VarEventYear = 0 then'All' else convert(varchar(10),@VarEventYear) End + ' /  '+
	   'Month : ' + 
	              Case
						When @VarEventMonth = 0 then 'All'
						When @VarEventMonth = 1 then 'Jan'
						When @VarEventMonth = 2 then 'Feb'
						When @VarEventMonth = 3 then 'Mar'
						When @VarEventMonth = 4 then 'Apr'
						When @VarEventMonth = 5 then 'May'
						When @VarEventMonth = 6 then 'Jun'
						When @VarEventMonth = 7 then 'Jul'
						When @VarEventMonth = 8 then 'Aug'
						When @VarEventMonth = 9 then 'Sep'
						When @VarEventMonth = 10 then 'Oct'
						When @VarEventMonth = 11 then 'Nov'
						When @VarEventMonth = 12 then 'Dec'
				  End + ' /  '+
		'Day : ' + Case When @VarEventDay = 0 Then 'All' Else convert(varchar(10) ,@VarEventDay) End + ' / '+
		'Week Day : ' +
	              Case
						When @VarEventWeekDay = 0 then 'All'
						When @VarEventWeekDay = 1 then 'Sun'
						When @VarEventWeekDay = 2 then 'Mon'
						When @VarEventWeekDay = 3 then 'Tue'
						When @VarEventWeekDay = 4 then 'Wed'
						When @VarEventWeekDay = 5 then 'Thu'
						When @VarEventWeekDay = 6 then 'Fri'
						When @VarEventWeekDay = 7 then 'Sat'
				  End 

		--select * from #TempDateTimeBandDetailsProcessing

		--select @VarDateTimeBand as DateTimeBand

		if exists ( select 1 from #TempDateTimeBandDetailsProcessing where FromField < 0 )
		Begin

				set @ErrorDescription = 'ERROR !!! Time details for any band has to be between 00:00:00 and 23:59:59. Exception found in Time Band : ' + @VarDateTimeBand 
				set @ResultFlag = 1
				
				drop table #TempDateTimeBandDetailsProcessing
				drop table #TempDateTimeBandDetails

				Close DateTime_Validate_Cur
				DeAllocate DateTime_Validate_Cur

				Return 1

		End

		if exists ( select 1 from #TempDateTimeBandDetailsProcessing where ToField > 86399 )
		Begin

				set @ErrorDescription = 'ERROR !!! Time details for any band has to be between 00:00:00 and 23:59:59. Exception found in Time Band : ' + @VarDateTimeBand 
				set @ResultFlag = 1
				
				drop table #TempDateTimeBandDetailsProcessing
				drop table #TempDateTimeBandDetails

				Close DateTime_Validate_Cur
				DeAllocate DateTime_Validate_Cur

				Return 1

		End

		if not exists ( select 1 from  #TempDateTimeBandDetailsProcessing where FromField = 0 )
		Begin

				set @ErrorDescription = 'ERROR !!! No Time band details exist for start of day hours 00:00:00. Exception found in Time Band : ' + @VarDateTimeBand 
				set @ResultFlag = 1
				
				drop table #TempDateTimeBandDetailsProcessing
				drop table #TempDateTimeBandDetails

				Close DateTime_Validate_Cur
				DeAllocate DateTime_Validate_Cur

				Return 1

		End

		if not exists ( select 1 from  #TempDateTimeBandDetailsProcessing where ToField = 86399 )
		Begin

				set @ErrorDescription = 'ERROR !!! No time band detail exists for end of day hours 23:59:59. Exception found in Time Band : ' + @VarDateTimeBand 
				set @ResultFlag = 1
				
				drop table #TempDateTimeBandDetailsProcessing
				drop table #TempDateTimeBandDetails

				Close DateTime_Validate_Cur
				DeAllocate DateTime_Validate_Cur

				Return 1

		End

		if ( (select count(*) from #TempDateTimeBandDetailsProcessing )  > 1 ) -- Multiple Time Band Details for Time Band
		Begin

				if exists (
							 select 1 from #TempDateTimeBandDetailsProcessing where RecordID = 
							 ( Select min(RecordID) from #TempDateTimeBandDetailsProcessing )
							 and FromField <> 0
						  )
				Begin

						set @ErrorDescription = 'ERROR !!! There should be a time band detail starting at 00:00:00 hours. Exception found in Time Band : ' + @VarDateTimeBand 
						set @ResultFlag = 1
				
						drop table #TempDateTimeBandDetailsProcessing
						drop table #TempDateTimeBandDetails

						Close DateTime_Validate_Cur
						DeAllocate DateTime_Validate_Cur

						Return 1

				End

				if exists (
							 select 1 from #TempDateTimeBandDetailsProcessing where RecordID = 
							 ( Select max(RecordID) from #TempDateTimeBandDetailsProcessing )
							 and ToField <> 86399
						  )
				Begin

						set @ErrorDescription = 'ERROR !!! There should be a time band detail ending at 23:59:59 hours. Exception found in Time Band : ' + @VarDateTimeBand 
						set @ResultFlag = 1
				
						drop table #TempDateTimeBandDetailsProcessing
						drop table #TempDateTimeBandDetails

						Close DateTime_Validate_Cur
						DeAllocate DateTime_Validate_Cur

						Return 1

				End

				if exists (
							 select 1 
							 from #TempDateTimeBandDetailsProcessing tbl1
							 inner join  #TempDateTimeBandDetailsProcessing tbl2 on tbl1.RecordID + 1 = tbl2.RecordID
											and tbl1.ToField +1 <> tbl2.FromField
							 where tbl1.ToField <> 86399
						  )
				Begin

						set @ErrorDescription = 'ERROR !!! Missing or overlapping time band details. Exception found in Time Band : ' + @VarDateTimeBand 
						set @ResultFlag = 1
				
						drop table #TempDateTimeBandDetailsProcessing
						drop table #TempDateTimeBandDetails

						Close DateTime_Validate_Cur
						DeAllocate DateTime_Validate_Cur

						Return 1

				End


		End

		Fetch Next from DateTime_Validate_Cur
		Into @VarEventYear ,@VarEventMonth ,@VarEventDay ,@VarEventWeekDay

End

Close DateTime_Validate_Cur
DeAllocate DateTime_Validate_Cur

----------------------------------------------------------------
-- Post completion delete the temporary tables created
----------------------------------------------------------------

Drop table #TempDateTimeBandDetailsProcessing
Drop table #TempDateTimeBandDetails

Return 0
GO
