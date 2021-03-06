USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_ChartTopNCDRFilesExportedFromSwitch]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_ChartTopNCDRFilesExportedFromSwitch]
(
	@TopNCount int
)
As

if (@TopNCount <= 0 )
	set @TopNCount = 10

Declare @SQLStr varchar(2000)

---------------------------------------------------------
-- Latest N CDR Files Exported from Switch Directory
---------------------------------------------------------

set @SQLStr = 'select top ' + convert(varchar(20) ,@TopNCount) + ' CDRFilename , FileTimeStamp ' + char(10)+
              'from tb_MedCollectorStatistics ' + char(10)+
              'where FileStatus = ''File Exported'' ' + char(10)+
              'order by convert(datetime , substring(cdrfilename , 12,6) + '' '' +  substring(cdrfilename , 18,2) + '':'' +  substring(cdrfilename , 20,2) ) desc'

-- print @SQLStr

Exec(@SQLStr)

Return 0
GO
