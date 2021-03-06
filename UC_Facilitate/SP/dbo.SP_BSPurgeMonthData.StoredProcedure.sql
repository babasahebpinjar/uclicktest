USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPurgeMonthData]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSPurgeMonthData]
(
   @ArchiveMonth int ,
   @ArchiveYear int 
)
As

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRFiles') )
	Drop table #tempCDRFiles

select cdrFilename , CDRFileID
into #tempCDRFiles
from tb_MedCorrelateStatistics
where filestatus = 'Upload Completed'
and Month(convert(date , substring(cdrfilename , 12,6))) = @ArchiveMonth
and Year(convert(date , substring(cdrfilename , 12,6))) = @ArchiveYear


-------------------------------------------------------------------------
-- Store all the record ids which need to be deleted into temporary table
------------------------------------------------------------------------

--if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempDeleteRecordIDs') )
--	Drop table #tempDeleteRecordIDs

--select tbl1.RecordID
--into #tempDeleteRecordIDs
--from tb_MedCorrelateMapBER tbl1
--inner join #tempCDRFiles tbl2 on tbl1.I_CDRFileID = tbl2.CDRFileID
--inner join #tempCDRFiles tbl3 on tbl1.O_CDRFileID = tbl2.CDRFileID
--inner join #tempCDRFiles tbl4 on tbl1.Z_CDRFileID = tbl4.CDRFileID


---------------------------------------------------------------------
-- Delete all the correlated CDR records from the MAP BER table
---------------------------------------------------------------------

delete tbl1
from tb_MedCorrelateMapBER tbl1
inner join #tempCDRFiles tbl2 on tbl1.I_CDRFileID = tbl2.CDRFileID
inner join #tempCDRFiles tbl3 on tbl1.O_CDRFileID = tbl2.CDRFileID
inner join #tempCDRFiles tbl4 on tbl1.Z_CDRFileID = tbl4.CDRFileID


----------------------------------------------------------------
-- Delete records from the I , O and Z tables for all the files
----------------------------------------------------------------

delete tbl1
from tb_ITypeRecords tbl1
inner join #tempCDRFiles tbl2 on tbl1.CDRFileID = tbl2.CDRFileID

delete tbl1
from tb_OTypeRecords tbl1
inner join #tempCDRFiles tbl2 on tbl1.CDRFileID = tbl2.CDRFileID

delete tbl1
from tb_ZTypeRecords tbl1
inner join #tempCDRFiles tbl2 on tbl1.CDRFileID = tbl2.CDRFileID


-----------------------------------------------------------------------
-- Delete all the CDR file statistics from the CORRELATE statistics table
-----------------------------------------------------------------------

Delete tbl1
from tb_MedCorrelateStatistics tbl1
inner join #tempCDRFiles tbl2 on tbl1.CDRFileID = tbl2.CDRFileID


---------------------------------------------------------------------------
-- Delete all the CDR file statistics from the CONVERTER Statistic table
---------------------------------------------------------------------------

delete tbl1
from tb_MedConverterStatistics tbl1
inner join #tempCDRFiles tbl2 on tbl1.CDRFileName = tbl2.CDRFileName


---------------------------------------------------------------------------
-- Delete all the CDR file statistics from the COLLECTOR Statistic table
---------------------------------------------------------------------------

delete tbl1
from tb_MedCollectorStatistics tbl1
inner join #tempCDRFiles tbl2 on tbl1.CDRFileName = tbl2.CDRFileName

---------------------------------------------------------------------------
-- Drop table containing all the processed records for purging month
---------------------------------------------------------------------------

Declare @AllProcessedRecordsSchemaName varchar(100)

set @AllProcessedRecordsSchemaName = 'Temp_AllProcessedRecords_' + convert(varchar(4) , @ArchiveYear) + right('0' + convert(varchar(2) , @ArchiveMonth),2)

--select @AllProcessedRecordsSchemaName

if exists ( select 1 from sysobjects where name = @AllProcessedRecordsSchemaName and xtype = 'U' )
Begin

		Exec('Drop table ' + @AllProcessedRecordsSchemaName)

End

-------------------------------------------------------------------------
-- Delete all the records which have been purged from the Output table
-------------------------------------------------------------------------

Delete
from Temp_AllOutputRecords 
where month(calldate) = @ArchiveMonth
and year(CallDate) = @ArchiveYear


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRFiles') )
	Drop table #tempCDRFiles

--if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempDeleteRecordIDs') )
--	Drop table #tempDeleteRecordIDs
GO
