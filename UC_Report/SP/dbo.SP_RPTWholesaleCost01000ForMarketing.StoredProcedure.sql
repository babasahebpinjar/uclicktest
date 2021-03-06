USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTWholesaleCost01000ForMarketing]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTWholesaleCost01000ForMarketing]
(
	@SelectDate datetime,
	@CallTypeID int,
	@CountryIDList nvarchar(max),
	@DestinationIDList nvarchar(max),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @AllCountryFlag int = 0,
		@AllDestinationFlag int = 0,
		@SQLStr1 nvarchar(max),
		@SQLStr2 nvarchar(max),
		@SQLStr3 nvarchar(max),
		@SQLStr  nvarchar(max)

Declare @INServiceLevelID int = 2019, -- Hard coded to 01000 because its specifically for this service level
        @OutServiceLevelID int

--------------------------------------------------------------
-- In case the Call Type is 0 then set it to NULL to
-- indicate all Call types
--------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL

Select @OutServiceLevelID = OUTServiceLevelID
from REFERENCESERVER.UC_Reference.dbo.tb_INAndOUTServiceLevelMapping
where INServiceLevelID = @INServiceLevelID
and @SelectDate between BeginDate and ISNULL(EndDate , @SelectDate)

-------------------------------------------------------------
-- Select all the essential Rating Scenarios and Settlements
-- for the IN Service Level
-------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRatingScenario') )
		Drop table #TempRatingScenario

select tbl1.Attribute1ID as AgreementID,
       tbl1.Attribute2ID as CommercialTrunkID,
	   tbl1.Attribute3ID as CalltypeID,
	   tbl1.Attribute4ID as CountryID,
	   tbl1.Attribute6ID as OutServiceLevelID,
	   tbl2.RatePlanID,
	   tbl1.RatingScenarioTypeID
into #TempRatingScenario
from REFERENCESERVER.UC_Reference.dbo.tb_RatingScenario tbl1
inner join REFERENCESERVER.UC_Reference.dbo.tb_RatingSettlement tbl2 on tbl1.RatingScenarioID = tbl2.RatingScenarioID
where tbl1.RatingScenarioTypeID in (-1,-3)
and tbl1.attribute5ID = 2 -- Outbound
and tbl1.Attribute6ID = @OutServiceLevelID
and tbl2.RatePlanID <> -2 -- Not Applicable
and tbl1.Attribute3ID = isnull(@CallTypeID , tbl1.Attribute3ID)

--select *
--from #TempRatingScenario


----------------------------------------------------------------
-- Get the exchange rates as per the report run date to display
-- all the rates in system currency
----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempExchangeRate') )
		Drop table #TempExchangeRate

Select tbl1.*
into #TempExchangeRate
from REFERENCESERVER.UC_Reference.dbo.tb_Exchange tbl1
inner join
(
	select currencyID , max(BeginDate) as BeginDate
	from REFERENCESERVER.UC_Reference.dbo.tb_Exchange
	where BeginDate <= @SelectDate
	group by currencyID
) tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
        and
		  tbl1.BeginDate = tbl2.BeginDate

--select *
--from #TempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRate') )
		Drop table #TempRate

select rt.rateID ,rt.DestinationID , rt.CalltypeID , rt.RatePlanID , rt.BeginDate , rt.EndDate
into #TempRate
from REFERENCESERVER.UC_Reference.dbo.tb_Rate rt
inner join
(
	Select distinct CalltypeID ,RatePlanID
	from #TempRatingScenario
) rp on rt.RatePlanID = rp.RatePlanID
     and rt.CalltypeID = rp.CalltypeID


--select *
--from #TempRate


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateDetail') )
		Drop table #TempRateDetail

select rtd.rateid , max(rate) as Rate
into #TempRateDetail
from REFERENCESERVER.UC_Reference.dbo.tb_RateDetail rtd
inner join #TempRate rt on rtd.rateid = rt.rateid
where rtd.rate <> 99.99 -- Remove all analyzed rates which are having Dial Code Gap
group by rtd.rateid

--select *
--from #TempRateDetail

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempReferenceRateMaster') )
		Drop table #TempReferenceRateMaster


select Dest.DestinationID , Dest.Destination , 
       cp.CalltypeID , cp.Calltype, 
       rp.RatePlanID , rp.RatePlan,
	   dest.CountryID,
       convert(Decimal(19,6) ,rtd.rate/Exch.ExchangeRate) as rate,
	   rt.BeginDate,
	   rt.EndDate
into #TempReferenceRateMaster
from #TempRate rt
inner join REFERENCESERVER.UC_Reference.dbo.tb_RatePlan rp on rt.RatePlanID = rp.rateplanID
inner join #tempRateDetail rtd on rt.RateID = rtd.RateID
inner join REFERENCESERVER.UC_Reference.dbo.tb_Destination dest on rt.DestinationID = dest.DestinationID
                                                               and dest.numberplanid = -1 --  Routing Destinations
inner join #TempExchangeRate Exch on rp.CurrencyID = Exch.CurrencyID
inner join REFERENCESERVER.UC_Reference.dbo.tb_Calltype cp on rt.CallTypeID =  cp.CallTypeID
where @SelectDate between rt.BeginDate and ISNULL(rt.EndDate , @SelectDate )
and @SelectDate between dest.BeginDate and ISNULL(dest.EndDate , @SelectDate )
and rp.DirectionId = 2 -- Outbound

--select *
--from #TempReferenceRateMaster

--------------------------------------------------------------------
-- Open a cursor and loop through the rating scenarios in the order 
-- Country Specific and then Generic
--------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRoutingRateTable') )
		Drop table #TempRoutingRateTable

create table #TempRoutingRateTable
(
	CommercialTrunkID int,
	CalltypeID int,
	CountryID int,
	DestinationID int,
	Rate Decimal(19,6),
	BeginDate datetime,
	EndDate datetime
)

Begin Try

-----------------------------------------------------------------
-- Create table for list of all selected Countries from the 
-- parameter passed
-----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable


Create table #TempCountryIDTable (CountryID varchar(100) )
		
insert into #TempCountryIDTable
select * from FN_ParseValueList ( @CountryIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from #TempCountryIDTable where ISNUMERIC(CountryID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain a non numeric value'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

------------------------------------------------------
-- Check if the All the countries have been selected 
------------------------------------------------------

if exists (
				select 1 
				from #TempCountryIDTable 
				where CountryID = 0
			)
Begin

            set @AllCountryFlag = 1
			GOTO PROCESSDESTINATION
				  
End
		
-----------------------------------------------------------------
-- Check to ensure that all the Country IDs passed are valid values
-----------------------------------------------------------------
		
if exists ( 
				select 1 
				from #TempCountryIDTable 
				where CountryID not in
				(
					Select CountryID
					from ReferenceServer.UC_Reference.dbo.tb_country
					where flag & 1 <> 1
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End 

PROCESSDESTINATION:

-----------------------------------------------------------------
-- Create table for list of all selected Destinations from the 
-- parameter passed
-----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
		Drop table #TempDestinationIDTable

Create table  #TempDestinationIDTable (DestinationID varchar(100) )


insert into #TempDestinationIDTable
select * from FN_ParseValueList ( @DestinationIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from #TempDestinationIDTable where ISNUMERIC(DestinationID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------
-- Check if the All the Detinations have been selected 
------------------------------------------------------

if exists (
				select 1 
				from #TempDestinationIDTable 
				where DEstinationID = 0
			)
Begin

			set @AllDestinationFlag = 1
			GOTO GENERATEREPORT
				  
End
		
--------------------------------------------------------------------------
-- Check to ensure that all the Destinations passed are valid values
--------------------------------------------------------------------------
		
if exists ( 
				select 1 
				from #TempDestinationIDTable 
				where DestinationID not in
				(
					Select DestinationID
					from ReferenceServer.UC_Reference.dbo.tb_Destination
					where numberplanID = -1 -- All Routing Destinations
					and flag & 1 <> 1
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain value(s) which are not valid or do not exist'
	set @ResultFlag = 1
	Return 1

End 


GENERATEREPORT:

--------------------------------------------------------
-- Declare the essential work variables for processing
--------------------------------------------------------

Declare @VarAgreementID int,
        @VarRatePlanID int,
		@VarCallTypeID int,
		@VarCountryID int,
		@VarCommercialTrunkID int

DECLARE db_Get_LCR_Cur CURSOR FOR  
select AgreementiD , RatePlanID , CalltypeID ,CountryID , CommercialTrunkID
From #TempRatingScenario
order by RatingScenarioTypeID

OPEN db_Get_LCR_Cur   
FETCH NEXT FROM db_Get_LCR_Cur
INTO @VarAgreementID , @VarRatePlanID , @VarCallTypeID ,@VarCountryID, @VarCommercialTrunkID 



WHILE @@FETCH_STATUS = 0   
BEGIN

        insert into #TempRoutingRateTable
		(	
		     CommercialTrunkID,
			 CalltypeID,
	         CountryID,
			 DestinationID,
			 Rate,
			 BeginDate,
			 EndDate
		)
		Select @VarCommercialTrunkID , tbl1.CallTypeID , tbl1.CountryID,
		       tbl1.DestinationID , tbl1.Rate , tbl1.BeginDate , tbl1.EndDate
		from 
		(
		  select *
		  from #TempReferenceRateMaster
		  where CalltypeID = @VarCallTypeID
		  and CountryID = isnull(@VarCountryID , CountryID)
		  and RatePlanID = @VarRatePlanID

		) tbl1
		left join 
		(
		    select *
		    from #TempRoutingRateTable
			where CalltypeID = @VarCallTypeID
			and CommercialTrunkID = @VarCommercialTrunkID
						
		) tbl2 on
			tbl1.CalltypeID = tbl2.CallTypeID
			and 
			tbl1.DestinationID = tbl2.DestinationID
		Where tbl2.DestinationID is NULL
		

		FETCH NEXT FROM db_Get_LCR_Cur
		INTO @VarAgreementID , @VarRatePlanID , @VarCallTypeID ,@VarCountryID, @VarCommercialTrunkID 
 
END   

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running Wholesale Cost 01000 Marketing Report.' + ERROR_MESSAGE()
		set @ResultFlag = 1

		CLOSE db_Get_LCR_Cur  
		DEALLOCATE db_Get_LCR_Cur

		GOTO ENDPROCESS

End Catch

CLOSE db_Get_LCR_Cur  
DEALLOCATE db_Get_LCR_Cur

--select *
--from #TempRoutingRateTable

Begin Try

		------------------------------------------------------
		-- Get the exchange rate for IDR currency from the
		-- Exchange rate table
		-------------------------------------------------------

		Declare @ExchangeRateIDR Money

		select @ExchangeRateIDR = ExchangeRate
		from #TempExchangeRate
		where currencyID = 1011 -- IDR currency

		Alter table #TempRoutingRateTable Add RateInIDR Decimal(19,2)

		update #TempRoutingRateTable
		set RateInIDR = convert(decimal(19,2) ,Rate * @ExchangeRateIDR)

		set @SQLStr1 = 'select tbl1.DestinationID , tbl2.Destination ,tbl1.CallTypeID , tbl3.Calltype , max(Rate) as Rate, ' + char(10) +
			           'max(RateInIDR) as RateInIDR' + char(10)

        set @SQLStr2 = 'from #TempRoutingRateTable tbl1 ' + char(10) +
		                'inner join REFERENCESERVER.UC_Reference.dbo.tb_Destination tbl2 on tbl1.DestinationID = tbl2.DestinationID and tbl2.numberplanid = -1 ' + char(10) +
		                'inner join REFERENCESERVER.UC_Reference.dbo.tb_Calltype tbl3 on tbl1.CallTypeId = tbl3.CalltypeID' + char(10) +
		                Case
						    When  @AllCountryFlag = 1 then ''
							Else ' inner join #TempCountryIDTable tbl5 on tbl1.CountryID = tbl5.CountryID ' + char(10)
						End +
		                Case
						    When  @AllDestinationFlag  = 1 then ''
							Else ' inner join #TempDestinationIDTable tbl4 on tbl1.DestinationID = tbl4.DestinationID ' + char(10)
						End + char(10)


		set @SQLStr3 = 'group by tbl1.DestinationID , tbl2.Destination ,tbl1.CallTypeID , tbl3.Calltype' + char(10) +
		               'order by tbl2.Destination , tbl3.Calltype'

        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		Exec (@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running Wholesale Cost 01000 Marketing Report.' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRoutingRateTable') )
		Drop table #TempRoutingRateTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempReferenceRateMaster') )
		Drop table #TempReferenceRateMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRatingScenario') )
		Drop table #TempRatingScenario

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempExchangeRate') )
		Drop table #TempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
		Drop table #TempDestinationIDTable
GO
