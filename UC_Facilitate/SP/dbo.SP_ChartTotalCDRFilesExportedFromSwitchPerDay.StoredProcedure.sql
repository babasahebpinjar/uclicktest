USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_ChartTotalCDRFilesExportedFromSwitchPerDay]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_ChartTotalCDRFilesExportedFromSwitchPerDay]
(
	@DayOffset int
)
As

if ( @DayOffset > 0 )
Begin

	set @DayOffset =  @DayOffset * -1 -- setting it a negative value 

End

----------------------------------------------------------------------------
-- Total CDR Files Exported from Switch Directory Per Day ( Last N days )
----------------------------------------------------------------------------

select convert(date , substring(cdrfilename , 12,6) + ' ' +  substring(cdrfilename , 18,2) + ':' +  substring(cdrfilename , 20,2) ) as SelectDate,
       count(*) as TotalFiles , max(convert(datetime , FileTimeStamp)) as LastFileTimeStamp , Min(convert(datetime , FileTimeStamp)) as FirsttFileTimeStamp
from tb_MedCollectorStatistics
where FileStatus = 'File Exported'
and convert(date , substring(cdrfilename , 12,6) + ' ' +  substring(cdrfilename , 18,2) + ':' +  substring(cdrfilename , 20,2) )
          between dateadd(dd , @DayOffset , convert(date ,getdate()) ) and convert(date ,getdate())
group by  convert(date , substring(cdrfilename , 12,6) + ' ' +  substring(cdrfilename , 18,2) + ':' +  substring(cdrfilename , 20,2) )
order by 1 desc

Return 0
GO
