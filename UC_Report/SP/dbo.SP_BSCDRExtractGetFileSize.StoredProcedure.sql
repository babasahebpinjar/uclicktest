USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtractGetFileSize]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_BSCDRExtractGetFileSize]
(
  @CompleteCDRExtractFileName varchar(500),
  @CDRFileSizeInMB Decimal(19,2) output
)
As

DECLARE @CommandString varchar(2000),
        @CDRExtractFileName varchar(500),
		@CDRFileSize int,
		@FileDetails varchar(500)		


set @CDRExtractFileName = reverse(substring(reverse(@CompleteCDRExtractFileName) , 1 , charindex('\' , reverse(@CompleteCDRExtractFileName) ) - 1 ))

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempGetFileDetails') )
	Drop table #TempGetFileDetails

CREATE TABLE #TempGetFileDetails (row VARCHAR(1000) )

set @CommandString = 'DIR ' + @CompleteCDRExtractFileName 

--print @CommandString

INSERT	#TempGetFileDetails ( row )
EXEC	master..xp_cmdshell @CommandString

delete from #TempGetFileDetails
where row is null

delete from #TempGetFileDetails
where CHARINDEX(@CDRExtractFileName , row) = 0

select @FileDetails = substring(row , 1,20) + ' ' +ltrim(substring(row , 21 , patindex('%'+@CDRExtractFileName+'%' , row )-21))
from #TempGetFileDetails

set  @CDRFileSize = Replace(substring(rtrim(@FileDetails), 22 , len(rtrim(@FileDetails))), ',' , '')

set @CDRFileSizeInMB =  convert(decimal(19,2) , @CDRFileSize/(1024.0 * 1024.0))

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempGetFileDetails') )
	Drop table #TempGetFileDetails

return 0
GO
