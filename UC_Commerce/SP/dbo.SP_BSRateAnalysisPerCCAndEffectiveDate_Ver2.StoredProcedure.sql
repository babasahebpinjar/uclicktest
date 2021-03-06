USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRateAnalysisPerCCAndEffectiveDate_Ver2]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRateAnalysisPerCCAndEffectiveDate_Ver2]
(
	@ProcessCountryCode varchar(15),
	@EffectiveDate Datetime,
	@OfferID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @ErrorMsgStr varchar(2000),
        @NumberplanID int,
		@RatePlanID int,
		@CallTypeID int,
		@SourceID int

select @SourceID = SourceID
from tb_Offer
where OfferID = @OfferID

Select @NumberPlanID = NumberplanID
from UC_Reference.dbo.tb_NumberPlan
where ExternalCode = @SourceID

select @RatePlanID = RatePlanID,
       @CallTypeID = CallTypeID
from tb_Source
where sourceID = @SourceID

--------------------------------
-- Print for debugging purpose
--------------------------------

--select @RatePlanID as RatePlanID,
--       @CallTypeID as CallTypeID,
--	   @EffectiveDate as EffectiveDate
        
------------------------------------------------------------
-- Create temporary table to hold all the dialed digits
-- from Reference and vendor Offer for a specific country
-- code and effective date
------------------------------------------------------------

Create table #TempAllDialedDigits
(
	DestinationID int,
	Destination varchar(60),
	DialedDigits varchar(15),
	DestinationNP varchar(100)
)

---------------------------------------
-- Insert data into the Temporary table
---------------------------------------

insert into #TempAllDialedDigits
(DestinationID , Destination , DialedDigits , DestinationNP)
select Dest.DestinationID , Dest.Destination , DD.DialedDigits,
		Case
			When Dest.NumberPlanID = -1 Then 'Reference'
			Else 'Vendor'
		End as DestinationNP
from UC_Reference.dbo.Tb_Destination Dest
inner join UC_Reference.dbo.tb_DialedDigits DD on Dest.DestinationID = DD.DestinationID
inner join UC_Reference.dbo.tb_Country Cou on Dest.CountryID = Cou.CountryID
where cou.CountryCode = @ProcessCountryCode
and @EffectiveDate between DD.BeginDate and isnull(DD.EndDate , @EffectiveDate)
and Dest.NumberPlanID in (-1 , @NumberPlanID)

--------------------------------------------------------------
-- There could be a case that the country code is part of a 
-- Country Group and the dialed digits may be residing under
-- destinattion with a different country ID
---------------------------------------------------------------
-- Example : Dominica Republic has Country codes:
-- 1829
-- 1809
-- 1849
---------------------------------------------------------------

Declare @CountryGroupID int

select @CountryGroupID = GroupID
from vw_CountryGroupXRef
where countrycode = @ProcessCountryCode

if ( @CountryGroupID is not NULL )
Begin


		insert into #TempAllDialedDigits
		(DestinationID , Destination , DialedDigits , DestinationNP)
		select Dest.DestinationID , Dest.Destination , DD.DialedDigits, 'Vendor'
		from UC_Reference.dbo.Tb_Destination Dest
		inner join UC_Reference.dbo.tb_DialedDigits DD on Dest.DestinationID = DD.DestinationID
		inner join UC_Reference.dbo.tb_Country Cou on Dest.CountryID = Cou.CountryID
		where cou.CountryCode in
		   ( 
				select countrycode
				from vw_CountryGroupXRef
				where GroupID = @CountryGroupID
		   )
		and @EffectiveDate between DD.BeginDate and isnull(DD.EndDate , @EffectiveDate)
		and Dest.NumberPlanID  = @NumberPlanID
		and substring( DD.DialedDigits , 1 , len(@ProcessCountryCode) ) = @ProcessCountryCode
	
	
End


------------------------------------
-- Printing for Debugging purpose
------------------------------------

--select *
--from #TempAllDialedDigits


-----------------------------------------------------
-- Select all the Distinct Dialed digits from the
-- combination of Reference and Vendor break outs
-- top form the master list
-----------------------------------------------------

Select Distinct DialedDigits
into #TempMasterDialedDigits
from #TempAllDialedDigits

--select *
--from #TempMasterDialedDigits

--------------------------------------------------------
-- Create table which holds all the dialed digit range
--------------------------------------------------------

Create table #TempAllDDRange
(
	DialedDigits varchar(15),
	DDLength int,
	ReferenceDestinationID int,
	VendorDestinationID int,
	BreakoutFlag int,
	ProcessFlag int
)

----------------------------------------------------------
-- From the Code, form the minimum and maximum Values
-- for which we need to run the procedure for finding
-- DD Range
----------------------------------------------------------

Create table #TempSuffixCode
(
	SuffixCode varchar(1)
)

insert into #TempSuffixCode (SuffixCode) values ('1')
insert into #TempSuffixCode (SuffixCode) values ('2')
insert into #TempSuffixCode (SuffixCode) values ('3')
insert into #TempSuffixCode (SuffixCode) values ('4')
insert into #TempSuffixCode (SuffixCode) values ('5')
insert into #TempSuffixCode (SuffixCode) values ('6')
insert into #TempSuffixCode (SuffixCode) values ('7')
insert into #TempSuffixCode (SuffixCode) values ('8')
insert into #TempSuffixCode (SuffixCode) values ('9')
insert into #TempSuffixCode (SuffixCode) values ('0')


Declare @CountryCode varchar(15) = @ProcessCountryCode,
		@DDRangeValue varchar(15),
		@ProcessingLength int

Insert into #TempAllDDRange ( DialedDigits , DDLength , BreakoutFlag , ProcessFlag )
select @CountryCode + SuffixCode , Len(@CountryCode + SuffixCode) , 0 , 0
from #TempSuffixCode

set @ProcessingLength = Len(@CountryCode + '0')

------------------------------------------------------------- 
-- Find out those Dialed Digits which have further breakout
-- and mark there process flag as 0
-------------------------------------------------------------

update TB1
set breakoutFlag = 1,
    ProcessFLag = 0
from #TempAllDDRange TB1
inner join 
(
	select Distinct tbl1.DialedDigits
	from #TempAllDDRange tbl1
	inner join
	(
		select Substring(DialedDigits , 1, @ProcessingLength + 1) DD
		From #TempMasterDialedDigits
		where Len(DialedDigits) > @ProcessingLength
	) tbl2 on tbl1.DialedDigits = substring(tbl2.DD , 1 , @ProcessingLength)
) TB2 on TB1.DialedDigits = TB2.DialedDigits



----------------------------------------------------
-- For Records which have no further breakout, mark
-- process flag as 1
-----------------------------------------------------

Update #TempAllDDRange
set ProcessFlag = 1
where breakoutFlag = 0


----------------------------------------------------------------------
-- Loop through until all the Dialed digits with process flag as 0
-- are not addressed
----------------------------------------------------------------------

While exists ( select 1 from #TempAllDDRange where ProcessFlag = 0 )
Begin


		Insert into #TempAllDDRange ( DialedDigits , DDLength , BreakoutFlag , ProcessFlag )
		select DialedDigits + SuffixCode , Len(DialedDigits + SuffixCode) , 0 , 0
		from #TempAllDDRange
		cross join #TempSuffixCode
		where DDLength = @ProcessingLength
		and ProcessFlag = 0
		and BreakoutFlag <> 0

		------------------------------------------------------
		-- Delete the records as we have inserted a more
		-- detailed breakout for the records
		-------------------------------------------------------

		Delete from #TempAllDDRange
		where  DDLength = @ProcessingLength
		and ProcessFlag = 0
		and BreakoutFlag <> 0

		set @ProcessingLength = @ProcessingLength + 1

		------------------------------------------------------------- 
		-- Find out those Dialed Digits which have further breakout
		-- and mark there process flag as 0
		-------------------------------------------------------------

		update TB1
		set breakoutFlag = 1,
			ProcessFLag = 0
		from #TempAllDDRange TB1
		inner join 
		(
			select Distinct tbl1.DialedDigits
			from #TempAllDDRange tbl1
			inner join
			(
				select Substring(DialedDigits , 1, @ProcessingLength + 1) DD
				From #TempMasterDialedDigits
				where Len(DialedDigits) > @ProcessingLength
			) tbl2 on tbl1.DialedDigits = substring(tbl2.DD , 1 , @ProcessingLength)
		) TB2 on TB1.DialedDigits = TB2.DialedDigits

		----------------------------------------------------
		-- For Records which have no further breakout, mark
		-- process flag as 1
		-----------------------------------------------------

		Update #TempAllDDRange
		set ProcessFlag = 1
		where breakoutFlag = 0
		and DDLength = @ProcessingLength
		
End

-------------------------------------------------------------------------
-- In case the country Code is 1 , we need to mae sure that we remove all
-- the dialed digits which belong to other countries in the NADP region
-------------------------------------------------------------------------

Declare @VarNADPCountryCode int

Declare @NADPCountries table 
(
	CountryID int,
	CountryCode varchar(100)
)

insert into @NADPCountries ( CountryID , CountryCode ) 
select CountryID , CountryCode
from UC_Reference.dbo.tb_Country
where CountryCode like '1%'
and CountryCode <> '1'
and flag & 1 <> 1


if (@ProcessCountryCode = '1' ) 
Begin

		DECLARE db_remove_NADPCountries CURSOR FOR  
		select CountryCode
		From @NADPCountries
		order by len(CountryCode) Desc


		OPEN db_remove_NADPCountries   
		FETCH NEXT FROM db_remove_NADPCountries
		INTO @VarNADPCountryCode 

		WHILE @@FETCH_STATUS = 0   
		BEGIN  

		       Delete from #TempAllDDRange
			   where substring(DialedDigits , 1 ,  len(@VarNADPCountryCode) ) = @VarNADPCountryCode

			   FETCH NEXT FROM db_remove_NADPCountries
			   INTO  @VarNADPCountryCode 
 
		END   

		CLOSE db_remove_NADPCountries  
		DEALLOCATE db_remove_NADPCountries

End

------------------------------------
-- Print data for debug purposes
-------------------------------------

--select 'Before Populating Reference and Vendor' ,*
--from #TempAllDDRange


------------------------------------------------------------
-- Analyze the Dialed Digit Range against the Reference
-- Destination Dial Codes to establish the Destination
-------------------------------------------------------------

Declare @VarDialedDigits varchar(15),
        @VarDestinationID int

-----------------------------------
-- Populate Reference Destination
-----------------------------------
        
DECLARE db_populate_Resolve_RefDestination CURSOR FOR  
select DialedDigits , DestinationID
From #TempAllDialedDigits
where DestinationNP = 'Reference'
order by len(DialedDigits) Desc


OPEN db_populate_Resolve_RefDestination   
FETCH NEXT FROM db_populate_Resolve_RefDestination
INTO @VarDialedDigits , @VarDestinationID 

WHILE @@FETCH_STATUS = 0   
BEGIN  

       update #TempAllDDRange
	   set ReferenceDestinationID = @VarDestinationID
	   where ReferenceDestinationID is NULL
	   and substring(DialedDigits , 1 ,  len(@VarDialedDigits) ) = @VarDialedDigits

	   FETCH NEXT FROM db_populate_Resolve_RefDestination
	   INTO  @VarDialedDigits , @VarDestinationID 
 
END   

CLOSE db_populate_Resolve_RefDestination  
DEALLOCATE db_populate_Resolve_RefDestination


-------------------------------
-- Populate Vendor Destination
-------------------------------

DECLARE db_populate_Resolve_VendorDestination CURSOR FOR  
select DialedDigits , DestinationID
From #TempAllDialedDigits
where DestinationNP = 'Vendor'
order by len(DialedDigits) Desc


OPEN db_populate_Resolve_VendorDestination   
FETCH NEXT FROM db_populate_Resolve_VendorDestination
INTO @VarDialedDigits , @VarDestinationID 

WHILE @@FETCH_STATUS = 0   
BEGIN  

       update #TempAllDDRange
	   set VendorDestinationID = @VarDestinationID
	   where VendorDestinationID is NULL
	   and substring(DialedDigits , 1 ,  len(@VarDialedDigits) ) = @VarDialedDigits

	   FETCH NEXT FROM db_populate_Resolve_VendorDestination
	   INTO  @VarDialedDigits , @VarDestinationID 
 
END   

CLOSE db_populate_Resolve_VendorDestination  
DEALLOCATE db_populate_Resolve_VendorDestination

------------------------------------
-- Print data for debug purposes
-------------------------------------

--select 'After populating Reference and Vendor' , *
--from #TempAllDDRange


-----------------------------------------------------------------------
-- Create the Master DD Range Repository for following combination
-- FromDD
-- ToDD
-- DDLength
-- ReferenceDestination
-- VendorDestination
-----------------------------------------------------------------------

Create Table #TempDDRangeMaster
(
	FromDD varchar(15),
	ToDD varchar(15),
	DDLength int,
	ReferenceDestinationID int,
	VendorDestinationID int
)

Begin Try

	Exec SP_BSPrepareDDRangeMaster_Ver2 

End Try

Begin Catch

		set @ErrorDescription = 'ERROR!!! Preparing Dialed Digit Range Master Reference=.' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorMsgStr)

		set @ResultFlag = 1
			
		GOTO ENDPROCESS

End Catch

-----------------------------------------------
-- Print the data for the purpose of debugging
-----------------------------------------------

select @ProcessCountryCode as CountryCode , count(*)
from #TempDDRangeMaster

--select tbl1.* ,  tbl2.Destination as RefDestination , tbl3.Destination as VendorDestination
--from #TempDDRangeMaster tbl1
--left join (
--				Select distinct DestinationID , Destination
--				From #TempAllDialedDigits
--				where DestinationNP = 'Reference'
--           ) tbl2 on tbl1.ReferenceDestinationID = tbl2.DestinationID
--left join (
--				Select distinct DestinationID , Destination
--				From #TempAllDialedDigits
--				where DestinationNP = 'Vendor'
--           ) tbl3 on tbl1.VendorDestinationID = tbl3.DestinationID


---------------------------------------------------------
-- Get the essential rates for Vendor destinations and 
-- populate the temporary table
---------------------------------------------------------

Create table #TempVendorRates
(
	DestinationID int,
	CallTypeID int,
	RatingMethodID int,
	RateTypeID int,
	Rate decimal(19,6),
	BeginDate Date,
	EndDate Date
)


insert into #TempVendorRates
(
	DestinationID,
	CallTypeID,
	RatingMethodID,
	RateTypeID,
	Rate,
	BeginDate,
	EndDate
)
Select rt.DestinationID , rt.CallTypeID , rt.RatingMethodID , rtd.RateTypeID,
       rtd.Rate , rt.BeginDate , rt.EndDate
from UC_Reference.dbo.tb_Rate rt
inner join UC_Reference.dbo.tb_RateDetail rtd on rt.RateID = rtd.rateID
inner join ( select distinct VendorDestinationID from  #TempDDRangeMaster) vdest on rt.DestinationID = vdest.VendorDestinationID
Where rt.RatePlanID = @RatePlanID
and rt.CallTypeID = @CallTypeID
and @EffectiveDate between rt.BeginDate and isnull(rt.EndDate, @EffectiveDate)


-----------------------------------------------
-- Print the data for the purpose of debugging
-----------------------------------------------

--select *
--from #TempVendorRates

-----------------------------------------------------------
-- Check if there are any records in the dial code analysis
-- where the reference destination is NULL. This is indicative
-- that the ROC dialed digit does not exist for the country
-- to resolve these dialed digit range
-----------------------------------------------------------

if not exists ( select 1 from #TempAllDialedDigits where DialedDigits = @ProcessCountryCode ) 
Begin

	Delete from #TempDDRangeMaster
	where ReferenceDestinationID is NULL

End


------------------------------------------------------------------
-- Insert records into tb_RateAnalysisDetail for all the 
-- dial code range analysis for reference and vendor destinations
--------------------------------------------------------------------

Create table #TempRateAnalysisDetail
(
	OfferID int,
	AnalysisDate datetime,
	RefDestinationID int,
	VendorDestinationID int,
	DDFrom varchar(15),
	DDTo varchar(15),
	CountryCode varchar(100)
)

Insert into #TempRateAnalysisDetail
(
	OfferID ,
	AnalysisDate ,
	RefDestinationID ,
	VendorDestinationID ,
	DDFrom ,
	DDTo ,
	CountryCode
)
select @OfferID , @EffectiveDate , tbl1.ReferenceDestinationID , tbl1.VendorDestinationID ,
       tbl1.FromDD , tbl1.ToDD , @ProcessCountryCode 
from #TempDDRangeMaster tbl1


--Insert into Tb_RateAnalysisDetail
--(
--	OfferID ,
--	AnalysisDate ,
--	RefDestinationID ,
--	VendorDestinationID ,
--	DDFrom ,
--	DDTo ,
--	CountryCode,
--	ModifiedDate,
--	ModifiedByID,
--	Flag
--)
--select	OfferID ,
--		AnalysisDate ,
--		RefDestinationID ,
--		VendorDestinationID ,
--		DDFrom ,
--		DDTo ,
--		CountryCode,
--		GetDate(),
--		@UserID,
--		0
--from #TempRateAnalysisDetail

-----------------------------------------------
-- Print the data for the purpose of debugging
-----------------------------------------------

select *
from #TempRateAnalysisDetail
order by DDFrom , DDTo


--------------------------------------------------------
-- Insert records into the table tb_RateAnalysisRate
-- for all the Vendor Destination Rates for the
-- analyzed reference destinations
---------------------------------------------------------
CREATE TABLE #TempRateAnalysisRate
(
	[OfferID] [int] NOT NULL,
	[AnalysisDate] [datetime] NOT NULL,
	[RefDestinationID] [int] NOT NULL,
	[VendorDestinationID] [int] NOT NULL,
	[Rate] [decimal](19, 6) NOT NULL,
	[RateTypeID] [int] NOT NULL,
	[RatingMethodID] [int] NOT NULL,
	[EffectiveDate] [datetime] NULL
)

insert into #TempRateAnalysisRate
(
	OfferID,
	AnalysisDate,
	RefDestinationID,
	VendorDestinationID,
	Rate,
	RateTypeID,
	RatingMethodID,
	EffectiveDate
)
select Distinct tbl1.OfferID , tbl1.AnalysisDate , tbl1.RefDestinationID , tbl1.VendorDestinationID,
       tbl2.Rate , tbl2.RateTypeID , tbl2.RatingMethodID , tbl2.BeginDate
from #TempRateAnalysisDetail tbl1
inner join #TempVendorRates tbl2 on tbl1.VendorDestinationID = tbl2.DestinationID



--insert into Tb_RateAnalysisRate
--(
--	OfferID,
--	AnalysisDate,
--	RefDestinationID,
--	VendorDestinationID,
--	Rate,
--	RateTypeID,
--	RatingMethodID,
--	EffectiveDate,
--	ModifiedDate,
--	ModifiedByID,
--	Flag
--)
--select OfferID,
--		AnalysisDate,
--		RefDestinationID,
--		VendorDestinationID,
--		Rate,
--		RateTypeID,
--		RatingMethodID,
--		EffectiveDate,
--		GetDate(),
--		@UserID,
--		0
--from #TempRateAnalysisRate


-----------------------------------------------
-- Print the data for the purpose of debugging
-----------------------------------------------

select *
from #TempRateAnalysisRate

ENDPROCESS:

--------------------------------------------------
-- Drop all the temporary tables post processing
--------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDialedDigits') )
	Drop table #TempAllDialedDigits

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDDRange'))
	Drop table #TempAllDDRange

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMasterDialedDigits') )
	Drop table #TempMasterDialedDigits

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDDRangeMaster') )
	Drop table #TempDDRangeMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisDetail') )
	Drop table #TempRateAnalysisDetail

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisRate') )
	Drop table #TempRateAnalysisRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempVendorRates') )
	Drop table #TempVendorRates

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempSuffixCode') )
	Drop table #TempSuffixCode
GO
