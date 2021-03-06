USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_AlertTrafficStatisticsByEmail]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_AlertTrafficStatisticsByEmail]
(
   @Offset int ,
   @EmailList varchar(1000) 
)
As

-- Build the select date  ased on the hourly offset

Declare @SelectDate date

set @SelectDate = convert(date ,DateAdd(hh , (@Offset* -1) , getdate()))

--select @SelectDate as SelectDate

-- Get the Call duration for each Call Date by Call Hour

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDataByDateAndHour') )
		Drop table #TempAllDataByDateAndHour

select CallDate , CallHour , 
       convert(Decimal(19,2) ,sum(convert(float ,CallDuration))/60.0) as Minutes
into #TempAllDataByDateAndHour
from tb_HourlyINCrossOutTrafficMart tbl1
where Datediff(dd , CallDate , @SelectDate) <  60
group by CallDate , CallHour

-- Create a table to add count of number of occurances for each hour
-- in the master table

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountByHour') )
		Drop table #TempCountByHour

select CallHour , Count(*) as NumOfRec
into #TempCountByHour
from #TempAllDataByDateAndHour
Group by CallHour

-- Open a cursor to go through each Call Hour and Calculate the Median value for
-- Traffic Minutes

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMedianMinutesByHour') )
		Drop table #TempMedianMinutesByHour

Create Table #TempMedianMinutesByHour (CallHour int , Minutes Decimal(19,2))

Declare @VarCallHour int,
        @VarNumOfRec int

Declare Get_Median_Val_Per_Hour_Cur Cursor For
Select CallHour , NumOfRec 
from #TempCountByHour
order by CallHour

Open Get_Median_Val_Per_Hour_Cur
Fetch Next From Get_Median_Val_Per_Hour_Cur
Into @VarCallHour, @VarNumOfRec

While @@FETCH_STATUS = 0
Begin
    
	 insert into #TempMedianMinutesByHour
     Select @VarCallHour , Minutes
	 from 
     (
		select ROW_NUMBER() OVER(ORDER BY Minutes ASC) as RecNum ,Minutes
		from #TempAllDataByDateAndHour
		where CallHour = @VarCallHour
	 ) as tbl1
	 Where RecNum = 
	        Case
				When @VarNumOfRec%2 = 0 then @VarNumOfRec/2
				Else (@VarNumOfRec + 1)/2
			End

	Fetch Next From Get_Median_Val_Per_Hour_Cur
	Into @VarCallHour, @VarNumOfRec

End

Close Get_Median_Val_Per_Hour_Cur
Deallocate Get_Median_Val_Per_Hour_Cur

--select *
--from #TempMedianMinutesByHour
--order by Callhour

-- Get all the statistics per hour for the selected date

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllData') )
		Drop table #TempAllData

select tbl1.CallHour , tbl1.ASR , tbl1.ALOC , tbl1.MHT , tbl1.Minutes,
       convert(int ,((tbl1.Minutes - tbl2.Minutes) * 100.0)/tbl2.Minutes) as PercentDeviation
into #TempAllData
from 
(
	Select CallHour, 
		   convert(Decimal(19,2) ,sum(convert(float ,CallDuration))/60.0) as Minutes,
		   convert(int ,(sum(Answered) * 100.0)/sum(Seized)) as ASR,
		   Case
				When sum(Answered) = 0 then 0
				Else convert(Decimal(19,2) ,(sum(convert(float ,CallDuration))/60.0)/sum(Answered))
		   End as ALOC,
		   Case
				When sum(Answered) = 0 then 0
				Else convert(Decimal(19,2) ,(sum(convert(float ,CircuitDuration))/60.0)/sum(Answered))
		   End as MHT
	from tb_HourlyINCrossOutTrafficMart tbl1
	where calldate = @SelectDate
	group by CallHour
) tbl1
inner join #TempMedianMinutesByHour tbl2 on
					tbl1.CallHour = tbl2.CallHour
order by tbl1.Callhour

-- Prepare the final statement for publish in mail

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDataStatement') )
		Drop table #TempAllDataStatement

select
'Call Hour = '+ convert(varchar(2), CallHour) +' ->  '+
'ASR = '+ convert(varchar(2), ASR) +'  '+
'ALOC = ' + convert(varchar(10), ALOC) +'  '+
'MHT = ' + convert(varchar(10), MHT) +'  '+
'Minutes = '+ convert(varchar(20), Minutes) +' '+
Case 
	When PercentDeviation < 0 then ' down by ' + convert(varchar(10), abs(PercentDeviation)) + '%'
	Else ' up by ' + convert(varchar(10), PercentDeviation) + '%'
End as PublishStatement
into #TempAllDataStatement
from #TempAllData
order by Callhour

----------------------------------------------------
-- Send the alert over email to all the concerned
-- users
----------------------------------------------------

if not exists ( select 1 from #TempAllDataStatement )
	GOTO ENDPROCESS

Declare @To varchar(1000),
		@Subject varchar(500),
		@EmailBody varchar(3000),
		@LogFileName varchar(1000) = NULL
	
set @Subject = 'ALERT: Traffic Statistics for -> ' + convert(varchar(10) , @SelectDate , 20) + ' at ' + convert(varchar(20) , getdate() , 20)
			   
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

set @EmailBody = 'Please find the Traffic statistics published below:' +'<br><br>'

Declare @VarAlertMessage varchar(1000)

DECLARE db_cur_Prepare_Message CURSOR FOR
select PublishStatement 
from #TempAllDataStatement

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

set @EmailBody = @EmailBody + '<br>' + 'NOTE: Traffic minutes for each hour compared against last 60 days Median calculated per hour'

set @To = @EmailList

-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName


ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDataByDateAndHour') )
		Drop table #TempAllDataByDateAndHour

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountByHour') )
		Drop table #TempCountByHour

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMedianMinutesByHour') )
		Drop table #TempMedianMinutesByHour

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllData') )
		Drop table #TempAllData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDataStatement') )
		Drop table #TempAllDataStatement
GO
