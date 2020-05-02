USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_AlertZeroASREveryHourByEmail]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_AlertZeroASREveryHourByEmail]
(
	@EmailList varchar(1000)
)
As
------------------------------------------------------------
-- Generate the data for the Alert. Find out all the routes
-- for which the ASR is 0 in Current -2 Call hour
------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempSummary') )
		Drop table #tempSummary

select Summ.CallHour ,Summ.INAccountID ,Summ.OUTAccountID , Summ.CountryID,
	   Summ.Answered , Summ.Seized,
       Summ.Minutes , Summ.ASR , Summ.ALOC , Summ.MHT
into #tempSummary
from
(
	select tbl1.CallHour , tbl1.INAccountID , tbl1.OUTAccountID , tbl2.CountryID ,  
	       sum(tbl1.Answered) as Answered , sum(tbl1.Seized) as Seized ,
		   convert(decimal(19,2) ,sum(CallDuration)/60.0) as Minutes,
		   convert(int ,  (sum(tbl1.Answered) * 100.0)/sum(tbl1.Seized)) as ASR,
		   Case
				When sum(tbl1.Answered) = 0 then 0
				Else convert(decimal(19,2) ,convert(decimal(19,2) ,sum(CallDuration)/60.0)/sum(tbl1.Answered))
		   End as ALOC,
		   Case
				When sum(tbl1.Answered) = 0 then 0
				Else convert(decimal(19,2) ,convert(decimal(19,2) ,sum(CircuitDuration)/60.0)/sum(tbl1.Answered)) 
		   End as MHT
	from tb_HourlyINCrossOutTrafficMart tbl1
	inner join ReferenceServer.UC_Reference.dbo.tb_Destination tbl2 on tbl1.RoutingDestinationID = tbl2.DestinationID
	where tbl1.calldate = convert(date ,getdate())
	group by tbl1.CallHour , tbl1.INAccountID , tbl1.OUTAccountID , tbl2.CountryID
) Summ
inner join
(
	select max(tbl1.CallHour) as MaxCallHour , tbl1.INAccountID , tbl1.OUTAccountID , tbl2.CountryID
	from tb_HourlyINCrossOutTrafficMart tbl1
	inner join ReferenceServer.UC_Reference.dbo.tb_Destination tbl2 on tbl1.RoutingDestinationID = tbl2.DestinationID
	where calldate = convert(date ,getdate())
	Group by tbl1.INAccountID , tbl1.OUTAccountID , tbl2.CountryID
) Summ2 on 
			Summ.INAccountID = Summ2.INAccountID
			and
			Summ.OUTAccountID = Summ2.OUTAccountID
			and
			Summ.CountryID = Summ2.CountryID
			and
			Summ.CallHour = Summ2.MaxCallHour

where summ.ASR = 0
and abs(summ.Callhour - convert(int,substring(convert(varchar(20) , getdate() , 120),12,2))) <= 2


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempSummaryFinal') )
		Drop table #tempSummaryFinal

select 'Route ' + INAccount + ' -> ' + Country + ' -> ' + OutAccount + ' has 0 ASR for ' + 
       convert(varchar(20) , Seized) + ' seized calls at ' + 
	   convert(varchar(2) , CallHour) + ':00 hour' as AlertMessage
into #tempSummaryFinal
from
(
	select Summ.CallHour ,Acc1.AccountAbbrv as INAccount ,Acc2.AccountAbbrv as OUTAccount , Cou.Country,
		   Summ.Answered , Summ.Seized,
		   Summ.Minutes , Summ.ASR , Summ.ALOC , Summ.MHT
	from #tempSummary Summ
	inner join ReferenceServer.UC_Reference.dbo.tb_Account Acc1 on Summ.INAccountID = Acc1.AccountID
	inner join ReferenceServer.UC_Reference.dbo.tb_Account Acc2 on Summ.OUTAccountID = Acc2.AccountID
	inner join ReferenceServer.UC_Reference.dbo.tb_Country Cou on Summ.CountryID = Cou.CountryID
) as TBL1
order by Seized Desc

----------------------------------------------------
-- Send the alert over email to all the concerned
-- users
----------------------------------------------------

if not exists ( select 1 from #tempSummaryFinal )
	GOTO ENDPROCESS

Declare @To varchar(1000),
		@Subject varchar(500),
		@EmailBody varchar(3000),
		@LogFileName varchar(1000) = NULL
	
set @Subject = 'ALERT: Zero ASR for Traffic Routes - ' + convert(varchar(10) , getdate() , 20) + ' at ' +
               substring(convert(varchar(20) , getdate() , 120),12,2) + ':00 Hours'
			   
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


---------------------------------------------------------
-- Open a cursor to prepare the content of the email
---------------------------------------------------------

set @EmailBody = 'Please find the routes for which we are seeing degraded performance:' +'<br><br>'

Declare @VarAlertMessage varchar(1000)

DECLARE db_cur_Prepare_Message CURSOR FOR
select AlertMessage 
from #tempSummaryFinal

OPEN db_cur_Prepare_Message
FETCH NEXT FROM db_cur_Prepare_Message
INTO @VarAlertMessage 

While @@FETCH_STATUS = 0
BEGIN

        set @EmailBody = @EmailBody + '<b>' + @VarAlertMessage + '</b>' + '<br>'

		FETCH NEXT FROM db_cur_Prepare_Message
		INTO @VarAlertMessage   		 

END

CLOSE db_cur_Prepare_Message
DEALLOCATE db_cur_Prepare_Message

set @EmailBody = @EmailBody + '<br>' + 'Appreciate your kind attention to this issue.'

set @To = @EmailList

-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName
	

ENDPROCESS:				    

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempSummary') )
		Drop table #tempSummary

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempSummaryFinal') )
		Drop table #tempSummaryFinal

GO
