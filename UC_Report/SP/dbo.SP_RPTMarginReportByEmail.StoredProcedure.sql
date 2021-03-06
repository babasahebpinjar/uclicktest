USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTMarginReportByEmail]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_RPTMarginReportByEmail]
(
	@StartDate Date = NULL,
	@EndDate Date = NULL
)
As

-- If any of the start or end date is NULL then take the report out
-- for current month 

if ( ( @StartDate is NULL ) or ( @EndDate is NULL ) )
Begin

		set @EndDate = DateAdd(dd , -1 ,convert(date , getdate()))

		set @StartDate = convert(Date,convert(varchar(4) ,Year(@EndDate)) + '-' + 
						 convert(varchar(2) , right('0' + convert(varchar(2) ,Month(@EndDate)) ,2)) + '-' +
						 '01')


End

select @StartDate , @EndDate

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
		where callDate between @StartDate and @EndDate
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
		where callDate between @StartDate and @EndDate
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
		where callDate between @StartDate and @EndDate
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


End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!!! When extracting data for margin report. ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 ,@ErrorMsgStr)
		GOTO ENDPROCESS

End Catch

-----------------------------------------
-- Output the desired results to file
-----------------------------------------

if exists ( select 1 from #TempFinalMarginReport)
Begin

        Declare @HeaderFile varchar(500),
				@RecordFile varchar(500),
				@datestring varchar(100),
			    @bcpCommand varchar(5000),
			    @FileExists int,
			    @res int,
			    @QualifiedTableName varchar(500)

         select @datestring = CONVERT(varchar(50), getdate(), 20)
         select @datestring = REPLACE(@datestring, ':', '')
         select @datestring = REPLACE(@datestring, '-', '')
         select @datestring = ltrim(rtrim(REPLACE(@datestring, ' ', '')))	

         set @HeaderFile = @FileExtractPath + 'HeaderFile_'+ @datestring
         set @RecordFile = @FileExtractPath + 'RecordFile_'+ @datestring
		 set @ExtractFileName = @FileExtractPath + 'TrafficMarginReport'+ + '_' + @datestring + '.csv'

		 -- Build the header file for the QOS Report

		 set @bcpCommand = 'echo INACCOUNT^,OUTACCOUNT^,COUNTRY^,DESTINATION^,SERVICELEVEL^,SEIZED^,ANSWERED^,ASR^,MINUTES^,ALOC^,RPM^,CPM^,REVENUE^,COST^,MARGIN > ' + '"'+ @HeaderFile + '"'

		 Exec master..xp_cmdshell @bcpCommand

		 -- Check if the header file exists or not

		 set @FileExists = 0

		 Exec master..xp_fileexist  @HeaderFile , @FileExists output 

		 if ( @FileExists <> 1 )
		 Begin

			set @ErrorMsgStr = 'Error !!! Header file for the extract : (' + @HeaderFile + ') does not exist'
			Raiserror('%s' , 16 , 1, @ErrorMsgStr)

			set @ExtractFileName = NULL

			GOTO ENDPROCESS	

		 End

		 -- Create the file with all the records

		 set @QualifiedTableName = 'TempTrafficMarginReport_'+@datestring

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
			Exec('Drop table ' + @QualifiedTableName)

         -- Move the data from the temporary table to the qualified table
		 Exec('select * into '+ @QualifiedTableName + ' from #TempFinalMarginReport')

         Set @QualifiedTableName = db_name() + '.dbo.' + @QualifiedTableName

         SET @bcpCommand = 'bcp "SELECT * from ' + @QualifiedTableName + ' order by Margin desc" queryout ' + '"' + ltrim(rtrim(@RecordFile )) + '"' + ' -c -t"," -r"\n" -T -S '+ @@servername
         --print @bcpCommand 

         EXEC master..xp_cmdshell @bcpCommand

		 -- Check if the Record File exists or not

		 set @FileExists = 0

		 Exec master..xp_fileexist  @RecordFile , @FileExists output 

		 if ( @FileExists <> 1 )
		 Begin

			set @ErrorMsgStr = 'Error !!! Record file for the extract : (' + @RecordFile + ') does not exist'
			Raiserror('%s' , 16 , 1, @ErrorMsgStr)

			set @ExtractFileName = NULL

			GOTO ENDPROCESS	

		 End

		 -- Combine the header and record file to build the final extract file

         set @bcpCommand = 'copy '+ '"'+ @HeaderFile + '"' + ' + ' + '"' +  @RecordFile + '"' +' '+ '"'+ @ExtractFileName + '"' + ' /B'
         --print @bcpCommand 
         EXEC master..xp_cmdshell @bcpCommand 

         set @bcpCommand = 'del '+ @HeaderFile
         EXEC master..xp_cmdshell @bcpCommand 

         set @bcpCommand = 'del '+ @RecordFile
         EXEC master..xp_cmdshell @bcpCommand 

		------------------------------------------------------
		-- Check if the Extract file has been created or not
        ------------------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist  @ExtractFileName , @FileExists output 

		if ( @FileExists <> 1 )
		Begin

				set @ErrorMsgStr = 'Error !!! Final extract file : (' + @ExtractFileName + ') does not exist'
				Raiserror('%s' , 16 , 1, @ErrorMsgStr)

				set @ExtractFileName = NULL

				GOTO ENDPROCESS	

		End

End

Else
Begin

		set @ErrorMsgStr = 'Error !!! No data has been extracted for Traffic Margin Report'
		Raiserror('%s' , 16 , 1, @ErrorMsgStr)

		set @ExtractFileName = NULL

		GOTO ENDPROCESS	

End

ENDPROCESS:

-------------------------------------------------------------------
-- Send an alert email to the desired email address regarding the
-- Extract status
-------------------------------------------------------------------
Declare @To varchar(1000),
		@Subject varchar(500),
		@EmailBody varchar(3000),
		@LogFileName varchar(1000) = NULL
	
set @LogFileName = @ExtractFileName
set @Subject = 'Traffic Margin Report - ' + convert(varchar(100) , getdate() , 20)

Declare @ServerName varchar(100),
		@From varchar(300),
		@Passwd varchar(100),
		@Port int,
		@SSL varchar(10),
		@ProxyServerName varchar(100),
		@ProxyServerPort int,
		@LicenseKey varchar(100)


if ( ( @LogFileName is not NULL ) and ( LEN(@LogFileName) = 0))	
		set @LogFileName = NULL
		
if (@LogFileName is NULL )
	set @LogFileName = 'NoFile'	
		
-----------------------------------------------------------------
--In scenarios where Error Description is populated, alert message
--should indicate the exception
-----------------------------------------------------------------

if (@ErrorMsgStr is not NULL)
Begin

		set @EmailBody = '<b> Error!!! encountered while running the Traffic Margin report.</b>' +
						 '<br><br>' + @ErrorMsgStr
		set @To = 'Pushpinder.mahant@ccplglobal.com'
		set @Subject = 'ERROR !!!! Generating Traffic Margin Report - ' + convert(varchar(100) , getdate() , 20)
						 
End

else
Begin

		if ( @LogFileName <> 'NoFile')
		Begin

				set @EmailBody = '<b> Please find the Traffic Margin report file attached for period '+ convert(varchar(10) , @StartDate) + ' to ' + convert(varchar(10) , @EndDate) + '.</b>'
				set @To = 'Pushpinder.mahant@ccplglobal.com,shubhanshu.srivastava@ccplglobal.com,sheril.amilia@axiata.com,azreen@axiata.com,zaihan@axiata.com,mohamad.firdaus@axiata.com,daniel.see@ccplglobal.com,anuar.wahab@axiata.com,mustafa@axiata.com,zoco@axiata.com'

		End

		else
		Begin

				set @EmailBody = '<b> Traffic Margin Report not generated. Please check for exceptions.  </b>'
				set @To = 'Pushpinder.mahant@ccplglobal.com'
				set @Subject = 'ERROR !!! Generating Traffic Margin Report - ' + convert(varchar(100) , getdate() , 20)

		End

End

-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMarginReport') )
		Drop table #TempMarginReport

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRevenue') )
		Drop table #TempRevenue

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCost') )
		Drop table #TempCost

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalMarginReport') )
		Drop table #TempFinalMarginReport

if exists ( select 1 from sysobjects where name = 'TempTrafficMarginReport_'+@datestring and xtype = 'U')
		Exec('Drop table ' + 'TempTrafficMarginReport_'+@datestring)
GO
