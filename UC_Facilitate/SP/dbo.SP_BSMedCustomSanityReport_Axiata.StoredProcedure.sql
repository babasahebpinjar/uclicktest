USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCustomSanityReport_Axiata]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedCustomSanityReport_Axiata]
(
	@StartDate date,
	@EndDate date,
	@ExtractFolder varchar(500)
)
As

--set @StartDate = '2018-08-01'
--set @EndDate = '2018-08-31'
--set @ExtractFolder = '\\Uclickserver04\g\MediationSanityReport\Monthly'

-- Construct the name of the file for the sanity report

Declare @FileName varchar(500),
        @ExtractFilePath varchar(1000)

set @FileName = 'MediationSanityReport_' + replace( convert(varchar(10), @StartDate , 120), '-' , '') + '_To_' +
				 replace( convert(varchar(10), @EndDate , 120), '-' , '') + '_' +
				 replace(replace(replace(convert(varchar(20) , getdate() , 120), ' ', ''), '-' , ''), ':' , '')

--select @FileName

if (right(@ExtractFolder , 1) <> '\')
	set @ExtractFolder = @ExtractFolder + '\'

set @ExtractFilePath = @ExtractFolder + @FileName

Declare @RunningDate date

set @RunningDate =  @StartDate

-- Create a temporary table containing all the date ranges timestamp

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateTimestamps') )	
	Drop table #TempDateTimestamps

create table #TempDateTimestamps (DateOffset varchar(10))

While (@RunningDate <= @EndDate)
Begin

		insert into #TempDateTimestamps values (replace(convert(varchar(10), @RunningDate, 120), '-' , ''))
		set @RunningDate = DateAdd(dd ,1 , @RunningDate)

End

-- Get the statistics from the Collector module to indicate the number of files collected

Declare @TotalFilesCollected int

select @TotalFilesCollected = count(*)
from tb_MedCollectorStatistics tbl1
where tbl1.FileStatus = 'File Exported'
and reverse(substring(reverse(CDRFilename), 13 , 8)) in
(
	select DateOffset from #TempDateTimestamps
)

--select @TotalFilesCollected as TotalFilesCollected

-- Get the statistics from the Converter module
Declare @TotalFilesConverted int,
        @TotalRecordsConverted int

select @TotalFilesConverted = count(*),
       @TotalRecordsConverted = sum(TotalOutputRecords)
from tb_MedConverterStatistics tbl1
where tbl1.FileStatus = 'Completed' -- All successfully converted files
and reverse(substring(reverse(CDRFilename), 13 , 8)) in
(
	select DateOffset from #TempDateTimestamps
)

--select @TotalFilesConverted as TotalFilesConverted,
--       @TotalRecordsConverted as TotalRecordsConverted

-- Get all the statistics for the Formatter module

Declare @TotalRecords int,
		@TotalProcessedRecords int,
		@TotalDuplicateRecords int,
		@TotalRejectRecords int,
		@TotalMinutes Decimal(19,2),
		@TotalProcessedMinutes Decimal(19,2),
		@TotalDuplicateMinutes Decimal(19,2),
		@TotalRejectMinutes Decimal(19,2),
		@TotalFilesFormatted int

Select @TotalFilesFormatted  = count(*) ,
	   @TotalRecords =  sum(TotalRecords),
	   @TotalProcessedRecords = sum(TotalProcessedRecords),
	   @TotalDuplicateRecords = sum(TotalDuplicateRecords),
	   @TotalRejectRecords = sum(TotalRejectRecords),
	   @TotalMinutes = sum(TotalMinutes),
	   @TotalProcessedMinutes = sum(TotalProcessedMinutes),
	   @TotalDuplicateMinutes = sum(TotalDuplicateMinutes),
	   @TotalRejectMinutes = sum(TotalRejectMinutes)
from tb_MedFormatterStatistics tbl1
where tbl1.FileStatus = 'Completed' -- All successfully converted files
and reverse(substring(reverse(CDRFilename), 13 , 8)) in
(
	select DateOffset from #TempDateTimestamps
)

--select @TotalFilesFormatted as TotalFilesFormatted ,
--	   @TotalRecords as TotalRecords,
--	   @TotalProcessedRecords as TotalProcessedRecords,
--	   @TotalDuplicateRecords as TotalDuplicateRecords,
--	   @TotalRejectRecords as TotalRejectRecords,
--	   @TotalMinutes as TotalMinutes,
--	   @TotalProcessedMinutes as TotalProcessedMinutes,
--	   @TotalDuplicateMinutes as TotalDuplicateMinutes,
--	   @TotalRejectMinutes as TotalRejectMinutes

-- Get the statisrtics from the uClick system for the CDR Files
Declare @TotalFilesUploaded int,
        @TotalCDRUploaded int

select @TotalFilesUploaded = count(*) , 
       @TotalCDRUploaded = sum(Measure1)
from Referenceserver.UC_Operations.dbo.tb_ObjectInstance tbl1
inner join Referenceserver.UC_Operations.dbo.tb_Object tbl3 on tbl1.ObjectID = tbl3.ObjectID
inner join Referenceserver.UC_Operations.dbo.tb_ObjectInstanceTaskLog tbl2 on tbl1.ObjectInstanceID = tbl2.ObjectInstanceID
where tbl3.ObjectTypeID = 100
and tbl1.statusid = 10012 -- All Successfully processed files
and tbl2.Taskname = 'Upload RAW CDR File'
and reverse(substring(reverse(tbl1.ObjectInstance), 17 , 8)) in
(
	select DateOffset from #TempDateTimestamps
)

--select @TotalFilesUploaded as TotalFilesUploaded,
--       @TotalCDRUploaded as TotalCDRUploaded

-- Print the information in the Extract File

Declare @MessageStr varchar(2000)

set @MessageStr = '----------------------------------------------------------------------------------'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '                            MEDIATION SANITY REPORT                               '
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '----------------------------------------------------------------------------------'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '                       Period From ' + convert(varchar(10) , @StartDate) + ' To ' + convert(varchar(10) , @EndDate)
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '----------------------------------------------------------------------------------'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'COLLECTOR'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'Total number of CDR Files Collected from SBC : ' + convert(varchar(20) , isnull(@TotalFilesCollected,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

Exec SP_LogMessage NULL , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'CONVERTER'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'Total number of CDR Files Parsed            : ' + convert(varchar(20) , isnull(@TotalFilesConverted,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'Total number of CDR Records Parsed          : ' + convert(varchar(20) , isnull(@TotalRecordsConverted,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

Exec SP_LogMessage NULL , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'FORMATTER'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'Total number of CDR Files Formatted         : ' + convert(varchar(20) , isnull(@TotalFilesFormatted,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'Total number of CDR records Formatted       : ' + convert(varchar(20) , isnull(@TotalRecords,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath


Exec SP_LogMessage NULL , @ExtractFilePath

set @MessageStr = '            ======================='
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '            CDR RECORD STATISTICS              '
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '            ========================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '            Processed   : ' + convert(varchar(20) , isnull(@TotalProcessedRecords ,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath
set @MessageStr = '            Duplicate   : ' + convert(varchar(20) , isnull(@TotalDuplicateRecords ,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath
set @MessageStr = '            Reject      : ' + convert(varchar(20) , isnull(@TotalRejectRecords ,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

Exec SP_LogMessage NULL , @ExtractFilePath

set @MessageStr = 'Total number of Minutes                     : ' + convert(varchar(20) , isnull(@TotalMinutes,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

Exec SP_LogMessage NULL , @ExtractFilePath

set @MessageStr = '            ======================='
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '            CDR MINUTES STATISTICS              '
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '            ========================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '            Processed   : ' + convert(varchar(20) , isnull(@TotalProcessedMinutes ,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath
set @MessageStr = '            Duplicate   : ' + convert(varchar(20) , isnull(@TotalDuplicateMinutes ,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath
set @MessageStr = '            Reject      : ' + convert(varchar(20) , isnull(@TotalRejectMinutes ,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

Exec SP_LogMessage NULL , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'uCLICK RATING'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '================'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'Total number of CDR Files Uploaded          : ' + convert(varchar(20) , isnull(@TotalFilesUploaded,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = 'Total number of CDR records Rated           : ' + convert(varchar(20) , isnull(@TotalCDRUploaded,0))
Exec SP_LogMessage @MessageStr , @ExtractFilePath

set @MessageStr = '----------------------------------------------------------------------------------'
Exec SP_LogMessage @MessageStr , @ExtractFilePath

-- Send the mediation Sanity Report Out via email

-------------------------------------------------------------------
-- Send an alert email to the desired email address regarding the
-- Extract status
-------------------------------------------------------------------
Declare @To varchar(1000),
		@Subject varchar(500),
		@EmailBody varchar(3000),
		@LogFileName varchar(1000) = NULL

select @To = ConfigValue
from ReferenceServer.UC_Admin.dbo.tb_Config
where configname = 'MediationSanityEmailList'
and AccessScopeID = -9 -- uClick Facilitate parameter

if ( @To is NULL )
	set @To = 'Pushpinder.mahant@ccplglobal.com' -- Default email address
	
set @LogFileName = @ExtractFilePath
set @Subject = 'Mediation Sanity Report For ' + convert(varchar(100) , @StartDate , 20) + ' To ' + convert(varchar(100) , @EndDate , 20)

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


if ( @LogFileName <> 'NoFile')
Begin

		set @EmailBody = '<b> Mediation Sanity report for the above mentioned period has been generated. </b>'

End

else
Begin

		set @EmailBody = '<b> Mediation SanityReport not generated. Please check for exceptions.  </b>'
		set @Subject = 'ERROR !!! Generating Mediation Sanity Report For - ' +  + convert(varchar(100) , @StartDate , 20) + ' To ' + convert(varchar(100) , @EndDate , 20)

End


-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateTimestamps') )	
	Drop table #TempDateTimestamps
GO
