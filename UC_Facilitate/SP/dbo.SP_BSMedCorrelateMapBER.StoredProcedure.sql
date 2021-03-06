USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCorrelateMapBER]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedCorrelateMapBER]
(
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(1000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------------
-- Start the mapping process for all the O_TYPE CDR records which have the
-- USED IN CORRELATION flag set to 0
---------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Create a tenmporary table to hold the complete mapping of I,O and Z CDR
-- records
-----------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedCorrelateMapBER') )
	Drop table #temp_MedCorrelateMapBER

select CorrelationID , I_CDRFileID , O_CDRFileID , Z_CDRFileID, I_BERID, O_BERID, Z_BERID
into #temp_MedCorrelateMapBER
from tb_MedCorrelateMapBER
where 1 = 2

-------------------------------------------------------------------------------
-- Create a temporary table to hold all the O_Type Records which have the 
-- USED IN CORRELATION flag as 0
-------------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_OTypeRecords') )
	Drop table #temp_OTypeRecords

select *
into #temp_OTypeRecords
from tb_OTypeRecords
where UsedInCorrelationFlag = 0 -- pick up those records which are pending correlation

-------------------------------------------------
-- Map with the I and the Z records to create the
-- complete CDR record
-------------------------------------------------

insert into #temp_MedCorrelateMapBER
( CorrelationID ,I_CDRFileID , O_CDRFileID , Z_CDRFileID, I_BERID, O_BERID, Z_BERID )
Select tbl1.CorrelationID,
       tbl2.CDRFileID ,
       tbl1.CDRFileID ,
	   tbl3.CDRFileID ,
	   tbl2.BERID ,
	   tbl1.BERID ,
	   tbl3.BERID 
from #temp_OTypeRecords tbl1
inner join tb_ITypeRecords tbl2 on tbl1.CorrelationID = tbl2.CorrelationID
                   and abs(DateDiff(ss ,tbl1.CorrelationDate , tbl2.CorrelationDate)) <= 86400 -- One Day
inner join tb_ZTypeRecords tbl3 on tbl1.CorrelationID = tbl3.CorrelationID
				   and abs(DateDiff(ss ,tbl1.CorrelationDate , tbl3.CorrelationDate)) <= 86400 -- One Day
where tbl1.UsedInCorrelationFlag = 0


-----------------------------------------------------------
-- Double check to see that a O Record has not gone ahead 
-- and correlated to multiple I or Z records
----------------------------------------------------------
if exists ( Select 1 from
            (
				select count(*) as TotalRecords , O_CDRFileID , O_BERID 
				from #temp_MedCorrelateMapBER
				group by O_CDRFileID , O_BERID
				having count(1) > 1
			) as tbl1
		 )
Begin

    set @ErrorDescription = 'ERROR: O Records have been found that Correlate to multiple I or Z records'
  
    set @ErrorDescription = 'SP_BSCorrelateMapBER : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	set @ResultFlag = 1

    ---------------------------------------------------------
	-- Print these Records into the log file for review
	---------------------------------------------------------

	Exec SP_BSMedCorrelatePublishExceptionRecords @AbsoluteLogFilePath

	GOTO ENDPROCESS

End

---------------------------------------------------------------------------
-- Insert the mapped records into the schema for the Formatter to pick up
-- and create the output file
-- Also update the records in O schema to indicate that the record has been
-- used for correlation 
---------------------------------------------------------------------------

Begin Transaction Insert_Mapping_Rec

Begin Try

	insert into tb_MedCorrelateMapBER
	(RecordID ,CorrelationID ,I_CDRFileID , O_CDRFileID, Z_CDRFileID, I_BERID, O_BERID, Z_BERID, OutCDRFileID )
	select convert(varchar(20) , I_CDRFileID)+'-'+ convert(varchar(20) , I_BERID) + ':' +
		   convert(varchar(20) , O_CDRFileID)+'-'+ convert(varchar(20) , O_BERID) + ':' +
		   convert(varchar(20) , Z_CDRFileID)+'-'+ convert(varchar(20) , Z_BERID),
	CorrelationID ,I_CDRFileID , O_CDRFileID , Z_CDRFileID, I_BERID, O_BERID, Z_BERID , NULL
	from #temp_MedCorrelateMapBER

	update tbl1
	set UsedInCorrelationFlag = 1
	from tb_OTypeRecords tbl1
	inner join ( select distinct O_CDRFileID , O_BERID from #temp_MedCorrelateMapBER ) as tbl2
	        on tbl1.CDRFileID = tbl2.O_CDRFileID and tbl1.BERID = tbl2.O_BERID


End Try

Begin Catch

    set @ErrorDescription = 'ERROR: Inserting/Updating Mapped I,O and Z records into schema.' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSCorrelateMapBER : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	set @ResultFlag = 1

	Rollback Transaction Insert_Mapping_Rec

	GOTO ENDPROCESS

End Catch

Commit Transaction Insert_Mapping_Rec

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_OTypeRecords') )
	Drop table #temp_OTypeRecords

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedCorrelateMapBER') )
	Drop table #temp_MedCorrelateMapBER
GO
