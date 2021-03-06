USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAnalyseUploadBreakouts]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSAnalyseUploadBreakouts]
(
	@OfferID int,
	@UserID int
)
As


Declare @SourceID int,
		@OfferDate DateTime,
		@OfferContent varchar(50),
		@NumberPlanID int,
		@RatePlanID int,
		@CalltypeID int,
		@ExpireEffectiveDateAZFlag int

------------------------------------------------
-- Get essential attributes for the offer
------------------------------------------------

select @SourceID = SourceID,
       @OfferDate = OfferDate,
	   @OfferContent = OfferContent
from tb_Offer
where OfferID = @OfferID


Select @NumberPlanID = NumberplanID
from UC_Reference.dbo.tb_NumberPlan
where ExternalCode = @SourceID

----------------------------------------------------
-- Create temporary tables to store the data for
-- processing
----------------------------------------------------

-------------------------------------------------
-- Table to store all the offer breakouts to be
-- uploaded
-------------------------------------------------

Create table #IncomingOfferBreakouts
(
	UploadBreakoutID int,
	DestinationID int,
	UploadDestinationID int,
	DialedDigit varchar(15),
	CountryCode varchar(100),
	EffectiveDate datetime,
	Flag int,
	Primary Key(DestinationID,DialedDigit)
)

-----------------------------------------------------
-- Create table to store all the previous breakouts for 
-- qualified breakouts from incoming offer
-----------------------------------------------------

Create table #PreviousExistingBreakouts
(
	DialedDigitsID int,
	DialedDigits varchar(15),
	NumberPlanID int,
	DestinationID int,
	BeginDate DateTime,
	EndDate DateTime,
	Flag int,
	Primary Key(DestinationID,DialedDigits)
)

---------------------------------------------------------
--  Compare count also in case the DDs in the offer set are 
--  a subset of the DDs in the reference set
---------------------------------------------------------
Declare @Count table
	(
	DestinationID int,
	CountPerm int,
	CountTemp int,
	Primary Key(DestinationID)
	)


-----------------------------------------------------------
-- Open a cursor for each effective date supplied in the
-- offer and process breakouts for this date
-----------------------------------------------------------

Declare @VarEffectiveDate DateTime

Declare UploadBreakOuts_Cur Cursor For
select Distinct EffectiveDate
from #TempUploadBreakout
order by EffectiveDate

Open UploadBreakOuts_Cur
Fetch Next From UploadBreakOuts_Cur
Into @VarEffectiveDate

