USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTGenerateLCRReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTGenerateLCRReport]
(
	@ReportRunDate datetime,
	@MaxReportCount int,
	@ServiceLevelID int,
	@CallTypeID int,
	@CountryIDList nvarchar(max),
	@DestinationIDList nvarchar(max),
	@AccountIDList nvarchar(max),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @AllCountryFlag int = 0,
		@AllDestinationFlag int = 0,
		@AllAccountFlag int = 0,
		@SQLStr1 nvarchar(max),
		@SQLStr2 nvarchar(max),
		@SQLStr3 nvarchar(max),
		@SQLStr  nvarchar(max)

Declare @INServiceLevelID int ,
        @OutServiceLevelID int

set @INServiceLevelID = isnull(@ServiceLevelID, 0)

--------------------------------------------------------------
-- In case the Call Type is 0 then set it to NULL to
-- indicate all Call types
--------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL

Select @OutServiceLevelID = OUTServiceLevelID
from REFERENCESERVER.UC_Reference.dbo.tb_INAndOUTServiceLevelMapping
where INServiceLevelID = @INServiceLevelID
and @ReportRunDate between BeginDate and ISNULL(EndDate , @ReportRunDate)

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
and ( tbl1.Attribute6ID = @OutServiceLevelID or tbl1.Attribute6ID is NULL)
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
	where BeginDate <= @ReportRunDate
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
where @ReportRunDate between rt.BeginDate and ISNULL(rt.EndDate , @ReportRunDate )
and @ReportRunDate between dest.BeginDate and ISNULL(dest.EndDate , @ReportRunDate )
and rp.DirectionId = 2 -- Outbound

--select 'Debug' ,*
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
	AccountID int,
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
			GOTO PROCESSACCOUNT
				  
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

PROCESSACCOUNT:

-----------------------------------------------------------------
-- Create table for list of selected Accounts from the parameter
-- passed
-----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
		Drop table #TempAccountIDTable

Create Table #TempAccountIDTable (AccountID varchar(100) )


insert into #TempAccountIDTable
select * from FN_ParseValueList ( @AccountIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from #TempAccountIDTable where ISNUMERIC(AccountID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain a non numeric value'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

------------------------------------------------------
-- Check if the All the Accounts have been selected 
------------------------------------------------------

if exists (
				select 1 
				from #TempAccountIDTable 
				where AccountID = 0
			)
Begin

            set @AllAccountFlag = 1
			GOTO GENERATEREPORT
				  
End
		
-----------------------------------------------------------------
-- Check to ensure that all the Account IDs passed are valid values
-----------------------------------------------------------------
		
if exists ( 
				select 1 
				from #TempAccountIDTable 
				where AccountID not in
				(
					Select AccountID
					from ReferenceServer.UC_Reference.dbo.tb_Account
					where flag & 1 <> 1
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain value(s) which are not valid or do not exist'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End



GENERATEREPORT:

--------------------------------------------------------
-- Declare the essential work variables for processing
--------------------------------------------------------

Declare @VarAgreementID int,
        @VarRatePlanID int,
		@VarCallTypeID int,
		@VarCountryID int,
		@VarCommercialTrunkID int,
		@VarAccountID int

DECLARE db_Get_LCR_Rates CURSOR FOR  
select AgreementiD , RatePlanID , CalltypeID ,CountryID , CommercialTrunkID
From #TempRatingScenario
order by RatingScenarioTypeID

OPEN db_Get_LCR_Rates   
FETCH NEXT FROM db_Get_LCR_Rates
INTO @VarAgreementID , @VarRatePlanID , @VarCallTypeID ,@VarCountryID, @VarCommercialTrunkID 



WHILE @@FETCH_STATUS = 0   
BEGIN

        select @VarAccountID = AccountID 
		from ReferenceServer.UC_Reference.dbo.tb_Trunk 
		where TrunkID = @VarCommercialTrunkID

        insert into #TempRoutingRateTable
		(	
		     AccountID,
			 CommercialTrunkID,
			 CalltypeID,
	         CountryID,
			 DestinationID,
			 Rate,
			 BeginDate,
			 EndDate
		)
		Select @VarAccountID, @VarCommercialTrunkID , tbl1.CallTypeID , tbl1.CountryID,
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
		

		FETCH NEXT FROM db_Get_LCR_Rates
		INTO @VarAgreementID , @VarRatePlanID , @VarCallTypeID ,@VarCountryID, @VarCommercialTrunkID 
 
END   

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running Least Costing Route Report (Data Preparation Step).' + ERROR_MESSAGE()
		set @ResultFlag = 1

		CLOSE db_Get_LCR_Rates  
		DEALLOCATE db_Get_LCR_Rates

		GOTO ENDPROCESS

End Catch

CLOSE db_Get_LCR_Rates  
DEALLOCATE db_Get_LCR_Rates

--select 'Debug' , *
--from #TempRoutingRateTable

Begin Try

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMasterData') )
				Drop table #TempMasterData      
				
		Create table #TempMasterData
		(
		    DestinationID int,
			Destination varchar(100),
			CallTypeID int,
			CallType varchar(60),
			Rate Decimal(19,6),
			RateEntity varchar(100),
			RateEntityID int
		)	  

		set @SQLStr1 = 'select Distinct tbl1.DestinationID , tbl2.Destination ,tbl1.CallTypeID , tbl3.Calltype , Rate, ' + char(10) +
			           'tbl5.AccountAbbrv + '' / '' + tbl4.Trunk , tbl1.CommercialTrunkID' + char(10)

        set @SQLStr2 = 'from #TempRoutingRateTable tbl1 ' + char(10) +
		                'inner join REFERENCESERVER.UC_Reference.dbo.tb_Destination tbl2 on tbl1.DestinationID = tbl2.DestinationID and tbl2.numberplanid = -1 ' + char(10) +
		                'inner join REFERENCESERVER.UC_Reference.dbo.tb_Calltype tbl3 on tbl1.CallTypeId = tbl3.CalltypeID' + char(10) +
						'inner join REFERENCESERVER.UC_Reference.dbo.tb_Trunk tbl4 on tbl1.CommercialTrunkID = tbl4.TrunkID' + char(10) +
						'inner join REFERENCESERVER.UC_Reference.dbo.tb_Account tbl5 on tbl4.AccountID = tbl5.AccountID' + char(10) +
		                Case
						    When @AllAccountFlag = 1 then ''
							Else ' inner join #TempAccountIDTable tbl6 on tbl1.AccountID = tbl6.AccountID ' + char(10)
						End +
		                Case
						    When  @AllCountryFlag = 1 then ''
							Else ' inner join #TempCountryIDTable tbl7 on tbl1.CountryID = tbl7.CountryID ' + char(10)
						End +
		                Case
						    When  @AllDestinationFlag  = 1 then ''
							Else ' inner join #TempDestinationIDTable tbl8 on tbl1.DestinationID = tbl8.DestinationID ' + char(10)
						End + char(10)


		set @SQLStr3 = 'Where tbl5.Flag & 32 <> 32 ' -- Only Active Accounts

        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		print @SQLStr

		insert into #TempMasterData
		Exec (@SQLStr)

		--select *
		--from #TempMasterData

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running Least Costing Route Report (Master Data Step).' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--------------------------------------------------------------
-- Check out the real traffic profile for the last 7 days 
-- from the report date to find out the actual traffic
-- routing
---------------------------------------------------------------

Declare @TrafficBeginDate datetime,
        @TrafficEndDate datetime

set @TrafficEndDate = @ReportRunDate
set @TrafficBeginDate = dateAdd(dd , -7 , @TrafficEndDate)

Begin Try

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrafficData') )
				Drop table #TempTrafficData

        select Distinct tbl1.RoutingDestinationID , tbl1.CallTypeID , tbl1.CommercialTrunkID
		into #TempTrafficData
		from tb_DailyINUnionOutFinancial tbl1
		inner join
		(
			select Distinct DestinationID , CallTypeID , RateEntityID
			from #TempMasterData
		) tbl2 on 
		       tbl1.RoutingDestinationID = tbl2.DestinationID
			   and tbl1.CallTypeID = tbl2.CallTypeID
			   and tbl1.CommercialTrunkID = tbl2.RateEntityID
		where CallDate between @TrafficBeginDate and @TrafficEndDate
		and tbl1.directionID = 2 -- Outbound
		and tbl1.INServiceLevelID = @INServiceLevelID
		and tbl1.OUTServiceLevelID = @OutServiceLevelID
		and tbl1.CallDuration > 0 -- Only pick up those commercial trunks where traffic has been terminated successfully

		----------------------------------------------------------------
		-- Update in the Master data table to indicate those Commercial
		-- trunks, which have been used for terminating the traffic
		----------------------------------------------------------------

		update tbl1
		set RateEntity = RateEntity + ' (Selected)'
		from #TempMasterData tbl1
		inner join #TempTrafficData tbl2 on
		         tbl1.DestinationID = tbl2.RoutingDestinationID
				 and
				 tbl1.CallTypeID = tbl2.CallTypeID
				 and
				 tbl1.RateEntityID = tbl2.CommercialTrunkID


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running Least Costing Route Report (Populate live traffic Step).' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--------------------------------------------------------------
-- Format the master data set content as per the requirement 
-- of the report
--------------------------------------------------------------

Begin Try

		------------------------------------------------------------
		-- Get the list of all the different Routing Destinations
		------------------------------------------------------------

		Select Distinct Destination , DestinationID , CallType ,CallTypeID
		into #TempDistinctRoutingEntity
		from #TempMasterData

		--------------------------------------------------------------------------
		-- Get the Maximum report count for which the report needs to be run
		-------------------------------------------------------------------------- 


		if ( ( isnull(@MaxReportCount, 0 ) = 0 ) )
		Begin
	
				Select @MaxReportCount = Max(RecordCount)
				from
				(
					select DestinationID , CallTypeID ,  Count(*) as RecordCount
					from #TempMasterData
					group by DestinationID , CallTypeID
				) tbl1


		End

		-----------------------------------------------------------------
		-- Create the Temporary Report data table for storing the results
		-----------------------------------------------------------------

		Declare @TableName Varchar(200)  = 'tbl_TempLCRReport_' + Replace(Replace(Replace(Replace(convert(varchar(30) , getdate() , 121) , '-' , '') , ':' , '') , '.' , ''), ' ', ''),
		        @Counter int

		set @SQLStr = 'Create table ' + @TableName + ' ( ' + Char(10) +
					  'DestinationID int,' + Char(10) +
					  'Destination varchar(100),' + char(10) +
					  'CallTypeID int,' + Char(10) +
					  'CallType varchar(100),' + Char(10)

		set @Counter = 1

		While ( @Counter <= @MaxReportCount )
		Begin

				set @SQLStr = @SQLStr + 'RateEntity_'+ convert(varchar(100) , @Counter) + ' varchar(100),'+	Char(10)		
				set @SQLStr = @SQLStr + 'LCR_'+ convert(varchar(100) , @Counter) + ' Decimal(19,6),'+	Char(10)

				set @Counter =  @Counter + 1

		End

		set @SQLStr = substring(@SQLStr , 1 , len(@SQLStr) -2) + ')'

		--print @SQLStr

		Exec(@SQLStr)

		---------------------------------------------------------
		-- Insert the distinct Destination and Call Type into the
		-- Report table
		----------------------------------------------------------

		set @SQLStr = 'Insert into ' + @TableName + char(10) +
					  '(DestinationID , Destination ,CallTypeID , CallType)'+ char(10) +
					  'Select DestinationID , Destination ,CallTypeID , CallType ' + char(10) +
					  'from #TempDistinctRoutingEntity'

		--print @SQLStr

		Exec (@SQLStr)

	    ----------------------------------------------------------------
		-- Open a cursor to traverse through all the Routing Entities
		-- and populate the report for them
		----------------------------------------------------------------

		Declare @VarDestination varchar(100),
		        @VarDestinationID int,
				@VarCallType varchar(60),
				@VarRateEntity varchar(100), 
				@VarRate Decimal(19,6)

		------------------------------------------------
		-- Create temporary table to hold the rates
		-- for each Routing Entity
		------------------------------------------------

	
		Create table #TempRoutingEntityRate
		(

			RateEntityID int,
			RateEntity varchar(200),
			Rate Decimal(19,6)	
		)


		DECLARE db_Get_LCR_Cur CURSOR FOR  
		select Destination , DestinationID , CallType , CallTypeID
		From #TempDistinctRoutingEntity


		OPEN db_Get_LCR_Cur   
		FETCH NEXT FROM db_Get_LCR_Cur
		INTO @VarDestination , @VarDestinationID , @VarCallType, @VarCallTypeID 

		WHILE @@FETCH_STATUS = 0   
		BEGIN  

				Delete from #TempRoutingEntityRate

				Insert into #TempRoutingEntityRate (RateEntityID ,RateEntity , Rate)
				Select RateEntityID , RateEntity , Rate
				From #TempMasterData
				where DestinationID = @VarDestinationID
				and CallTypeID = @VarCallTypeID

				Set @Counter = 1

				set @SQLStr = 'Update '  + @TableName + ' set '+ Char(10) 

				DECLARE db_Get_LCR_Per_RE_Cur CURSOR FOR  
				select RateEntity , Rate
				From #TempRoutingEntityRate
				order by Rate

				OPEN db_Get_LCR_Per_RE_Cur   
				FETCH NEXT FROM db_Get_LCR_Per_RE_Cur
				INTO @VarRateEntity , @VarRate 

				WHILE @@FETCH_STATUS = 0   
				BEGIN
		
						if ( @Counter > @MaxReportCount )
						Begin

								GOTO PROCESSNEXTREC

						End	
				
				
						set @SQLStr = @SQLStr +
									  ' RateEntity_' + convert(varchar(10) , @Counter) + ' = ''' + @VarRateEntity + '''' + ',' + Char(10)+
									  ' LCR_' + convert(varchar(10) , @Counter) + ' = ''' + convert(varchar(20) , @VarRate) + '''' + ',' + Char(10)


						set @Counter = @Counter + 1

		 
						FETCH NEXT FROM db_Get_LCR_Per_RE_Cur
						INTO @VarRateEntity , @VarRate 

				END

		PROCESSNEXTREC:

		        set @SQLStr = substring(@SQLStr , 1 , len(@SQLStr) - 2) + Char(10) +
							' where DestinationID = ' + convert(varchar(20) , @VarDestinationID) + Char(10)+ 
							' and CallTypeID = ' + convert(varchar(20) , @VarCallTypeID)

				print @SQLStr

				Exec(@SQLStr)

				CLOSE db_Get_LCR_Per_RE_Cur  
				DEALLOCATE db_Get_LCR_Per_RE_Cur

				set @SQLStr = '' -- Empty the string after update

				FETCH NEXT FROM db_Get_LCR_Cur
				INTO @VarDestination , @VarDestinationID , @VarCallType, @VarCallTypeID 
 
		END   

		CLOSE db_Get_LCR_Cur  
		DEALLOCATE db_Get_LCR_Cur

		------------------------------------------------------------
		-- Print records depending on the MAX Report Count paramter
		------------------------------------------------------------

		set @Counter = 1

		set @SQLStr = 'Select DestinationID ,Destination, CalltypeID ,CallType,'

		While ( @Counter <= @MaxReportCount )
		Begin

				set @SQLStr =  @SQLStr + 'RateEntity_'+ convert(varchar(10) , @Counter) + ',LCR_'+ convert(varchar(10) , @Counter)+','
				set @Counter = @Counter + 1		

		End

		set @SQLStr = substring (@SQLStr , 1 , len(@SQLStr) -1)

		set @SQLStr  =  @SQLStr + ' from ' + @TableName +
						' order by Destination , CallType'


		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running Least Costing Route Report (Data Formatting Step).' + ERROR_MESSAGE()
		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRoutingEntityRate') )
		Drop table #TempRoutingEntityRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDistinctRoutingEntity') )
		Drop table #TempDistinctRoutingEntity

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMasterData') )
		Drop table #TempMasterData

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

if exists (select 1 from sysobjects where xtype = 'U' and name = @TableName )
		Exec('Drop table ' + @TableName)

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrafficData') )
		Drop table #TempTrafficData
GO
