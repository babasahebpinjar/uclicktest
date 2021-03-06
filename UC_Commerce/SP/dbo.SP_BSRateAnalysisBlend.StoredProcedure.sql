USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRateAnalysisBlend]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRateAnalysisBlend]
(
	@OfferID int,
	@UserID int
)
As

Declare @ErrorMsgStr varchar(2000)

Declare @MobileMin int,
		@MobileMax int,
		@FixedMin int,
		@FixedMax int,
		@OverRideRate Decimal(19,6)

Declare @BlendingProcess varchar(100)

select @MobileMin = convert(int,ConfigValue)
from UC_Admin.dbo.tb_Config
where Configname = 'MobileMin'

select @MobileMax = convert(int,ConfigValue)
from UC_Admin.dbo.tb_Config
where Configname = 'MobileMax'


select @FixedMin = convert(int,ConfigValue)
from UC_Admin.dbo.tb_Config
where Configname = 'FixedMin'

select @FixedMax = convert(int,ConfigValue)
from UC_Admin.dbo.tb_Config
where Configname = 'FixedMax'

select @BlendingProcess = ConfigValue
from UC_Admin.dbo.tb_Config
where Configname = 'BlendingProcess'

select @OverRideRate = isnull (convert(decimal(19,6) ,ConfigValue) , 99.99)
from UC_Admin.dbo.tb_Config
where Configname = 'OverRideRate'


if ( @BlendingProcess is Not NULL )
Begin

		if ( (@MobileMin is NULL ) or (@MobileMax is NULL) or (@FixedMax is NULL) or (@FixedMin is NULL) )
		Begin

				set @ErrorMsgStr = 'One of the configuration paramenters ( MobileMin/MobileMsx/FixedMin/FixedMax ) is a NULL value or not configured'
				RaisError('%s' , 16, 1 , @ErrorMsgStr)
				Return 1
				
		End 

		if ( ( ( @MobileMin + @MobileMax ) <> 100 ) or ( ( @FixedMin + @FixedMax ) <> 100 ) )
		Begin

				set @ErrorMsgStr = 'Percentage total for Mobile or Fixed blending is not 100 percent. Please check values for parameters ( MobileMin/MobileMsx/FixedMin/FixedMax ) '
				RaisError('%s' , 16, 1 , @ErrorMsgStr)
				Return 1
				
		End 

End 

Else
Begin

		set @MobileMax = 100
		set @MobileMin = 0

		set @FixedMin = 0
		set @FixedMax = 100

End


Create table #TempAnalysisRate
(
	RefDestinationID int,
	VendorDestinationID int,
	AnalysisDate datetime,
	Rate Decimal(19,6),
	RateTypeID int,
	RatingMethodID int
)

------------------------------------------------------
-- Insert data for all the differeent Reference and
-- Vendor Destinations combinations
-----------------------------------------------------

insert into #TempAnalysisRate
(
	RefDestinationID,
	VendorDestinationID,
	AnalysisDate,
	Rate ,
	RateTypeID ,
	RatingMethodID
)
select distinct
	tbl1.RefDestinationID,
	tbl1.VendorDestinationID,
	tbl1.AnalysisDate,
	tbl2.Rate ,
	tbl2.RateTypeID ,
	tbl2.RatingMethodID
from tb_RateAnalysisDetail tbl1
left join tb_RateAnalysisRate tbl2 on
	tbl1.OfferID = tbl2.OfferID
	and
	tbl1.RefDestinationID = tbl2.RefDestinationID
	and 
	isnull(tbl1.VendorDestinationID, -9999) = tbl2.VendorDestinationID
	and 
	tbl1.AnalysisDate = tbl2.AnalysisDate
where tbl1.OfferID = @OfferID


---------------------------------------
-- Print info for debugging purposes
---------------------------------------

--select *
--from #TempAnalysisRate

--select *
--from #TempAnalysisRate
--where VendorDestinationID is NULL

--------------------------------------------------------------
-- Get the attributes for the Reference Destination to check
-- if it is a mobile or a fixed destination
--------------------------------------------------------------

