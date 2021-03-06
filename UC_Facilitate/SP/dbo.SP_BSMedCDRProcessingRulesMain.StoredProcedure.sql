USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCDRProcessingRulesMain]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSMedCDRProcessingRulesMain]
(
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------
-- Create a temporary table to hold the data on which
-- prefixing rules need to be applied
---------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedCDRPrexingOutput') )
	Drop table #temp_MedCDRPrexingOutput

Select *
into #temp_MedCDRPrexingOutput
from ##temp_MedOutputFormatterRecords

----------------------------------------------------------
-- Alter the table and add the enrichment fields as well
----------------------------------------------------------

Alter table #temp_MedCDRPrexingOutput Add INServiceLevelID Int
Alter table #temp_MedCDRPrexingOutput Add INServiceLevel varchar(50)
Alter table #temp_MedCDRPrexingOutput Add OUTServiceLevelID Int
Alter table #temp_MedCDRPrexingOutput Add OUTServiceLevel varchar(50)
Alter table #temp_MedCDRPrexingOutput Add EnrichedINCalledNumber varchar(100)
Alter table #temp_MedCDRPrexingOutput Add EnrichedOutCalledNumber varchar(100)

-----------------------------------------------------------------------
-- Update the IN and OUT CALLED NUMBER for the scenarios where the
-- they have the prefix 030099XX
-----------------------------------------------------------------------


Update #temp_MedCDRPrexingOutput
set INCALLEDNUMBER = 
	            Case
					When substring(INCALLEDNUMBER , 1,6) = '030099' Then
							substring(INCALLEDNUMBER ,1,3) + substring(INCALLEDNUMBER ,9,Len(INCALLEDNUMBER))
					Else INCALLEDNUMBER
				End,		
	OUTCALLEDNUMBER = 
	            Case
					When substring(OUTCALLEDNUMBER , 1,6) = '030099' Then substring(OUTCALLEDNUMBER ,9,Len(OUTCALLEDNUMBER))
					Else OUTCALLEDNUMBER
				End


-------------------------------------------------------------------
-- Call the CDR Processing stored procedure for both the directions
-------------------------------------------------------------------

set @ErrorDescription = NULL
set @ResultFlag = 0

Exec SP_BSMedCDRProcessingRules 1 , @AbsoluteLogFilePath ,@ErrorDescription Output , @ResultFlag Output

if (@ResultFlag = 1)
Begin

		GOTO ENDPROCESS

End

set @ErrorDescription = NULL
set @ResultFlag = 0

Exec SP_BSMedCDRProcessingRules 2 , @AbsoluteLogFilePath ,@ErrorDescription Output , @ResultFlag Output 

if (@ResultFlag = 1)
Begin

		GOTO ENDPROCESS

End

------------------------------------------------------------
-- Update and set the SERVICE LEVEL name in the enriched
-- CDR records post processing
------------------------------------------------------------

update tbl1 
set INServiceLevel = tbl2.ServiceLevel,
    OUTServiceLevel = tbl3.ServiceLevel,
	EnrichedINCalledNumber = 
	   		Case
				When substring(EnrichedINCalledNumber ,1,2) = '00' then substring(EnrichedINCalledNumber, 3 , len(EnrichedINCalledNumber))
				When substring(EnrichedINCalledNumber ,1,1) = '0' and substring(EnrichedINCalledNumber ,1,2) <> '00' 
							        then substring(EnrichedINCalledNumber , 2 , len(EnrichedINCalledNumber))
				Else EnrichedINCalledNumber
			End,
	EnrichedOUTCalledNumber = 
	   		Case
				When substring(EnrichedOUTCalledNumber ,1,2) = '00' then substring(EnrichedOUTCalledNumber, 3 , len(EnrichedOUTCalledNumber))
				When substring(EnrichedOUTCalledNumber ,1,1) = '0' and substring(EnrichedOUTCalledNumber ,1,2) <> '00' 
							        then substring(EnrichedOUTCalledNumber , 2 , len(EnrichedOUTCalledNumber))
				Else EnrichedOUTCalledNumber
			End
from #temp_MedCDRPrexingOutput tbl1
left join UC_Reference.dbo.tb_ServiceLevel tbl2 on tbl1.INServiceLevelID = tbl2.ServiceLevelID
left join UC_Reference.dbo.tb_ServiceLevel tbl3 on tbl1.OUTServiceLevelID = tbl3.ServiceLevelID

-----------------------------------------------------------
-- For all CDRs where the Called number is a '65' based
-- call, we need to update the OUT called number with
-- '65' prefix, in case it is missing
-----------------------------------------------------------

update tbl1
set EnrichedOUTCalledNumber = '65' + EnrichedOUTCalledNumber
from #temp_MedCDRPrexingOutput tbl1
where INServiceLevelID is not null
and OUTServiceLevelID is not NULL
and substring(EnrichedINCalledNumber ,1,2) = '65'
and substring(EnrichedOUTCalledNumber ,1,2) <> '65'
and substring(EnrichedINCalledNumber ,3 ,  len(EnrichedINCalledNumber)) = EnrichedOUTCalledNumber

-----------------------------------------------------
-- Insert data into the temporary storage table
-----------------------------------------------------

insert into Temp_AllOutputRecords
select * from #temp_MedCDRPrexingOutput

ENDPROCESS:

------------------------------------------------------
-- Drop all the temporary tables post processing of
-- data
------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedCDRPrexingOutput') )
	Drop table #temp_MedCDRPrexingOutput
GO
