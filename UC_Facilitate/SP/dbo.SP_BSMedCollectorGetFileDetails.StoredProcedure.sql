USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCollectorGetFileDetails]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSMedCollectorGetFileDetails]
(
  @CDRFileName varchar(500),
  @CompleteCDRFileName varchar(500),
  @FileDetails varchar(1000) output
)
As

DECLARE @CommandString varchar(2000)


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempGetFileDetails') )
	Drop table #TempGetFileDetails

CREATE TABLE #TempGetFileDetails (row VARCHAR(1000) )

set @CommandString = 'DIR ' + @CompleteCDRFileName 

INSERT	#TempGetFileDetails ( row )
EXEC	master..xp_cmdshell @CommandString

delete from #TempGetFileDetails
where row is null

delete from #TempGetFileDetails
where CHARINDEX(@CDRFileName , row) = 0

select @FileDetails = substring(row , 1,20) + ' ' +ltrim(substring(row , 21 , patindex('%'+@CDRFileName+'%' , row )-21))
from #TempGetFileDetails

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempGetFileDetails') )
	Drop table #TempGetFileDetails

return 0
GO
