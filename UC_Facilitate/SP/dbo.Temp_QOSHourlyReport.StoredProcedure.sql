USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[Temp_QOSHourlyReport]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Temp_QOSHourlyReport] As

Declare @FileExtractPath varchar(1000),
        @ExtractFileName  varchar(1000),
		@ErrorMsgStr varchar(2000) = NULL

set @FileExtractPath = '\\Uclickserver04\g\QOSHourlyReport'

if (right(@FileExtractPath , 1) <> '\')
	set @FileExtractPath = @FileExtractPath + '\'

if exists ( select 1 from sysobjects where name = 'tb_CDRFileDataAnalyzed_QOS' and xtype = 'U')
	Drop table tb_CDRFileDataAnalyzed_QOS
	
-----------------------------------------------------
--- Create a schema to hold the analyzed CDR records
--- for the current date
-----------------------------------------------------
	
select *
into tb_CDRFileDataAnalyzed_QOS
from tb_CDRFileData
where calldate  = convert(date , getdate())


Alter table tb_CDRFileDataAnalyzed_QOS Add RecordID int identity(1,1)
Alter table tb_CDRFileDataAnalyzed_QOS Add INAccount varchar(100)
Alter table tb_CDRFileDataAnalyzed_QOS Add OUTAccount varchar(100)
Alter table tb_CDRFileDataAnalyzed_QOS Add Country varchar(100)
Alter table tb_CDRFileDataAnalyzed_QOS Add Destination varchar(100)
Alter table tb_CDRFileDataAnalyzed_QOS Add CallDurationMinutes Decimal(19,4)

-- Get the IN and OUT Account Details

update tbl1
set INAccount = isnull( tbl2.Account, 'Not Resolved')
from tb_CDRFileDataAnalyzed_QOS tbl1
left join  tb_TrunkToAccountMapping tbl2 on tbl1.INTrunk = tbl2.Trunk

update tbl1
set OUTAccount = isnull( tbl2.Account, 'Not Resolved')
from tb_CDRFileDataAnalyzed_QOS tbl1
left join  tb_TrunkToAccountMapping tbl2 on tbl1.OUTTrunk = tbl2.Trunk

--select * from tb_CDRFileDataAnalyzed_QOS
--where INAccount = 'Not Resolved'
--or OutAccount = 'Not Resolved'

-- For GIC account, there may be Called numbers with 8080 Code, that needs to be removed

update tb_CDRFileDataAnalyzed_QOS
set CalledNumber = 
				Case 
					when substring(CalledNumber ,1,4) = '8080' then substring(callednumber , 5 , len(callednumber))
					Else CalledNumber
				End
Where OutAccount = 'GIC'

-- Populate the Destination based on the Routing Plan and the CalledNumber

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_RoutingBreakout') )
		Drop table #temp_RoutingBreakout

select *
into #temp_RoutingBreakout
from tb_RoutingPlan


Declare @MaxLength int,
        @MaxLengthRef int,
        @Counter int = 1,
		@SQLStr varchar(2000)

select @MaxLength = Max(Len(CalledNumber))
from tb_CDRFileDataAnalyzed_QOS

select @MaxLengthRef = Max(Len(DialedDigit))
from #temp_RoutingBreakout

set @MaxLength = 
    Case
			when @MaxLength <= @MaxLengthRef then @MaxLength
			when @MaxLength > @MaxLengthRef then @MaxLengthRef
	End

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRCalledNumberBreakout') )
		Drop table #temp_CDRCalledNumberBreakout

Begin Try

		Create table #temp_CDRCalledNumberBreakout
		(
			RecordID int,
			CalledNumber varchar(100),
			CallDate datetime,
			Destination varchar(100),
			Country varchar(100)
		)

		while ( @Counter <= @MaxLength )
		Begin

				set @SQLStr = 'Alter table #temp_CDRCalledNumberBreakout add CalledNumber_'+convert(varchar(10) ,@Counter) + ' varchar(100)'
		
				Exec (@SQLStr)

				set @Counter = @Counter + 1

		End

		---------------------------------------------------------------------
		-- Insert records into the temp table for each of the CDR records
		---------------------------------------------------------------------

		insert into #temp_CDRCalledNumberBreakout
		(RecordID , CalledNumber , CallDate)
		Select RecordID , CalledNumber , CallDate
		from tb_CDRFileDataAnalyzed_QOS
		where CalledNumber is not NULL 

		--select *
		--from #temp_CDRCalledNumberBreakout

		set @Counter = 1
		set @SQLStr = 'Update #temp_CDRCalledNumberBreakout set ' + char(10)

		While ( @Counter <= @MaxLength )
		Begin

				set @SQLStr = @SQLStr + ' Callednumber_'+ convert(varchar(100) , @Counter) + 
							  ' = Case ' +
							  ' When len(Callednumber) >= '+ convert(varchar(100) , @Counter) + ' then substring(Callednumber , 1 , ' + convert(varchar(100) , @Counter) + ')' +
							  ' Else NULL' +
							  ' End,' + char(10)				  
					  
				set @Counter = @Counter + 1			  		

		End

		set @SQLStr = substring(@SQLStr , 1 ,  len(@SQLStr) -2 )

		--print @SQLStr

		Exec (@SQLStr)

End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!!! During populating break out table. ' + ERROR_MESSAGE()
		RaisError( '%s' , 16,1 , @ErrorMsgStr)
		GOTO ENDPROCESS

End Catch

--select *
--from #temp_CDRCalledNumberBreakout

-----------------------------------------------------------------------
-- Update the routing DestinationID and routing Country ID in the
-- temporary table
------------------------------------------------------------------------
Begin Try

		set @Counter = @MaxLength

		While ( @Counter > 0 )
		Begin

				set @SQLStr = 'update tbl1 ' + char(10) +
				              ' set tbl1.Destination  = tbl2.Destination ,' + char(10) +
							  ' tbl1.Country = tbl2.Country ' + char(10) +
							  ' from #temp_CDRCalledNumberBreakout tbl1 ' + char(10) +
							  ' inner join #temp_RoutingBreakout tbl2 on ' + char(10) +
							  ' tbl1.CalledNumber_'+ convert(varchar(30) , @Counter) + ' = tbl2.DialedDigit '+ char(10) +
							  ' where tbl1.Destination is NULL' 


				--print @SQLStr
							  
				Exec (@SQLStr)			   
					  
				set @Counter = @Counter - 1			  		

		End

End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!!! When updating the Destination and country details in Temporary table. ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 ,@ErrorMsgStr)
		GOTO ENDPROCESS

