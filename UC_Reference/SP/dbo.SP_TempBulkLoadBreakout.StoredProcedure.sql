USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_TempBulkLoadBreakout]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_TempBulkLoadBreakout]
(
	@SourceFilePath varchar(200) = NULL,
	@VendorSource varchar(100),
	@TKG int
)
As

--Declare @SourceFilePath varchar(200) = 'C:\Temp_Folder\Load Rates\1Global_Rates.csv'

Declare @FileExists int,
        @ErrorMsgStr varchar(2000),
		@SQLStr varchar(2000)


----------------------------------------------------------------
-- Create temporary table to store the data for the source file
----------------------------------------------------------------

Create table #TempVendorOfferData
(
	Direction int,
	Destination varchar(60),
	DialedDigit varchar(15),
	Rate varchar(25),
	TKG int,
	BeginDate varchar(20),
	EndDate varchar(20),
	RatingMethod varchar(100),
	RateType varchar(100),
	DestinationType varchar(30)
)


if ( @SourceFilePath is NOT NULL )
Begin

			---------------------------------------------------------
			-- Check if the Source File Exists in the system or not
			---------------------------------------------------------

			set @FileExists = 0

			Exec master..xp_fileexist @SourceFilePath , @FileExists output  

			if ( @FileExists <> 1 )
			Begin

				   set @ErrorMsgStr = 'Error!!! Source File Name cannot be located as per value : (' + @SourceFilePath + ')'
				   Raiserror('%s' , 16 , 1, @ErrorMsgStr)
				   return 

			End 

			-------------------------------------------------------------------
			-- Load bulk data into the temporary table for the source file
			-------------------------------------------------------------------

			Declare @FieldTerminator varchar(10) = ',' ,
					@RowTerminator  varchar(10) = '\n'

			Begin Try

				Select	@SQLStr = 'Bulk Insert  #TempVendorOfferData '+ ' From ' 
							  + '''' + @SourceFilePath +'''' + ' WITH (
							  MAXERRORS = 0, FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
						  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

				print @SQLStr
				Exec(@SQLStr)


			End Try

			Begin Catch

				set @ErrorMsgStr = 'ERROR!!! Data could not be bulk uploaded from the Source File.' + ERROR_MESSAGE()
				Raiserror('%s' , 16 , 1, @ErrorMsgStr)
				drop table #TempVendorOfferData
				return

			End Catch

End

Else
Begin

		insert into #TempVendorOfferData
		(	
			Direction,
			Destination ,
			DialedDigit ,
			Rate ,
			TKG ,
			BeginDate ,
			EndDate ,
			RatingMethod ,
			RateType ,
			DestinationType
		)
		Select Direction , Destination , DialedDigit , Rate , TKG,
			   BeginDate , 
			   Case
				   When EndDate  = 'NULL' then NULL
				   Else EndDate
				End ,
			   'Default: Flat Time Based Rating', 'Flat',
			   'Mobile'
		from Tb_AllRateDumpData
		where tkg = @TKG


End

----------------------------------------------------
-- Update the BeginDate and EndDate columns with
-- yyyy-mm-dd date format
----------------------------------------------------

update #TempVendorOfferData
set BeginDate = 
		Case
		   When BeginDate is not NULL then substring(BeginDate , 7,4) + '-' + substring(BeginDate , 4,2) + '-' + substring(BeginDate , 1,2)
		   Else BeginDate
		End,
	EndDate = 
		Case
		   When EndDate <> 'NULL' then substring(EndDate , 7,4) + '-' + substring(EndDate , 4,2) + '-' + substring(EndDate , 1,2)
		   Else NULL
		End


------------------------------------------------------------
-- Update the Destination Type based on regular expressions
------------------------------------------------------------
-- KINDA HARD CODED FOR THE MOMENT UNTIL EXPLICITLY SUGGESTED
-------------------------------------------------------------

update #TempVendorOfferData
set DestinationType = 
        Case
				when charindex('Mobile' , Destination) <> 0 then 'Mobile'
				Else 'Fixed'
		End


-----------------------------------------------------------------------------------
-- Check to see if there are records which have the rating method or Rate type NULL
-----------------------------------------------------------------------------------

if exists ( select 1 from #TempVendorOfferData where RatingMethod is NULL or RateType is NULL )
Begin

	set @ErrorMsgStr = 'ERROR!!! Rating Method or Rate Type is NULL for records in the vendor file'
	Raiserror('%s' , 16 , 1, @ErrorMsgStr)
	drop table #TempVendorOfferData
	return		

End

----------------------------------------------------------------
-- Check to ensure that the Rating Method Exists in the system
----------------------------------------------------------------

if exists (
			select distinct RatingMethod 
			from #TempVendorOfferData
			where RatingMethod not in
			(
				Select Distinct RatingMethod
				from tb_RatingMethod
				where Flag & 1 <> 1
			)
          )
Begin

	set @ErrorMsgStr = 'ERROR!!! Rating Method(s) defined in the file does not exist in the system'
	Raiserror('%s' , 16 , 1, @ErrorMsgStr)
	drop table #TempVendorOfferData
	return

End


------------------------------------------------------------------
-- Check to ensure that the Rating Method and Rate Type combination
-- exists in the database
-------------------------------------------------------------------

select RatingMethod + '|' + RateType
from #TempVendorOfferData
where RatingMethod + '|' + RateType not in
(
	select tbl2.RatingMethod + '|' + tbl3.RateDimensionBand
	from tb_RateNumberIdentifier tbl1
	inner join tb_RatingMethod tbl2 on tbl1.RatingMethodID = tbl2.RatingMethodID
	inner join tb_RateDimensionBand tbl3 on tbl1.RateDimension1BandID = tbl3.RateDimensionBandID
	where tbl2.RateStructureID = 1
)


--select *
--from #TempVendorOfferData

---------------------------------------------------
-- Extract the number plan and Rate Plan info from
-- the vendor source
---------------------------------------------------

Declare @NumberPlan varchar(60),
        @NumberPlanID int,
		@RatePlan varchar(100),
		@RatePlanID int

select @NumberPlan = Np.NumberPlan,
       @NumberPlanID = Np.NumberPlanID,
	   @RatePlan = Rp.RatePlan,
	   @RatePlanID = Rp.RatePlanID
from UC_Commerce.dbo.tb_Source Src
inner join tb_NumberPlan Np on Src.SourceID = Np.ExternalCode
inner join tb_RatePlan Rp on Src.RatePlanID = Rp.RatePlanID
where Src.Source = @VendorSource
and Src.SourceTypeId = -1 -- Vendor Source


select @NumberPlan as NumberPlan , @RatePlan as RatePlan

----------------------------------------------
-- Add the Country ID  and Errlr Message 
-- to the list of records
----------------------------------------------

Alter table #TempVendorOfferData Add CountryID int
Alter table #TempVendorOfferData Add ErrorMEssage varchar(2000)

-------------------------------------------------------
-- Populate the country IDs for respective destinations
-------------------------------------------------------

create table #TempAllCountryCode ( CountryId int,CountryCode varchar(20) )

Declare @VarCountryCode varchar(20),
        @VarCountryID int,
		@TempCountryCodeStr varchar(100)

Declare GetAllCountryCode_Cur Cursor For
select CountryID ,countrycode
from tb_country
where countryid > 0 and flag <> 1

Open GetAllCountryCode_Cur
Fetch Next From GetAllCountryCode_Cur
Into @VarCountryID , @VarCountryCode


While @@FETCH_STATUS = 0
Begin

    set @TempCountryCodeStr = @VarCountryCode

	while ( charindex(',' , @VarCountryCode ) <> 0 )
	Begin

            set @TempCountryCodeStr = substring(@VarCountryCode , 1 , charindex(',' , @VarCountryCode ) - 1 )
			insert into #TempAllCountryCode values ( @TempCountryCodeStr )
            set @VarCountryCode = substring(@VarCountryCode , charindex(',' , @VarCountryCode ) + 1 , Len(@VarCountryCode) )
	End

	insert into #TempAllCountryCode values ( @VarCountryID , @VarCountryCode )
 
	Fetch Next From GetAllCountryCode_Cur
	Into @VarCountryID ,@VarCountryCode

End

Close GetAllCountryCode_Cur
Deallocate GetAllCountryCode_Cur

--select * from #TempAllCountryCode

Declare Update_CountryCode_Cur Cursor For
select CountryID ,countrycode
from #TempAllCountryCode
order by len(countrycode) desc

Open Update_CountryCode_Cur
Fetch Next From Update_CountryCode_Cur
Into @VarCountryID ,@VarCountryCode


While @@FETCH_STATUS = 0
Begin

	update #TempVendorOfferData
        set CountryID = @VarCountryID
	where CountryID is NULL
	and substring(DialedDigit , 1 , len(@VarCountryCode) ) = @VarCountryCode
 
	Fetch Next From Update_CountryCode_Cur
	Into @VarCountryID ,@VarCountryCode

End

Close Update_CountryCode_Cur
Deallocate Update_CountryCode_Cur

drop table #TempAllCountryCode

------------------------------------------------------------
-- Validate data to ensure that all information is correct
------------------------------------------------------------

-----------------------------------------
-- CHECK 1 : DialCode is not numeric
-----------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'DialCode  : '  + tbl1.DialedDigit + ' is not a numeric value'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and
(
   ISNUMERIC(tbl1.DialedDigit) = 0
   or
   charindex('.' , convert(varchar(20) ,tbl1.DialedDigit) ) <> 0
)

-------------------------------------------------------
-- CHECK 2 : DialCode length greater than 15 characters
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'DialCode  : '  + tbl1.DialedDigit + ' length greater than 15 characters'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and ISNUMERIC(tbl1.DialedDigit) = 1
and LEN(tbl1.DialedDigit) > 15

---------------------------------------------------------
-- CHECK 3 : Destination name should be less than the
-- 60 characters
---------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : (' + tbl1.Destination + ') has length greater than 60 characters' 
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and len(tbl1.Destination) > 60

--------------------------------------------------------------------
-- CHECK 5 : Destination With no associated dial codes or rates
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has no associated Dial Codes or Rates'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is null
and
(
   isnumeric(isnull(tbl1.Rate , 'No Rates')) = 0 
   or
   charindex(',' , convert(varchar(25) ,tbl1.Rate) ) <> 0
 )


 --------------------------------------------------------------------
-- CHECK 6 : Destination With associated dial codes but no rates
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has  associated Dial Codes but no Rates'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and
(
   isnumeric(isnull(tbl1.Rate , 'No Rates')) = 0 
   or
   charindex(',' , convert(varchar(25) ,tbl1.Rate) ) <> 0
 )


 --------------------------------------------------------------------
-- CHECK 7 : Destination With associated rates but no dial codes
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has  associated Rates but no Dial Codes'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is null
and isnumeric(isnull(tbl1.Rate , 'No Rates')) = 1


--------------------------------------------------------
-- CHECK 8 : More than one entry for the combination of 
-- 1. Destination
-- 2. Effective Date
-- 3. Dialed Digit
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Multiple Entries exist for Destination : ' + tbl1.Destination + ' and  BeginDate : '+ CONVERT(varchar(10), tbl1.BeginDate, 120 ) +' and DialedDigit : ' + tbl1.DialedDigit
from  #TempVendorOfferData tbl1
inner join
(  
	Select COUNT(*) as TotalRecords, Destination , BeginDate , DialedDigit
	from #TempVendorOfferData
	where ErrorMessage is NULL
	group by Destination , BeginDate , DialedDigit
	Having COUNT(1) > 1
) tbl2
on tbl1.destination = tbl2.destination
and tbl1.BeginDate = tbl2.BeginDate
and tbl1.DialedDigit = tbl2.DialedDigit
where tbl1.ErrorMessage is NULL

--------------------------------------------------------
-- CHECK 9 : Duplicate Dial code for same effective date
-- across different destinations.
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Duplicate Dial Code : ' + tbl1.DialedDigit + ' for Effective Date :' + CONVERT(varchar(10) , tbl1.BeginDate , 120 )
from  #TempVendorOfferData tbl1
inner join
(  
	Select COUNT(*) as TotalRecords, BeginDate , DialedDigit
	from #TempVendorOfferData
	where ErrorMessage is NULL
	group by  BeginDate , DialedDigit
	Having COUNT(1) > 1
) tbl2
on tbl1.BeginDate = tbl2.BeginDate
and tbl1.DialedDigit = tbl2.DialedDigit
where tbl1.ErrorMessage is NULL

--------------------------------------------------------
-- CHECK 10 : Multiple rates for the same destination and 
-- Effective date.
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Multiple rates for Destination : ' + tbl1.Destination + ' and  Effective Date :' + CONVERT(varchar(10) , tbl1.BeginDate , 120 )
from  #TempVendorOfferData tbl1
inner join
(
	select count(*) as TotalRecords , Destination , BeginDate
	from
	(
		select distinct Destination , BeginDate , Rate
		from #TempVendorOfferData
		where ErrorMessage is NULL
	) as tbl
	Group by Destination , BeginDate
	having count(1) > 1
)tbl2
on tbl1.BeginDate = tbl2.BeginDate
and tbl1.Destination = tbl2.Destination
where tbl1.ErrorMessage is NULL


-------------------------------------------------------
-- CHECK 11 : Check for record Items which have the 
-- country ID is NULL
------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Country Code cannot be resolved for Destination : '+ tbl1.Destination +' and DialedDigit : ' + tbl1.DialedDigit + ' and  Effective Date :' + CONVERT(varchar(10) , tbl1.BeginDate , 120 ) 
from #TempVendorOfferData tbl1
where tbl1.ErrorMessage is NULL
and tbl1.CountryID IS NULL

---------------------------------------------------------------------------
---- Check to see if there are destinations which have multiple countries
---- assigned
---------------------------------------------------------------------------

------------------------------------------------
-- CHECK 12 : Multiple Country Codes for the
-- Same Destination.
--------------------------------------------------------------------
-- Multiple Code Scenarios would be:
-- 1. Two Different country codes belonging to no group
-- 2. Two Different country codes belonging to two different groups
-- 3. Two different country codes one belonging to group, other to no group
---------------------------------------------------------------------

------------------------
-- Handle Condition 1
------------------------

update tbl1
set tbl1.ErrorMessage ='Multiple CountryID : ' + convert(varchar(20) ,tbl1.CountryID) + ' for Destination :' + tbl1.Destination
from  #TempVendorOfferData tbl1
inner join
(
	select destination , groupid , COUNT(*) as TotalCountryID
	from
	(
		select distinct tbl1.destination , tbl1.CountryID , ISNULL(tbl2.GroupID , 99999) as GroupId
		from #TempVendorOfferData tbl1
		left join 
		(
			select tbl1.EntityGroupID as GroupID , tbl1.InstanceID as CountryID
			from tb_EntityGroupMember tbl1
			inner join tb_EntityGroup tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
			where EntityGroupTypeID = -4 
        ) tbl2 on tbl1.CountryID = tbl2.CountryID
		where tbl1.errormessage is null
	) as tbl
	group by destination , groupid
	having COUNT(3) > 1
) as tbl2
on tbl1.destination = tbl2.destination
where tbl1.ErrorMessage is NULL
and tbl2.groupid = 99999

-----------------------------
-- Handle Condition 2 and 3
-----------------------------

update tbl1
set tbl1.ErrorMessage ='Multiple Country Code : ' + convert(varchar(20) ,tbl1.CountryID) + ' for Destination :' + tbl1.Destination
from  #TempVendorOfferData tbl1
inner join
(
	select destination , count(*) as TotalGroup
	from
	(
		select distinct tbl1.destination  , ISNULL(tbl2.GroupID , 99999) as GroupId
		from #TempVendorOfferData tbl1
		left join 
		(
			select tbl1.EntityGroupID as GroupID , tbl1.InstanceID as CountryID
			from tb_EntityGroupMember tbl1
			inner join tb_EntityGroup tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
			where EntityGroupTypeID = -4 
        ) tbl2 on tbl1.CountryID = tbl2.CountryID
		where tbl1.errormessage is null
	) as tbl
	group by destination
	having COUNT(2) > 1
) as tbl2
on tbl1.destination = tbl2.destination
where tbl1.ErrorMessage is NULL


if exists ( select 1 from #TempVendorOfferData where ErrorMessage is NOT NULL )
Begin

		select Distinct ErrorMessage
		from #TempVendorOfferData
		where ErrorMessage is NOT NULL

		Drop table #TempVendorOfferData

		Return 1

End

--------------------------------------------------
-- Delete old historical data from previous upload
--------------------------------------------------

delete tbl1
from tb_RateDetail tbl1
inner join tb_Rate tbl2 on tbl1.rateID = tbl2.RateID
where tbl2.RatePlanID = @RatePlanID

delete from tb_Rate 
where RatePlanID = @RatePlanID

delete tbl1
from tb_DialedDigits tbl1
inner join tb_Destination tbl2 on tbl1.DestinationID = tbl2.DestinationID
where tbl2.NumberPlanID = @NumberPlanID

Delete from tb_Destination
where numberplanid = @NumberPlanID

---------------------------------------------------
-- Insert data into the tb_Destination table
---------------------------------------------------

---------------------------------------------------
-- Select the unique list of destinations to be
-- inserted into the numberplan
---------------------------------------------------


select distinct Destination , substring(Destination , 1,20) as DestinationAbbrv,
       tbl2.DestinationTypeID , NULL as InternalCode , NULL as ExternalCode,
	   min(Begindate) as BeginDate , NULL , @NumberPlanID as NumberPlanID , min(CountryID) as CountryID, 
	   GetDate() as ModifiedDate , -1 as ModifiedByID , 0 as Flag 
from #TempVendorOfferData tbl1
inner join tb_DestinationType tbl2 on tbl1.DestinationType = tbl2.DestinationType
Group by Destination, substring(Destination , 1,20) , tbl2.DestinationTypeID

insert into tb_Destination
(
	Destination,
	DestinationAbbrv,
	DestinationTypeID,
	InternalCode,
	ExternalCode,
	BeginDate,
	EndDate,
	NumberPlanID,
	CountryID,
	ModifiedDate,
	ModifiedByID,
	Flag
)
select distinct Destination , substring(Destination , 1,20),
		tbl2.DestinationTypeID , NULL, NULL,
		min(Begindate) , NULL , @NumberPlanID  , min(CountryID) , 
		GetDate() , -1  , 0  
from #TempVendorOfferData tbl1
inner join tb_DestinationType tbl2 on tbl1.DestinationType = tbl2.DestinationType
Group by Destination , substring(Destination , 1,20), tbl2.DestinationTypeID

update tb_Destination
set DestinationAbbrv = convert(varchar(20) , DestinationID)
where numberplanid = @NumberPlanID


------------------------------------------
-- Insert data into tb_DialedDigits table
------------------------------------------

select distinct tbl1.DialedDigit as DialedDigits ,tbl2.DestinationID , tbl1.BeginDate , tbl1.EndDate
into #TempDialedDigits
from #TempVendorOfferData tbl1
inner join tb_Destination tbl2 on tbl1.Destination = tbl2.Destination
where tbl2.NumberPlanID = @NumberPlanID

Create index idx_Temp_DialedDigits on #TempDialedDigits ( DialedDigits )

-------------------------------------------------------------------------------
-- Populate the end dates for the dialeddigits, so that there are not multiple
-- active instances of the dialed digits
-------------------------------------------------------------------------------

Alter table #TempDialedDigits Add DialedDigitsID int identity(1,1)

Declare @VarDialedDigitsID int,
        @VarDDDestinationID int,
		@VarDialedDigits varchar(20),
		@VarDDBeginDate varchar(20), 
		@VarDDEndate varchar(20),
		@MinDDBeginDate date


Declare Populate_DDEndDate_Cur Cursor For
Select DialedDigitsID , DestinationID , DialedDigits , BeginDate , EndDate
from #TempDialedDigits

Open Populate_DDEndDate_Cur
Fetch Next From Populate_DDEndDate_Cur
Into @VarDialedDigitsID , @VarDDDestinationID , @VarDialedDigits, @VarDDBeginDate , @VarDDEndate

While @@FETCH_STATUS = 0
Begin
       
	    select @MinDDBeginDate = DateAdd(dd , -1 , Min(convert(date , BeginDate)))
		from #TempDialedDigits
		where DialedDigits = @VarDialedDigits
		and DialedDigitsID <> @VarDialedDigitsID
		and convert(Date ,BeginDate) > convert(Date , @VarDDBeginDate)

		if ( ( @MinDDBeginDate is not NULL ) and (@VarDDEndate is NULL ) )
		Begin

				update #TempDialedDigits
				set EndDate = @MinDDBeginDate
				where DialedDigitsID = @VarDialedDigitsID

		End
	    
		Fetch Next From Populate_DDEndDate_Cur
		Into @VarDialedDigitsID , @VarDDDestinationID , @VarDialedDigits, @VarDDBeginDate , @VarDDEndate

End

Close Populate_DDEndDate_Cur
Deallocate Populate_DDEndDate_Cur

select tbl1.DialedDigits , 1 , @NumberPlanID ,
       tbl1.DestinationID , tbl1.BeginDate , tbl1.EndDate,
       Getdate() ,-1  , 0 
from #TempDialedDigits tbl1


insert into tb_DialedDigits
(
	DialedDigits,
	IntIndicator,
	NumberPlanID,
	DestinationID,
	BeginDate,
	EndDate,
	ModifiedDate,
	ModifiedByID,
	Flag
)
select tbl1.DialedDigits , 1 , @NumberPlanID ,
       tbl1.DestinationID , tbl1.BeginDate , tbl1.EndDate,
       Getdate() ,-1  , 0 
from #TempDialedDigits tbl1

-------------------------------------------------------
--  Insert data into tb_Rate and tb_RateDetail Tables
-------------------------------------------------------

select Distinct @RatePlanID as RatePlanID,
       tbl3.DestinationID,
       1 as CallTypeID, -- Hard Coded set the Call Type as IDD
       tbl2.RatingMethodID as RatingMethodID,
	   convert(date ,tbl1.BeginDate) as BeginDate
into #TempRate
from #TempVendorOfferData tbl1
inner join tb_RatingMethod tbl2 on tbl1.RatingMethod = tbl2.RatingMethod
inner join tb_Destination tbl3 on tbl1.Destination = tbl3.Destination
where tbl3.numberplanid = @NumberPlanID

Alter table #TempRate Add EndDate date
Alter table #TempRate Add RateID int identity(1,1)

-------------------------------------------------------------------
-- Open a cursor to populate the end date against the rates for
-- all the destinations and call type
-------------------------------------------------------------------
Declare @VarRateID int,
        @VarDestinationID int,
		@VarCallTypeID int,
		@VarBeginDate varchar(20), 
		@MinBeginDate date


Declare Populate_EndDate_Cur Cursor For
Select RateID , DestinationID , CallTypeID , BeginDate
from #TempRate

Open Populate_EndDate_Cur
Fetch Next From Populate_EndDate_Cur
Into @VarRateID , @VarDestinationID , @VarCallTypeID, @VarBeginDate

While @@FETCH_STATUS = 0
Begin
       
	    select @MinBeginDate = DateAdd(dd , -1 , Min(convert(date , BeginDate)))
		from #TempRate
		where DestinationID = @VarDestinationID
		and CallTypeID = @VarCallTypeID
		and RateID <> @VarRateID
		and convert(Date ,BeginDate) > convert(Date , @VarBeginDate)

		if ( @MinBeginDate is not NULL ) 
		Begin

				update #TempRate
				set EndDate = @MinBeginDate
				where RateID = @VarRateID

		End
	    
		Fetch Next From Populate_EndDate_Cur
		Into @VarRateID , @VarDestinationID , @VarCallTypeID, @VarBeginDate

End

Close Populate_EndDate_Cur
Deallocate Populate_EndDate_Cur

select *
from #TempRate

insert into tb_Rate
(
	RatePlanID,
	DestinationID,
	CallTypeID,
	RatingMethodID,
	BeginDate,
	EndDate,
	ModifiedDate,
	ModifiedByID,
	Flag
)
Select RatePlanID,
       DestinationID,
	   CallTypeID,
	   RatingMethodID,
	   BeginDate,
	   EndDate,
	   GetDate(),
	   -1,
	   0
From #tempRate


-------------------------------------------
-- Insert data into tb_RateDetail table
-------------------------------------------

Select tbl1.RateID , convert(decimal(19,6) , tbl4.Rate) as Rate,
       tbl5.RateItemID as RateTypeID , getdate() , -1 , 0
from tb_Rate tbl1
inner join tb_Destination tbl2 on tbl1.DestinationId = tbl2.DestinationID
inner join tb_RatingMethod tbl3 on tbl1.RatingMethodID = tbl3.RatingMethodID
inner join tb_RateNumberIdentifier tbl5 on tbl3.RatingMethodID = tbl5.RatingMethodID
inner join tb_RateDimensionBand tbl6 on tbl5.RateDimension1BandID = tbl6.RateDimensionBandID
inner join (select distinct Destination , RatingMethod , Ratetype , Rate , BeginDate from #TempVendorOfferData ) tbl4
                  on tbl2.Destination = tbl4.Destination
				  and tbl3.RatingMethod = tbl4.RatingMethod
				  and tbl6.RateDimensionBand = tbl4.Ratetype
				  and tbl1.BeginDate = tbl4.BeginDate
where tbl1.RatePlanID = @RatePlanID
and tbl2.NumberplanID = @NumberPlanID

Begin Try

		insert into tb_RateDetail
		( RateID , Rate , RateTypeID , ModifiedDate , ModifiedByID , Flag )
		Select tbl1.RateID , convert(decimal(19,6) , tbl4.Rate),
			   tbl5.RateItemID , getdate() , -1 , 0
		from tb_Rate tbl1
		inner join tb_Destination tbl2 on tbl1.DestinationId = tbl2.DestinationID
		inner join tb_RatingMethod tbl3 on tbl1.RatingMethodID = tbl3.RatingMethodID
		inner join tb_RateNumberIdentifier tbl5 on tbl3.RatingMethodID = tbl5.RatingMethodID
		inner join tb_RateDimensionBand tbl6 on tbl5.RateDimension1BandID = tbl6.RateDimensionBandID
		inner join (select distinct Destination , RatingMethod , Ratetype , Rate , BeginDate from #TempVendorOfferData ) tbl4
						  on tbl2.Destination = tbl4.Destination
						  and tbl3.RatingMethod = tbl4.RatingMethod
						  and tbl6.RateDimensionBand = tbl4.Ratetype
						  and tbl1.BeginDate = tbl4.BeginDate
		where tbl1.RatePlanID = @RatePlanID
		and tbl2.NumberplanID = @NumberPlanID

End Try

Begin Catch

	set @ErrorMsgStr = 'ERROR!!! While inserting data into TB_RateDetail . ' + ERROR_MESSAGE()
	Raiserror('%s' , 16 , 1, @ErrorMsgStr)
	GOTO ENDPROCESS


End Catch



ENDPROCESS:

----------------------------------------------------
-- Drop the Temp table after processing the data
----------------------------------------------------

Drop table #TempVendorOfferData
Drop table #TempRate
Drop table #TempDialedDigits
GO