select DestinationID , DestinationTypeID
into #RefDest
from 
(
	select distinct RefDestinationID
	from #TempAnalysisRate
) tbl1
inner join UC_Reference.dbo.tb_Destination tbl2  on tbl1.RefDestinationID = tbl2.DestinationID


------------------------------------------------------------------------------
-- We need to sort out scenarios where there could be reference destinations
-- analyzed to vendor destinations having different rating methods
-- In such a scenario we need to find the highest rate across all the tiers 
-- for each destination, and use the same for analysis, along with the default
-- Rating Method  ( Default: Flat Time Based Rating)
------------------------------------------------------------------------------

select RefDestinationID , AnalysisDate , Count(*) as Cnt 
into #TempMultipleRatingMethodCount
from 
(
	select distinct  RefDestinationID , AnalysisDate , RatingMethodID
	from #TempAnalysisRate
	where VendorDestinationID is not NULL
) as tbl1
group by RefDestinationID , AnalysisDate

---------------------------------------
-- Print info for debugging purposes
---------------------------------------

--select *
--from #TempMultipleRatingMethodCount

------------------------------------------------------------------
-- Handle those reference destinations which have no Vendor
-- destination analyzed against them and have the Rating Method
-- and Rate Type as NULL
------------------------------------------------------------------

--select tbl1.*
--from #TempAnalysisRate tbl1
--left join #TempMultipleRatingMethodCount tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
--                                      and tbl1.AnalysisDate = tbl2.AnalysisDate
--where tbl2.RefDestinationID is NULL

Update tbl1
	set RatingMethodID = -2 ,-- Default Rating Method
	    RateTypeID  = 101 -- Tier 1 Rate Item
from #TempAnalysisRate tbl1
left join #TempMultipleRatingMethodCount tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
                                      and tbl1.AnalysisDate = tbl2.AnalysisDate
where tbl2.RefDestinationID is NULL

--------------------------------------------------------------------
-- Handle those Reference Destinations which have one kind of 
-- Rating Method, but there can be records for NULL Vendor
-- destination ID as well
--------------------------------------------------------------------

Create table #TempAnalysisRateSingleRM
(
	RefDestinationID int,
	AnalysisDate datetime,
	RateTypeID int,
	RatingMethodID int
)

insert into #TempAnalysisRateSingleRM
(
	RefDestinationID ,
	AnalysisDate,
	RateTypeID ,
	RatingMethodID 
)
select  Distinct
		tbl1.RefDestinationID,
		tbl1.AnalysisDate,
		tbl1.RateTypeID,
		tbl1.RatingMethodID		
from #TempAnalysisRate tbl1
inner join #TempMultipleRatingMethodCount tbl2 
        on tbl1.RefDestinationID = tbl2.RefDestinationID
        and tbl1.AnalysisDate = tbl2.AnalysisDate
where tbl2.Cnt = 1
and tbl1.VendorDestinationID is Not NULL


insert into #TempAnalysisRate
(
	RefDestinationID,
	VendorDestinationID,
	AnalysisDate,
	Rate ,
	RateTypeID ,
	RatingMethodID
)
select  tbl1.RefDestinationID,
		NULL,
		tbl1.AnalysisDate,
		NULL ,
		tbl2.RateTypeID ,
		tbl2.RatingMethodID
from #TempAnalysisRate tbl1
inner join #TempAnalysisRateSingleRM tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
                                          and tbl1.AnalysisDate = tbl2.AnalysisDate
where tbl1.VendorDestinationID is NULL