End Catch

--select top 1000 *
--from #temp_CDRCalledNumberBreakout

---------------------------------------------------------------------
-- Update tb_CDRFileDataAnalyzed_QOS with the Destination and Country details
----------------------------------------------------------------------

update tbl1
set tbl1.Destination = tbl2.Destination,
    tbl1.Country = tbl2.Country
from tb_CDRFileDataAnalyzed_QOS tbl1
inner join #temp_CDRCalledNumberBreakout tbl2
     on tbl1.RecordID = tbl2.RecordID

update tb_CDRFileDataAnalyzed_QOS
set Destination = 'Not Resolved',
    Country = 'Not Resolved'
where Destination is NULL


-----------------------------------------------------------
-- Populate the CallDurationMinutes based on Call Duration
-----------------------------------------------------------

update tb_CDRFileDataAnalyzed_QOS
set CallDurationMinutes = convert(Decimal(19,4) , CallDuration/60.0)

------------------------------------------------------
-- Generate the QOS report based on the analyzed data
------------------------------------------------------

if exists ( select 1 from sysobjects where name = 'tb_QOSbyHour' and xtype = 'U')
	Drop table tb_QOSbyHour

Select INAccount , OutAccount , Country , Destination, CallHour,
       count(*) as Seized,
	   sum( Case When CallDuration > 0 then 1 Else 0 End) as Answered,
	   convert(int ,(sum( Case When CallDuration > 0 then 1 Else 0 End) * 100.0)/Count(*)) as ASR,
	   convert(decimal(19,2) ,sum(CallDurationMinutes)) as Minutes,
	   Case
			When sum( Case When CallDuration > 0 then 1 Else 0 End) = 0 then 0
			Else convert(decimal(19,2) ,sum(CallDurationMinutes)/sum( Case When CallDuration > 0 then 1 Else 0 End)) 
	   End as ALOC
into tb_QOSbyHour
From tb_CDRFileDataAnalyzed_QOS
group by INAccount , OutAccount , Country , Destination, CallHour
--order by Callhour , INAccount , OutAccount , Country , Destination 

-----------------------------------------
-- Output the desired results to file
-----------------------------------------

