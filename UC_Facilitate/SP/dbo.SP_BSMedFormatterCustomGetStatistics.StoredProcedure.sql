USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCustomGetStatistics]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCustomGetStatistics]
(
	@TotalRecords int Output,
    @TotalProcessedRecords int Output,
	@TotalRejectRecords int Output,
	@TotalDuplicateRecords int Output,
	@TotalMinutes Decimal(19,2) Output,
	@TotalProcessedMinutes Decimal(19,2) Output,
	@TotalRejectMinutes Decimal(19,2) Output,
	@TotalDuplicateMinutes Decimal(19,2) Output
)
As

------------------------------------------------
-- Get all the Relevant statistics for the file
------------------------------------------------
-- Total Records & Total Minutes

select @TotalRecords = count(*),
       @TotalMinutes = isnull(convert(decimal(19,2) ,sum(CallDuration)/60.0),0)
from ##temp_MedFormatterOutputRecords

-- Total Processed Records & Minutes

select @TotalProcessedRecords = count(*),
	   @TotalProcessedMinutes = isnull(convert(decimal(19,2) ,sum(CallDuration)/60.0),0)
from ##temp_MedFormatterOutputRecords
where RecordStatus is NULL

-- Total Rejected Records & Minutes

select @TotalRejectRecords = count(*),
       @TotalRejectMinutes = isnull(convert(decimal(19,2) ,sum(CallDuration)/60.0),0)
from ##temp_MedFormatterOutputRecords
where RecordStatus = 'REJECT'

-- Total Duplicate Records & Minutes

select @TotalDuplicateRecords = count(*),
	   @TotalDuplicateMinutes = isnull(convert(decimal(19,2) ,sum(CallDuration)/60.0),0)
from ##temp_MedFormatterOutputRecords
where RecordStatus = 'DUPLICATE'



return 0
GO
