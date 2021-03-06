USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTMarginReportPrepaid]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_RPTMarginReportPrepaid]
(
	@ReportMonth int
)
As

Declare @StartDate Date ,
		@EndDate Date 


-- Define the path where the margin report needs to be extracted

Declare @FileExtractPath varchar(1000),
        @ExtractFileName  varchar(1000),
		@ErrorMsgStr varchar(2000) = NULL

set @FileExtractPath = '\\Uclickserver06\g\Uclick_Product_Suite\MarginReport'

if (right(@FileExtractPath , 1) <> '\')
	set @FileExtractPath = @FileExtractPath + '\'

Begin Try

		-- Get all the IN CROSS OUT data for the specified dates

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMarginReport') )
				Drop table #TempMarginReport

		select INAccountID , OUTAccountID , RoutingDestinationID , countryID, INCommercialTrunkID , OUTCommercialTrunkID,
			   sum(Answered) as Answered, 
			   sum(Seized) as Seized,
			  convert(Decimal(19,2) ,sum(CallDuration/60.0)) as CallDuration,
			  INServiceLevelID
		into #TempMarginReport
		from tb_DailyINCrossOutTrafficMart tbl1
		inner join ReferenceServer.UC_Reference.dbo.tb_Destination tbl2 on tbl1.RoutingDestinationID = tbl2.DestinationID
		where convert(int ,replace(convert(varchar(7) ,callDate , 120), '-' , '')) = @ReportMonth
		group by INAccountID , OUTAccountID , RoutingDestinationID , CountryID, INCommercialTrunkID , OUTCommercialTrunkID,
		         INServiceLevelID

		--select *
		--from #TempMarginReport

		-- Add Columns for RPM, CPM, Revenue, Cost and Margin to the Report table
		Alter table #TempMarginReport add RPM Decimal(19,4)
		Alter table #TempMarginReport add CPM Decimal(19,4)
		Alter table #TempMarginReport add Margin Decimal(19,2)
		Alter table #TempMarginReport add Revenue Decimal(19,2)
		Alter table #TempMarginReport add Cost Decimal(19,2)


		-- Get all the Revenue for each Routing Destination

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRevenue') )
				Drop table #TempRevenue

		select AccountID , RoutingDestinationID , CommercialTrunkID,
			   convert(Decimal(19,2) ,sum(CallDuration/60.0)) as CallDuration ,
			   convert(Decimal(19,2) ,sum(RoundedCallDuration/60.0)) as RoundedCallDuration,
			   Case
					When convert(Decimal(19,4) ,sum(RoundedCallDuration/60.0)) = 0 then 0
					Else convert(Decimal(19,4),convert(Decimal(19,4) ,sum(Amount))/convert(Decimal(19,4) ,sum(RoundedCallDuration/60.0)))
			   End  as Rate,
			   sum(Answered) as Answered ,
			   sum(Seized) as Seized ,
			   convert(Decimal(19,2) ,sum(Amount)) as Amount,
			   INServiceLevelID
		into #TempRevenue
		from tb_DailyINUnionOutFinancial
		where convert(int ,replace(convert(varchar(7) ,callDate , 120), '-' , '')) = @ReportMonth
		and DirectionID = 1
		group by AccountID , RoutingDestinationID , CommercialTrunkID , INServiceLevelID


		-- Update the Revenue Rate for each INAccount and Routing destination

		update tbl1
		set RPM = tbl2.Rate,
			Revenue = convert(Decimal(19,2) ,tbl2.Rate * tbl1.CallDuration)
		from #TempMarginReport tbl1
		inner join #TempRevenue tbl2 on tbl1.INAccountID = tbl2.AccountID 
									   and 
										tbl1.RoutingDestinationID = tbl2.RoutingDestinationID
									   and
									    tbl1.INCommercialTrunkID = tbl2.CommercialTrunkID
									   and
										tbl1.INServiceLevelID = tbl2.INServiceLevelID


		-- Get all the Cost for each Routing Destination

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCost') )
				Drop table #TempCost


		select AccountID , RoutingDestinationID , CommercialTrunkID,
			   convert(Decimal(19,2) ,sum(CallDuration/60.0)) as CallDuration ,
			   convert(Decimal(19,2) ,sum(RoundedCallDuration/60.0)) as RoundedCallDuration,
			   Case
					When convert(Decimal(19,4) ,sum(RoundedCallDuration/60.0)) = 0 then 0
					Else convert(Decimal(19,4),convert(Decimal(19,4) ,sum(Amount))/convert(Decimal(19,4) ,sum(RoundedCallDuration/60.0)))
			   End  as Rate,
			   sum(Answered) as Answered ,
			   sum(Seized) as Seized ,
			   convert(Decimal(19,2) ,sum(Amount)) as Amount,
			   INServiceLevelID
		into #TempCost
		from tb_DailyINUnionOutFinancial
		where convert(int ,replace(convert(varchar(7) ,callDate , 120), '-' , '')) = @ReportMonth
		and DirectionID = 2
		group by AccountID , RoutingDestinationID , CommercialTrunkID , INServiceLevelID


		-- Update the Cost Rate for each INAccount and Routing destination

		update tbl1
		set CPM = tbl2.Rate,
			Cost = convert(Decimal(19,2) ,tbl2.Rate * tbl1.CallDuration)
		from #TempMarginReport tbl1
		inner join #TempCost tbl2 on tbl1.OUTAccountID = tbl2.AccountID 
									   and 
										tbl1.RoutingDestinationID = tbl2.RoutingDestinationID
									   and
									    tbl1.OUTCOmmercialTrunkID = tbl2.CommercialTrunkID
									   and
										tbl1.INServiceLevelID = tbl2.INServiceLevelID


		-- Calculate the Margin based on the Revenue and Cost

		update #TempMarginReport
		set Margin  = isnull(Revenue , 0) - isnull(Cost , 0)


		-- Extract the final Result

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalMarginReport') )
				Drop table #TempFinalMarginReport

		select tbl2.AccountAbbrv + ' \ ' + tbl6.Trunk as INAccount , 
		       tbl3.AccountAbbrv  + ' \ ' + tbl7.Trunk as OUTAccount, 
			   tbl4.Country , tbl5.Destination, tbl8.ServiceLevel,
			   Seized, Answered,
			   convert(Decimal(19,2) ,round((Answered*100.0)/Seized,0)) as ASR,
			   CallDuration as Minutes,
			   Case
					When Answered = 0 then 0
					Else convert(Decimal(19,2) ,CallDuration/Answered)
			   End as ALOC,
			   RPM,
			   CPM,
			   Revenue,
			   Cost,
			   Margin
		into #TempFinalMarginReport
		from #TempMarginReport tbl1
		left join Referenceserver.UC_Reference.dbo.tb_Account tbl2 on tbl1.INAccountID = tbl2.AccountID
		left join Referenceserver.UC_Reference.dbo.tb_Account tbl3 on tbl1.OUTAccountID = tbl3.AccountID
		inner join Referenceserver.UC_Reference.dbo.tb_Country tbl4 on tbl1.CountryID = tbl4.CountryID
		inner join Referenceserver.UC_Reference.dbo.tb_Destination tbl5 on tbl1.RoutingDestinationID = tbl5.DestinationID
		inner join Referenceserver.UC_Reference.dbo.tb_Trunk tbl6 on tbl1.INCommercialTrunkID = tbl6.TrunkID
		inner join Referenceserver.UC_Reference.dbo.tb_Trunk tbl7 on tbl1.OUTCommercialTrunkID = tbl7.TrunkID
		inner join Referenceserver.UC_Reference.dbo.tb_ServiceLevel tbl8 on tbl1.INServiceLevelID = tbl8.SErviceLevelID
		where CallDuration > 0 -- Dont want records where no Call Duration is there
		-- Add the logic to only pick up traffic for Prepaid accounts in the month
		and (
				tbl1.INAccountID in (
				                      Select AccountID 
				                      from ReferenceServer.UC_Reference.dbo.tb_AccountMode
									  where Period = @ReportMonth
									  and AccountModeTypeID = -2
									)
				or
				tbl1.OUTAccountID in (
				                      Select AccountID 
				                      from ReferenceServer.UC_Reference.dbo.tb_AccountMode
									  where Period = @ReportMonth
									  and AccountModeTypeID = -2
									)
			)

End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!!! When extracting data for margin report. ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 ,@ErrorMsgStr)
		GOTO ENDPROCESS

End Catch

Select * from #TempFinalMarginReport


ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMarginReport') )
		Drop table #TempMarginReport

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRevenue') )
		Drop table #TempRevenue

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCost') )
		Drop table #TempCost

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalMarginReport') )
		Drop table #TempFinalMarginReport

GO
