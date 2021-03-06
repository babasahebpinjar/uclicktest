USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_ChartTopNCDRFilesOutputByFormatter]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_ChartTopNCDRFilesOutputByFormatter]
(
	@TopNCount int
)
As

if (@TopNCount <= 0 )
	set @TopNCount = 10

Declare @SQLStr varchar(2000)

---------------------------------------------------------
-- Latest N CDR Files Output by Formatter Module
---------------------------------------------------------

set @SQLStr = 'select top ' + convert(varchar(20) ,@TopNCount) + ' CDRfileName , TotalRecords as Total ,  TotalProcessedRecords as Processed, TotalDiscardRecords as Discard, TotalRejectRecords as Reject, ' + char(10) +
              'convert(datetime, (substring(cdrfilename , 11,8)  +  '' '' +  substring(cdrfilename , 19,2) + '':'' +  substring(cdrfilename , 21,2)) ) as FileTimeStamp ' + char(10) +
              'from tb_MedFormatterOutput ' + char(10) +
              'where filestatus = ''Processed'' ' + char(10) +
              'order by convert(datetime, (substring(cdrfilename , 11,8)  +  '' '' +  substring(cdrfilename , 19,2) + '':'' +  substring(cdrfilename , 21,2)) ) desc '

print @SQLStr

Exec(@SQLStr)

Return 0
GO
