USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogCollectorUncompressFile]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSMasterlogCollectorUncompressFile]
(
	@InputFileName varchar(1000),
	@CompressionExtension varchar(100),
	@WorkingDirectory varchar(1000),
	@UnCompressExecutablePath varchar(1000),
	@OutputFileName varchar(1000) Output,
	@ErrorDescription varchar(200) Output
)
As

set @OutputFileName = NULL
set @ErrorDescription = NULL

Declare @UnCompressExecutable varchar(1000) = 'WinRar.exe',
        @UnCompressedCDRFileName varchar(1000) 

--@InputFileName varchar(1000) = 'C:\uClick_Product_Suite\uClickFacilitate\TEST MD5\MGC1-UNIT1_1511060000.16.cdr.gz',
--@CompressionExtension varchar(100) = '.gz',
--@WorkingDirectory varchar(1000) = 'C:\uClick_Product_Suite\uClickFacilitate\TEST MD5\Working Directory'

if ( right(@WorkingDirectory,1) <> '\' )
	set @WorkingDirectory = @WorkingDirectory + '\'

if ( right(@UnCompressExecutablePath,1) <> '\' )
set @UnCompressExecutablePath = @UnCompressExecutablePath + '\'

set @UnCompressedCDRFileName  = reverse(substring(reverse(@InputFileName), 1 , charindex('\' , reverse(@InputFileName)) - 1))
set @UnCompressedCDRFileName = substring(@UnCompressedCDRFileName, 1 , len(@UnCompressedCDRFileName) - len(@CompressionExtension))

set  @OutputFileName = @WorkingDirectory + @UnCompressedCDRFileName

--Select 'Debug: Printing the Full path of the Compressed and Uncompressed File before uncompressing' as status
--select @InputFileName as CompressFile , @OutputFileName as UnCompressFile
                 
print @OutputFileName       

Declare @Command varchar(2000),
        @FileExists int = 0

------------------------------------------------------
-- Run the command to uncompress the executable file
-------------------------------------------------------

set @Command = ''+@UnCompressExecutablePath +'WINRAR'  +  ' e ' + '"' + @InputFileName + '"' + ' ' + '"' + @WorkingDirectory + '"'

print @Command

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOutput') )
	Drop table #TempOutput

create table #TempOutput (RecordData varchar(2000) )

Insert into #TempOutput
Exec master..xp_cmdshell @Command

select *
from #TempOutput

-------------------------------------------------------------
-- Adding this to select the top most record in case of error
-------------------------------------------------------------

Alter table #TempOutput Add RecordID int identity(1,1)

------------------------------------------------------
-- Post uncompression check if the file exists or not
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist  @OutputFileName , @FileExists output

print @FileExists

if ( @FileExists <> 1 )
Begin

	set @OutputFileName = NULL

	select @ErrorDescription = RecordData
	from #TempOutput
	where RecordID = 1


End

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOutput') )
	Drop table #TempOutput




GO