Delete tbl1
from #TempAnalysisRate tbl1
inner join ( select distinct RefDestinationID , AnalysisDate from #TempAnalysisRateSingleRM ) tbl2 
         on tbl1.RefDestinationID = tbl2.RefDestinationID
         and tbl1.AnalysisDate = tbl2.AnalysisDate
where tbl1.VendorDestinationID is NULL
and tbl1.RatingMethodID is NULL
and tbl1.RateTypeID is NULL
										   

-----------------------------------------------------------
-- Create a temporary table to store all the records for 
-- those reference destinations which have multiple
-- rating methods
----------------------------------------------------------

Create table #TempAnalysisRateMultipleRM
(
	RefDestinationID int,
	VendorDestinationID int,
	AnalysisDate datetime,
	Rate Decimal(19,6),
	RateTypeID int,
	RatingMethodID int
)

insert into #TempAnalysisRateMultipleRM
(
	RefDestinationID,
	VendorDestinationID,
	AnalysisDate,
	Rate ,
	RateTypeID ,
	RatingMethodID
)
select tbl1.RefDestinationID,
       tbl2.VendorDestinationID,
	   tbl1.AnalysisDate,
	   Max(Rate),
	   101,
	   -2
from #TempMultipleRatingMethodCount tbl1
inner join #TempAnalysisRate tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
                         and tbl1.AnalysisDate = tbl2.AnalysisDate
where tbl2.VendorDestinationID is NOT NULL
and tbl1.Cnt > 1
Group by tbl1.RefDestinationID , tbl2.VendorDestinationID , tbl1.AnalysisDate

-------------------------------------------------------------------
-- Delete old records from the analysis table and insert these new
-- enrichment records for multiple RM scenarios
-------------------------------------------------------------------


if exists ( select 1 from #TempAnalysisRateMultipleRM )
Begin

        --------------------------------------------------------
		-- COMMENTED WRONG LOGIC IN CODE AS IT WWAS CAUSING ALL
		-- RECORDS TO GET DELETED
		---------------------------------------------------------

		--Delete tbl2
		--from #TempMultipleRatingMethodCount tbl1
		--inner join #TempAnalysisRate tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
		--						 and tbl1.AnalysisDate = tbl2.AnalysisDate
        -- where tbl2.VendorDestinationID is NOT NULL

		---------------------------------------------
		-- CORRECT LOGIC IMPLEMENTED ON 03-OCT-2016
		---------------------------------------------

		Delete tbl2
		from ( Select distinct RefDestinationID , AnalysisDate from  #TempAnalysisRateMultipleRM ) tbl1
		inner join #TempAnalysisRate tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
								 and tbl1.AnalysisDate = tbl2.AnalysisDate
        where tbl2.VendorDestinationID is NOT NULL

        --------------------------------------------------------
		-- COMMENTED WRONG LOGIC IN CODE AS IT WWAS CAUSING ALL
		-- RECORDS TO GET DELETED
		---------------------------------------------------------

		--update tbl2
		--	set RatingMethodID = -2,
		--	    RatetypeID = 101
		--from #TempMultipleRatingMethodCount tbl1
		--inner join #TempAnalysisRate tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
		--						 and tbl1.AnalysisDate = tbl2.AnalysisDate
        --where tbl2.VendorDestinationID is NULL

		---------------------------------------------
		-- CORRECT LOGIC IMPLEMENTED ON 03-OCT-2016
		---------------------------------------------

		update tbl2
			set RatingMethodID = -2,
			    RatetypeID = 101
		from ( Select distinct RefDestinationID , AnalysisDate from  #TempAnalysisRateMultipleRM ) tbl1
		inner join #TempAnalysisRate tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
								 and tbl1.AnalysisDate = tbl2.AnalysisDate
        where tbl2.VendorDestinationID is NULL

		insert into #TempAnalysisRate
		(
			RefDestinationID,
			VendorDestinationID,
			AnalysisDate,
			Rate ,
			RateTypeID ,
			RatingMethodID
		)
		select RefDestinationID,
			   VendorDestinationID,
			   AnalysisDate,
			   Rate ,
			   RateTypeID ,
			   RatingMethodID
		from #TempAnalysisRateMultipleRM 

End

----------------------------
-- For purpose of debugging
---------------------------

select * from #TempAnalysisRate

----------------------------------------------------------------------
--  Create the table to hold the information regarding the MAX ,
-- MIN Rates and also the ROC rates for the reference destination
----------------------------------------------------------------------

Create Table #TempRateAnalyzeSummary
(
	RefDestinationID int,
	AnalysisDate datetime,
	RateTypeID int,
	RatingMethodID int,
	AnalyzedRate decimal(19,6),
	RateMax decimal(19,6),
	RateMin decimal(19,6),
	RateMinNotNULL decimal(19,6),
	RateROC decimal(19,6),
	DiscrepancyFlag int,
	IsMobileDestination int
)


---------------------------------------------------
-- Records having atleast one vendor destination
-- with not null rate
---------------------------------------------------

insert into #TempRateAnalyzeSummary
(
	RefDestinationID,
	AnalysisDate,
	RateTypeID ,
	RatingMethodID,
	RateMax,
	RateMin,
	RateMinNotNULL,
	RateROC,
	DiscrepancyFlag,
	IsMobileDestination
)
select RefDestinationID,
	   AnalysisDate,
	   RateTypeID,
	   RatingMethodID,
	   Max(Rate),
	   Min(ISNULL(Rate , -9999)),
	   Min(Rate),
	   NULL,
	   0,
	   Case
			when max(tbl2.DestinationTypeID) = 2 then 1
			Else 0
	   End
from #TempAnalysisRate tbl1
     inner join #RefDest tbl2 on tbl1.RefDestinationID = tbl2.DestinationID
Group by RefDestinationID ,AnalysisDate,RateTypeID ,RatingMethodID
having max(Rate) is not null

---------------------------------------------------
-- Records having null rate only for vendor
-- destination(s)
---------------------------------------------------

insert into #TempRateAnalyzeSummary
(
	RefDestinationID,
	AnalysisDate,
	RateTypeID ,
	RatingMethodID,
	RateMax,
	RateMin,
	RateMinNotNULL,
	RateROC,
	DiscrepancyFlag,
	IsMobileDestination
)
select RefDestinationID,
	   AnalysisDate,
	   RateTypeID,
	   RatingMethodID,
	   0,
	   -9999,
	   0,
	   NULL,
	   0,
	   Case
			when max(tbl2.DestinationTypeID) = 2 then 1
			Else 0
	   End
from #TempAnalysisRate tbl1
     inner join #RefDest tbl2 on tbl1.RefDestinationID = tbl2.DestinationID
Group by RefDestinationID ,AnalysisDate,RateTypeID ,RatingMethodID
having max(Rate) is null
	
---------------------------------------------------
-- If Blending Method is set to ROC then we need
-- to find the rates for all the vendor ROC 
-- destinations, as the same would be used in the
-- rate blending process
--------------------------------------------------

if  ( @BlendingProcess = 'BlendingROC' )
Begin

		Create table #ROC 
		(
		    RefDestinationID int,
			AnalysisDate datetime,
			VendorDestinationID int					
		)

		Create table #TempAnalysisRateROC 
		(
		    RefDestinationID int,
			AnalysisDate datetime,
			RatetypeID int,
			RateROC Decimal(19,6)			
		)


		Begin Try

				Insert into #ROC
				Exec SP_BSCheckVendorDestinationIsROC @OfferID

		End Try

		Begin Catch

				set @ErrorMsgStr = ERROR_MESSAGE()
				RaisError('%s' , 16,1 , @ErrorMsgStr)
				GOTO ENDPROCESS

		End Catch


		Insert into #TempAnalysisRateROC 
		(
		    RefDestinationID ,
			AnalysisDate ,
			RateTypeID ,
			RateROC 			
		)
		Select tbl1.RefDestinationID,
		       tbl1.AnalysisDate,
			   tbl1.RateTypeID,
			   Max(rate) as RateROC
		from #TempAnalysisRate tbl1
		inner join #ROC tbl2 
		     on tbl1.RefDestinationID = tbl2.RefDestinationID
			 and tbl1.AnalysisDate = tbl2.AnalysisDate
			 and tbl1.VendorDestinationID = tbl2.VendorDestinationID
		Group by tbl1.RefDestinationID, tbl1.AnalysisDate, tbl1.RateTypeID
		having Max(rate) is not NULL

		-----------------------------------------------
		-- Update the rates in the Temp Sumamry table
		-----------------------------------------------

		Update tbl1
		set tbl1.RateROC = tbl2.RateROC
		from #TempRateAnalyzeSummary tbl1
		inner join #TempAnalysisRateROC tbl2 on tbl1.RefDestinationID =  tbl2.RefDestinationID
		                                     and tbl1.AnalysisDate = tbl2.AnalysisDate
											 and tbl1.RateTypeID = tbl2.RatetypeID

				
End

----------------------------------
-- Printing for debugging purpose
----------------------------------

--select *
--from #TempRateAnalyzeSummary

-----------------------------------------------------------------
-- Calculate the anayzed Rate and populate the Discrepancy Flag
-----------------------------------------------------------------

Update #TempRateAnalyzeSummary
	set AnalyzedRate = 
			Case
				When IsMobileDestination = 1 Then
						 ( ( Convert(Decimal(19,2) , @MobileMin)/100) * ISNULL(RateROC , RateMax) ) +
						 ( ( Convert(Decimal(19,2) , @MobileMax)/100) *  RateMax )
				Else
						 ( ( Convert(Decimal(19,2) , @FixedMin)/100) * ISNULL(RateROC , RateMax) ) +
						 ( ( Convert(Decimal(19,2) , @FixedMax)/100) *  RateMax )
			End,
		DiscrepancyFlag = 
		     Case

				When RateMax < > RateMinNotNULL Then DiscrepancyFlag | 2
				Else DiscrepancyFlag

			 End

------------------------------------------------------------------------------------
-- Check for other Discrepancy like Rating Method mismatch or Missing Dialed Digits
------------------------------------------------------------------------------------

Update #TempRateAnalyzeSummary
	set DiscrepancyFlag =  DiscrepancyFlag|4
where RateMin = -9999

update tbl1
	set DiscrepancyFlag =  DiscrepancyFlag|8
from #TempRateAnalyzeSummary tbl1
inner join ( Select Distinct RefDestinationID ,AnalysisDate from #TempAnalysisRateMultipleRM ) tbl2
     on tbl1.RefDestinationID = tbl2.RefDestinationID
	 and tbl1.AnalysisDate = tbl2.AnalysisDate

update #TempRateAnalyzeSummary
	set AnalyzedRate = 
				Case
						When RateMin = -9999 then @OverRideRate
						Else AnalyzedRate
				End

----------------------------------
-- Printing for debugging purpose
----------------------------------

select 'Debug: Before inserting data into Analysis and Summary table' ,*
from #TempRateAnalyzeSummary

-----------------------------------------------
-- Insert the data into the database schemas
-----------------------------------------------

insert into tb_RateAnalysis
(
	OfferID,
	AnalysisDate,
	RefDestinationID,
	RatingMethodID,
	DiscrepancyFlag,
	ModifiedDate,
	ModifiedByID,
	Flag
)
select @OfferID,
       AnalysisDate,
	   RefDestinationID,
	   Min(RatingMethodID),
	   Max(DiscrepancyFlag),
	   Getdate(),
	   @UserID,
	   0
from #TempRateAnalyzeSummary
group by RefDestinationID , AnalysisDate


insert into tb_RateAnalysisSummary
(
	RateAnalysisID,
	RateTypeID,
	AnalyzedRate,
	RateMax,
	RateMin,
	RateROC,
	ModifiedDate,
	ModifiedByID,
	Flag
)
Select 	tbl2.RateAnalysisID,
		tbl1.RateTypeID,
		tbl1.AnalyzedRate,
		tbl1.RateMax,
		tbl1.RateMin,
		tbl1.RateROC,
		Getdate(),
		@UserID,
		0
from #TempRateAnalyzeSummary tbl1
inner join tb_RateAnalysis tbl2 on tbl1.RefDestinationID = tbl2.RefDestinationID
                           and tbl1.AnalysisDate = tbl2.AnalysisDate
where tbl2.OfferID = @OfferID




ENDPROCESS:

--------------------------------------------------------
-- Drop all the temporary tables created during the process
-----------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAnalysisRate') )
	Drop table #TempAnalysisRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMultipleRatingMethodCount') )
	Drop table #TempMultipleRatingMethodCount

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAnalysisRateMultipleRM') )
	Drop table #TempAnalysisRateMultipleRM

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalyzeSummary') )
	Drop table #TempRateAnalyzeSummary

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#RefDest') )
	Drop table #RefDest

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#ROC') )
	Drop table #ROC

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAnalysisRateROC') )
	Drop table #TempAnalysisRateROC	

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAnalysisRateSingleRM') )	
	Drop table #TempAnalysisRateSingleRM
GO