While @@FETCH_STATUS = 0
Begin

	Delete from #IncomingOfferBreakouts
	Delete from #PreviousExistingBreakouts

	insert into #IncomingOfferBreakouts
	(
		UploadBreakoutID,
		DestinationID ,
		UploadDestinationID ,
		DialedDigit,
		CountryCode ,
		EffectiveDate,
		Flag
	)
	select tbl1.UploadBreakoutID , tbl2.DestinationID , tbl1.UploadDEstinationID ,
	       tbl1.DialedDigit , tbl1.CountryCode , tbl1.EffectiveDate , tbl1.Flag
	from #TempUploadBreakout tbl1
	inner join #TempUploadDestination tbl2 on tbl1.UploadDestinationID = tbl2.UploadDestinationID
	where tbl1.EffectiveDate = @VarEffectiveDate

	----------------------------------
	-- Printing for debugging purpose
	----------------------------------

	--Select 'Incoming Dialed Digits' ,  @VarEffectiveDate as RunEffectiveDate ,*
	--from #IncomingOfferBreakouts
	--where DialedDigit like '228%'

	-----------------------------------------------------------------------------
	-- Delete following records from the dialeddigits table
	-- 1. All records for destinations which are part of the offer, but have the
	--    begin date greater than the effective date or have the same effective date
	--    but the dialed digit is not in the offer
	-- 2. All Records for the diald digits which are part of the offer, but have the
	--    begin date in future or have the same effective date but not the destination
	------------------------------------------------------------------------------

	Delete dd
	from UC_Reference.dbo.tb_DialedDigits dd 
	join (select distinct DestinationID, EffectiveDate from #IncomingOfferBreakouts) i
		on dd.DestinationID = i.DestinationID
	left join #IncomingOfferBreakouts iDD	
		on  dd.DialedDigits = iDD.DialedDigit
	where dd.NumberPlanID = @NumberPlanID
	and (dd.BeginDate > i.EffectiveDate
		or (dd.BeginDate = i.EffectiveDate and iDD.DialedDigit is null))
	
	Delete dd
	from UC_Reference.dbo.tb_DialedDigits dd 
	join #IncomingOfferBreakouts i
		on dd.DialedDigits = i.DialedDigit
	where dd.NumberPlanID = @NumberPlanID
	and  (dd.BeginDate > i.EffectiveDate
		or (dd.BeginDate = i.EffectiveDate and dd.DestinationID <> i.DestinationID))


    --------------------------------------------------------------------
	-- Get the list of previously active breakouts in the system. 
	-- Following union of records need to be fetched:
	-- 1. Breakouts for all the Destinations in the offer, which were active
	-- as per the effective date
	-- 2. Breakouts for all the Dialed Digits in the offer, which were active
	-- as per effective date
	------------------------------------------------------------------------

	insert into #PreviousExistingBreakouts
	(
		DialedDigitsID ,
		DialedDigits ,
		NumberPlanID ,
		DestinationID ,
		BeginDate ,
		EndDate ,
		Flag 
	)
	select DD.DialedDigitsID , DD.DialedDigits , DD.NumberPlanID ,
	       DD.DestinationID , DD.BeginDate , DD.EndDate , 0
	from UC_Reference.dbo.tb_DialedDigits DD
	inner join ( select distinct DestinationID , EffectiveDate from #IncomingOfferBreakouts) iDD
	  on dd.DestinationID = iDD.DestinationID
	where DD.NumberPlanID = @NumberPlanID
	and iDD.EffectiveDate between DD.BeginDate and isnull(DD.EndDate , iDD.EffectiveDate)

	insert into #PreviousExistingBreakouts
	(
		DialedDigitsID ,
		DialedDigits ,
		NumberPlanID ,
		DestinationID ,
		BeginDate ,
		EndDate ,
		Flag 
	)
	select DD.DialedDigitsID , DD.DialedDigits , DD.NumberPlanID ,
	       DD.DestinationID , DD.BeginDate , DD.EndDate , 0
	from UC_Reference.dbo.tb_DialedDigits DD
	inner join #IncomingOfferBreakouts iDD
	  on dd.DialedDigits = iDD.DialedDigit
	where DD.NumberPlanID = @NumberPlanID
	and iDD.EffectiveDate between DD.BeginDate and isnull(DD.EndDate , iDD.EffectiveDate)
	and DD.DialedDigits not in ( Select DialedDigits from #PreviousExistingBreakouts )


	----------------------------------
	-- Printing for debugging purpose
	----------------------------------

	--Select 'Previous Dialed Digits' ,  @VarEffectiveDate as RunEffectiveDate ,*
	--from #PreviousExistingBreakouts
	--where DialedDigits like '228%'

	---------------------------------------------------------------------
	-- Update the change flag for all the records for a destination
	-- which has change in dial codes when compared to previous data set
	---------------------------------------------------------------------

	update tbl1
	set flag = 64
	from #IncomingOfferBreakouts tbl1
	where UploadDestinationID in
	(
		select iDD.UploadDEstinationID
		from #IncomingOfferBreakouts iDD
		left join #PreviousExistingBreakouts pDD on iDD.DestinationID = pDD.DestinationID 
		           and iDD.DialedDigit = pDD.DialedDigits
		where pDD.DialedDigits is NULL
	)

	----------------------------------------------------------------------
	-- Handle the scenario where the number of dialed digits in the incoming
	-- offer have been reduced and it is a subset of dialed digits existing
	-- in the system
	------------------------------------------------------------------------


	-- Make sure to empty the @Count table of any previous contents
	Delete from @Count

	insert into @Count
	select tbl2.DestinationID,
		   CountPerm,
		   CountTemp
	from ( select count(*) as CountTemp , DestinationID from #IncomingOfferBreakouts group by DestinationID)  tbl1
	inner join (select count(*) as CountPerm , DestinationID from #PreviousExistingBreakouts group by DestinationID) tbl2
	      on tbl1.DestinationID = tbl2.DestinationID


    update tbl1
	set tbl1.Flag = 64
	from #IncomingOfferBreakouts tbl1
	inner join @Count tbl2 on tbl1.DestinationID = tbl2.DestinationID
	where tbl2.CountPerm <> tbl2.CountTemp

	--------------------------------------------------------------------
	-- Set the End date for previous records for the Destinations which
	-- have the flag as 64 , indicating change in breakout set
	--------------------------------------------------------------------

	update #PreviousExistingBreakouts
	set EndDate = NULL
	
	update pDD
	set pDD.EndDate = DateAdd(dd , -1 , iDD.EffectiveDate)
	from #PreviousExistingBreakouts pDD
	inner join #IncomingOfferBreakouts iDD on pDD.DestinationID = iDD.DestinationID
	where idd.Flag & 64 = 64 

	update pDD
	set pDD.EndDate = DateAdd(dd , -1 , iDD.EffectiveDate)
	from #PreviousExistingBreakouts pDD
	inner join #IncomingOfferBreakouts iDD on pDD.DialedDigits = iDD.DialedDigit
	where idd.Flag & 64 = 64 

	update DD
	set DD.EndDate = pDD.EndDate,
	    DD.ModifiedDate = getdate(),
		DD.ModifiedByID = @UserID
	from UC_Reference.dbo.tb_DialedDigits DD
	inner join #PreviousExistingBreakouts pDD on DD.DialedDigitsID = pDD.DialedDigitsID

	------------------------------------------------------------------
	-- Insert records for destinations having changed set into the
	-- dialed digits schema
	------------------------------------------------------------------

	INSERT UC_Reference.dbo.tb_DialedDigits		
		(
			NumberPlanID,
			DestinationID,
			IntIndicator,
			DialedDigits,
			BeginDate,
			ModifiedByID,
			ModifiedDate,
			Flag
		)
		select	
			@NumberPlanID,
			t.DestinationID,
			1,
			t.DialedDigit,
			t.EffectiveDate,
			@UserID,
			Getdate(),
			0
	from #IncomingOfferBreakouts as t
	where t.Flag & 64 = 64


    ---------------------------------------------------------
	-- Update the Upload Breakout table in the reference with
	-- changes from the incoming offer temp table
	---------------------------------------------------------

	Update tbl1
	set tbl1.Flag = tbl2.Flag
	From tb_UploadBreakout tbl1
	inner join #IncomingOfferBreakouts tbl2 on tbl1.UploadBreakoutID = tbl2.UploadBreakoutID

	Fetch Next From UploadBreakOuts_Cur
	Into @VarEffectiveDate

End

Close UploadBreakOuts_Cur
Deallocate UploadBreakOuts_Cur


-------------------------------------------------------------------------
-- Expire all the other destinations for the countries provided as part
-- of the Full Country or A-Z offer
-------------------------------------------------------------------------

Select @ExpireEffectiveDateAZFlag = ConfigValue
from UC_Admin.dbo.tb_Config
where Configname = 'ExpireEffectiveDateAZ'

if ( ( @ExpireEffectiveDateAZFlag is Null ) or ( @ExpireEffectiveDateAZFlag not in (1,2,3) ))
Begin

	set @ExpireEffectiveDateAZFlag = 3 -- Default Value

End

select tbl3.CountryID , tbl3.CountryCode
into #TempSharedCountryCode
from UC_Reference.dbo.tb_EntityGroup tbl1
inner join UC_Reference.dbo.tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.InstanceID = tbl3.CountryID
where tbl1.EntityGroupTypeID = -4 -- Country Grouping

Create table #TempCountryData ( CountryCode varchar(100) , EffectiveDate Date )

--------------------------------------------------
-- Create a table to hold all the dialed digits 
-- and destinations provided in the vendor offer
--------------------------------------------------

Create table #TempOfferDialedDigit 
(
	UploadDestinationID int,
	DestinationID int,
	OfferDate datetime,
	EffectiveDate datetime,
	DialedDigit varchar(15),
	CountryCode varchar(100),
	Flag int
)

Create index idx_OfferDialedDigit on #TempOfferDialedDigit(DialedDigit)

if (@OfferContent in ('FC' , 'AZ' )) 
Begin

	----------------------------------------------------------
	-- Insert data into the temporary table for all the vendor
	-- offer destinations and dialed digits
	-----------------------------------------------------------
   
	Insert #TempOfferDialedDigit
		(
		UploadDestinationID,
		DestinationID,
		OfferDate,
		EffectiveDate,
		DialedDigit,
		CountryCode
		)
		Select  distinct
			d.UploadDestinationID,
			d.DestinationID,
			d.OfferDate,
			dd.EffectiveDate,
			dd.DialedDigit,
			dd.CountryCode
		From #TempUploadDestination as d
		join #TempUploadBreakout as dd on dd.UploadDestinationID=d.UploadDestinationID

		----------------------------------------------------------------------------------
		-- Logic for finding the effective date:
		-- If the max and min effective dates for destinations of a country in the offer 
		-- is the same then use the Effective date
		-- In case there are multiple Effective dates:
		-- 1 : Use the Max value between offer date and Min Effective date for the country
		-- 2 : Use the Offer Date
		-- 3 : Use the MAx Effective date for the country
		----------------------------------------------------------------------------------

		insert into #TempCountryData
		(CountryCode , EffectiveDate)
		Select Distinct CountryCode,
		   Case

				When Max(EffectiveDate) = Min(EffectiveDate) then Min(EffectiveDate)
				When Max(EffectiveDate) <> Min(EffectiveDate) then
					Case

						When @ExpireEffectiveDateAZFlag = 1 then
							Case
								When Min(EffectiveDate) > convert(date , @OfferDate) then Min(EffectiveDate)
								When Min(EffectiveDate) < convert(date , @OfferDate) then convert(date , @OfferDate)
								When Min(EffectiveDate) = convert(date , @OfferDate) then convert(date , @OfferDate)								
							End
						When @ExpireEffectiveDateAZFlag = 2 then convert(date , @OfferDate)
						When @ExpireEffectiveDateAZFlag = 3 then max(EffectiveDate)
					
					End						
		   End
         from #TempOfferDialedDigit
		 Group by CountryCode


End

if ( @OfferContent = 'FC' )
Begin

	----------------------------------------------------------------
	-- Remove all the Countries from the Country table, which are
	-- part of a country group. This is to ensure that records of
	-- destinations which belong to Countries of a country group
	-- are not expoired
	----------------------------------------------------------------

	delete from #TempCountryData
	where CountryCode in
	( select CountryCode from #TempSharedCountryCode )

	----------------------------------------------------------------------
	-- Retire digits for destinations for countries that are in the offer. 
	--Have to retire products based on the effdate for the country
	----------------------------------------------------------------------

	Update dd
		Set EndDate = dateadd(dd , -1 ,o.EffectiveDate),
		    ModifiedDate = getdate(),
	 	    ModifiedByID = @UserID
		from UC_Reference.dbo.tb_DialedDigits dd 
		join UC_Reference.dbo.tb_Destination d
			on dd.DestinationID = d.DestinationID
        join UC_Reference.dbo.tb_Country  c               
			on d.CountryID = c.CountryID
		join #TempCountryData o				
			on  c.CountryCode = o.CountryCode
		left join #TempOfferDialedDigit as t
			on dd.DestinationID = t.DestinationID
		where d.NumberPlanID = @NumberPlanID
		and   (dd.EndDate is null or dd.EndDate >= (o.EffectiveDate))
		and   t.destinationid is null
		and   dd.DialedDigits not in (Select distinct DialedDigit from #TempOfferDialedDigit)


End

if ( @OfferContent = 'AZ')
Begin

    -------------------------------------------------------------------------
	-- Retire digits for destinations for countries that are in the offer. 
	-- Have to retire products based on the effdate for the country
	-------------------------------------------------------------------------

	Update dd
		Set EndDate = dateadd(dd , -1 ,o.EffectiveDate),
		    ModifiedDate = getdate(),
	 	    ModifiedByID = @UserID
		from UC_Reference.dbo.tb_DialedDigits dd 
		join UC_Reference.dbo.tb_Destination d
			on dd.DestinationID = d.DestinationID
                join UC_Reference.dbo.tb_Country  c               
			on d.CountryID = c.CountryID
		join #TempCountryData o				
			on  c.CountryCode = o.CountryCode
		left join #TempOfferDialedDigit as t
			on dd.DestinationID = t.DestinationID
		where d.NumberPlanID = @NumberPlanID
		and   (dd.EndDate is null or dd.EndDate >= (o.EffectiveDate))
		and   t.destinationid is null
		and   dd.DialedDigits not in (Select distinct DialedDigit from #TempOfferDialedDigit)


    ----------------------------------------------------------------------------
	-- Retire digits for destinations that are not in the offer as of OfferDate
	----------------------------------------------------------------------------

	Update dd
		Set EndDate = convert(date,DateAdd(dd , -1 ,@OfferDate)),
		    ModifiedDate = getdate(),
	 	    ModifiedByID = @UserID
		from UC_Reference.dbo.tb_DialedDigits as dd 
		join UC_Reference.dbo.tb_Destination d
			on dd.DestinationID = d.DestinationID
		left join #TempOfferDialedDigit as t
			on dd.DestinationID = t.DestinationID
		where dd.NumberPlanID = @NumberPlanID
		and   (dd.EndDate is null or dd.EndDate >= convert(date,@OfferDate))
		and   t.destinationid is null
		and   dd.DialedDigits not in (Select DialedDigit from #TempOfferDialedDigit) 


End


-----------------------------------------------
-- Drop all temporary tables after processing
-----------------------------------------------

Drop table #IncomingOfferBreakouts
Drop table #PreviousExistingBreakouts
Drop table #TempOfferDialedDigit
Drop table #TempCountryData
Drop table #TempSharedCountryCode

Return 0
GO
