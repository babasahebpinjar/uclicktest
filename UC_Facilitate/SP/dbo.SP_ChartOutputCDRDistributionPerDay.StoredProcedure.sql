USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_ChartOutputCDRDistributionPerDay]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_ChartOutputCDRDistributionPerDay]
(
	@DayOffset int
)
As

if ( @DayOffset > 0 )
Begin

	set @DayOffset =  @DayOffset * -1 -- setting it a negative value 

End

------------------------------------------------------------
--Total Output CDR Distribution per Day ( Last N days )
------------------------------------------------------------

select convert(date , substring(cdrfilename , 11,8)) as SelectDate ,  sum(TotalProcessedRecords) as ProcessedRecords,
		sum(TotalRejectRecords) as RejectRecords , sum(TotalDiscardRecords) as DiscardRecords
from tb_MedFormatterOutput
where filestatus in ('Processed' , 'Reprocess' , 'Reprocessing')
and convert(date , substring(cdrfilename , 11,8)) between dateadd(dd , @DayOffset , convert(date ,getdate()) ) and convert(date ,getdate())
group by convert(date , substring(cdrfilename , 11,8))
order by 1 desc

Return 0
GO
