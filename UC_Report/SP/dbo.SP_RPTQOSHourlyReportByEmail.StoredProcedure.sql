USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTQOSHourlyReportByEmail]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE Procedure [dbo].[SP_RPTQOSHourlyReportByEmail]
 (
	@EmailList varchar(1000)
 )

 As
 
 Declare @FileExtractPath varchar(1000),
        @ExtractFileName  varchar(1000),
		@ErrorMsgStr varchar(2000) = NULL

set @FileExtractPath = '\\Uclickserver04\g\QOSHourlyReport'

if (right(@FileExtractPath , 1) <> '\')
	set @FileExtractPath = @FileExtractPath + '\'

---------------------------------------------------------
-- Get information from the Destination Grouping
---------------------------------------------------------
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationGroup') )	
	Drop table #TempDestinationGroup

select tbl1.EntityGroup , tbl2.EntityGroupMemberID , tbl2.InstanceID , tbl2.EntityGroupID
into #TempDestinationGroup
from ReferenceServer.UC_Reference.dbo.tb_EntityGroup tbl1
inner join ReferenceServer.UC_Reference.dbo.tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
where EntityGroupTypeID = -2 -- Destination Grouping
 
------------------------------------------------------
-- Generate the QOS report based on the analyzed data
------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempQOSByHour') )	
	Drop table #TempQOSByHour

 Select tbl2.AccountAbbrv as INAccount,
		tbl3.AccountAbbrv as OUTAccount,
		tbl5.Country as Country,
		Case
			When tbl6.EntityGroup is not NULL then tbl6.EntityGroup
			Else tbl4.Destination
		End as Destination,
		tbl1.CallHour,
		sum(tbl1.Seized) as Seized,
		sum(tbl1.Answered) as Answered,
		convert(int ,(convert(Decimal(19,2) , sum(tbl1.Answered)) * 100.0 )/sum(tbl1.Seized)) as ASR ,
		convert(Decimal(19,2),sum(CallDuration/60.0)) Minutes ,
		Case
			 When sum(tbl1.Answered) = 0 then 0
			 Else convert(decimal(19,2) ,(convert(Decimal(19,2),sum((CircuitDuration)/60.0)))/sum(tbl1.Answered))
		End as MHT ,
		Case
			 When sum(tbl1.Answered) = 0 then 0
			 Else convert(decimal(19,2) ,(convert(Decimal(19,2),sum(CallDuration/60.0)))/sum(tbl1.Answered))
		End as ALOC
into #TempQOSByHour
from tb_HourlyINCrossOutTrafficMart tbl1
inner join ReferenceServer.UC_Reference.dbo.tb_Account tbl2 on tbl1.INAccountID = tbl2.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_Account tbl3 on tbl1.OUTAccountID = tbl3.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_Destination tbl4 on tbl1.RoutingDestinationID = tbl4.DestinationID
inner join ReferenceServer.UC_Reference.dbo.tb_Country tbl5 on tbl4.CountryID = tbl5.CountryID
left join #TempDestinationGroup tbl6 on tbl4.DestinationID = tbl6.InstanceID
Where calldate = convert(date ,getdate())
group by tbl2.AccountAbbrv,
		tbl3.AccountAbbrv ,
		tbl5.Country ,
		Case
			When tbl6.EntityGroup is not NULL then tbl6.EntityGroup
			Else tbl4.Destination
		End,
		tbl1.CallHour


-----------------------------------------
-- Output the desired results to file
-----------------------------------------

if exists ( select 1 from #TempQOSByHour)
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
         select @datestring = ltrim(rtrim(REPLACE(@datestring, ' ', ''))) + replace(convert(varchar(20) ,RAND()) , '.' , '')

         set @HeaderFile = @FileExtractPath + 'HeaderFile_'+ @datestring
         set @RecordFile = @FileExtractPath + 'RecordFile_'+ @datestring
		 set @ExtractFileName = @FileExtractPath + 'QOSHourlyReport'+ + '_' + @datestring + '.csv'

		 -- Build the header file for the QOS Report

		 set @bcpCommand = 'echo INACCOUNT^,OUTACCOUNT^,COUNTRY^,DESTINATION^,CALLHOUR^,SEIZED^,ANSWERED^,ASR^,MINUTES^,MHT^,ALOC > ' + '"'+ @HeaderFile + '"'

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

		 set @QualifiedTableName = 'TempQOSByHour_' + @datestring

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
			Exec('Drop table ' + @QualifiedTableName)

		 Exec('select * into '+ @QualifiedTableName + ' from #TempQOSByHour')

         Set @QualifiedTableName = db_name() + '.dbo.' + @QualifiedTableName

         SET @bcpCommand = 'bcp "SELECT * from ' + @QualifiedTableName + ' order by Country ,INAccount , OutAccount , CallHour" queryout ' + '"' + ltrim(rtrim(@RecordFile )) + '"' + ' -c -t"," -r"\n" -T -S '+ @@servername
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

		set @ErrorMsgStr = 'Error !!! No data has been extracted for hourly QOS reporting'
		Raiserror('%s' , 16 , 1, @ErrorMsgStr)

		set @ExtractFileName = NULL

		GOTO ENDPROCESS	

End

-------------------------------------------------------------------
-- Send an alert email to the desired email address regarding the
-- Extract status
-------------------------------------------------------------------
Declare @To varchar(1000),
		@Subject varchar(500),
		@EmailBody varchar(3000),
		@LogFileName varchar(1000) = NULL
	
set @LogFileName = @ExtractFileName
set @Subject = 'QOS Hourly Report - ' + convert(varchar(100) , getdate() , 20)

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

		set @EmailBody = '<b> Error!!! encountered while running the hourly QOS report.</b>' +
						 '<br><br>' + @ErrorMsgStr
		set @To = 'Pushpinder.mahant@ccplglobal.com'
		set @Subject = 'ERROR !!!! Generating QOS Hourly Report - ' + convert(varchar(100) , getdate() , 20)
						 
End

else
Begin

		if ( @LogFileName <> 'NoFile')
		Begin

				set @EmailBody = '<b> Please find the QOS hourly report file attached.  </b>'
				--set @To = 'Pushpinder.mahant@ccplglobal.com,sheril.amilia@axiata.com,azreen@axiata.com,zaihan@axiata.com,mohamad.firdaus@axiata.com,daniel.see@ccplglobal.com'
				set @To = @EmailList
		End

		else
		Begin

				set @EmailBody = '<b> QOS Hourly Report not generated. Please check for exceptions.  </b>'
				set @To = 'Pushpinder.mahant@ccplglobal.com'
				set @Subject = 'ERROR !!! Generating QOS Hourly Report - ' + convert(varchar(100) , getdate() , 20)

		End

End

-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempQOSByHour') )	
	Drop table #TempQOSByHour

if exists ( select 1 from sysobjects where name = 'TempQOSByHour_' + @datestring and xtype = 'U')
	Exec('Drop table ' + 'TempQOSByHour_' + @datestring)

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationGroup') )	
	Drop table #TempDestinationGroup
GO