if exists ( select 1 from tb_QOSbyHour)
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
		 set @ExtractFileName = @FileExtractPath + 'QOSHourlyReport'+ + '_' + @datestring + '.csv'

		 -- Build the header file for the QOS Report

		 set @bcpCommand = 'echo INACCOUNT^,OUTACCOUNT^,COUNTRY^,DESTINATION^,CALLHOUR^,SEIZED^,ANSWERED^,ASR^,Minutes^,ALOC > ' + '"'+ @HeaderFile + '"'

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

         Set @QualifiedTableName = db_name() + '.dbo.tb_QOSbyHour'

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
	
Declare @ExecFileName varchar(500),
		@cmd varchar(8000)
		
-----------------------------------------------------------
-- Get the outgoing SMTP settings from the database
-----------------------------------------------------------

Select 	@ServerName = servername,
        @From = AccountName,
        @Passwd = password,
        @Port = PortNumber,
		@SSL = 
		     Case
					When SSL = 1 then 'true'
					When SSL = 0 then 'false'
			 End,
        @ProxyServerName = ProxyServerName,
		@ProxyServerPort = ProxyServerPort
from UC_Bridge.dbo.tblOutgoingMailSettings
where status = 1

Select @LicenseKey = LicenseKey
from UC_Bridge.dbo.tblIncomingMailSettings
where status = 1
        		
-------------------------------------------------------------------
-- Get the name of executable file for sending email alert via SMTP
-------------------------------------------------------------------

select @ExecFileName = ConfigValue
from UC_Bridge.dbo.tb_config
where configname = 'SendAlertViaSMTP'

---------------------------------------------------------------------
-- Attach the Customer name as suffix to the email subject, so that
-- system knows for whom the alert has been generated
---------------------------------------------------------------------

Declare @CustomerName varchar(200)

Select @CustomerName = name
from UC_Bridge.dbo.tblClientMaster
where ID = 1

set @CustomerName = isnull(@CustomerName, '')

set @Subject = @CustomerName + ' : ' + @Subject

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
				set @To = 'Pushpinder.mahant@ccplglobal.com,sheril.amilia@axiata.com,azreen@axiata.com,zaihan@axiata.com,mohamad.firdaus@axiata.com,daniel.see@ccplglobal.com'

		End

		else
		Begin

				set @EmailBody = '<b> QOS Hourly Report not generated. Please check for exceptions.  </b>'
				set @To = 'Pushpinder.mahant@ccplglobal.com'
				set @Subject = 'ERROR !!! Generating QOS Hourly Report - ' + convert(varchar(100) , getdate() , 20)

		End

End



-------------------------------------------------------
-- Get the default folder for the Perl executable
-------------------------------------------------------

Declare @PerlExecutable varchar(500)

select @PerlExecutable = ConfigValue
from UC_Bridge.dbo.tb_config
where configname = 'PerlExecutable'

set @cmd = 'ECHO ? && '+'"' + @ExecFileName + '"' + ' '  +
           '"' + + @ServerName + '"' + ' '  +
		   '"' + @From + '"' + ' ' + 
		   '"' + @Passwd + '"' +  ' ' +
		   '"' + @SSL + '"' +  ' ' +
		   '"' + convert(varchar(20) , @Port) + '"' + ' '+
		   '"' + ISNULL(@ProxyServerName , '') + '"' + ' ' +
		   '"' + ISNULL(convert(varchar(10) ,@ProxyServerPort) , '') + '"' + ' ' +
		   '"' + @LicenseKey + '"' + ' ' +
		   '"' + @To + '"' + ' ' +
		   '"' + @Subject + '"' + ' ' +
		   '"' + @EmailBody + '"' + ' ' +
		   '"' + @LogFileName + '"' + ' '

		 					 					 
--select @ExecFileName as ExecFile,
--	   @ServerName as ServerName,
--	   @From as 'From',
--	   @Passwd as Passwd,
--	   @Port as 'Port',
--	   @LicenseKey as LicenseKey,
--	   @To as 'To',
--	   @Subject as 'Subject',
--	   @EmailBody as 'EmailBody',
--	   @LogFileName as 'LogFileName'

Exec master..xp_cmdshell @cmd

-- Delete all the temporary objects created for processing

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRCalledNumberBreakout') )
		Drop table #temp_CDRCalledNumberBreakout

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_RoutingBreakout') )
		Drop table #temp_RoutingBreakout

if exists ( select 1 from sysobjects where name = 'tb_CDRFileDataAnalyzed_QOS' and xtype = 'U')
	Drop table tb_CDRFileDataAnalyzed_QOS

if exists ( select 1 from sysobjects where name = 'tb_QOSbyHour' and xtype = 'U')
	Drop table tb_QOSbyHour






GO
