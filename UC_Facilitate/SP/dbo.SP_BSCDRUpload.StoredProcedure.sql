USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRUpload]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRUpload] As

Declare @InputFileFolder varchar(1000) = 'G:\Uclick_Product_Suite\uClickFacilitate\MedFormatter\Output',
		@CDRFileExtension varchar(10) = '.CDR',
		@CDRFileNameTag varchar(20) = 'avh01',
		@AbsoluteLogFilePath varchar(1000) = 'F:\Uclick_Product_Suite\uClickFacilitate\Logs\CDRUpload.Log'

Declare @SQLStr varchar(2000),
		@ErrorDescription varchar(2000)

if ( right(@InputFileFolder,1) <>'\')
	set @InputFileFolder = @InputFileFolder + '\'
			
----------------------------------------------------
-- Get the list of all files in the Input Folder
----------------------------------------------------

-- Create a temp table to hold the list of files

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToUpload') )
		Drop table #tmpGetListOfCDRFilesToUpload

Create table #tmpGetListOfCDRFilesToUpload (CDRFileName varchar(1000))

Begin Try

		-- Build the command to explore the input folder for files

		set @SQLStr = 'dir /b ' + '"' + @InputFileFolder + @CDRFileNameTag + '*' + @CDRFileExtension + '"'

		--print @SQLStr

		Insert	#tmpGetListOfCDRFilesToUpload
		EXEC 	master..xp_cmdshell @SQLStr

		-- Delete NULL records and record for "File Not Found"

		Delete from #tmpGetListOfCDRFilesToUpload
		where CDRfilename is NULL or CDRFileName = 'File Not Found'

		--Select 'Debug: Check the temporary table after running DIR command' as status
		--select * from #tmpGetListOfCDRFilesToUpload

End Try

Begin Catch

	set @ErrorDescription = 'SP_BSCDRUpload: '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR!!! While getting list of CDR files from input folder'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End Catch

-- Delete all the CDR files in the temp table, which have already been
-- uploaded 

delete tbl1
from #tmpGetListOfCDRFilesToUpload tbl1
inner join tb_CDRUploadStatistics tbl2
	on tbl1.CDRFileName = tbl2.CDRFileName + @CDRFileExtension

--select * from #tmpGetListOfCDRFilesToUpload

------------------------------------------------------------------
-- Loop through the list of CDR files to upload them one by one
-------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadCDRFile') )	
	Drop table #TempUploadCDRFile

Select * into #TempUploadCDRFile from tb_CDRFileData
where 1 = 2

--select * from #TempUploadCDRFile

Declare @VarCDRFileName varchar(500),
		@FieldDelimiter varchar(100),
		@RowDelimiter varchar(100),
		@TotalRecordCount int,
		@CDRFileNameWithoutExtension varchar(100)

set @RowDelimiter = '\n'
set @FieldDelimiter = ','

DECLARE db_cur_get_Upload_CDR_Files CURSOR FOR
select CDRFileName 
from #tmpGetListOfCDRFilesToUpload 

OPEN db_cur_get_Upload_CDR_Files
FETCH NEXT FROM db_cur_get_Upload_CDR_Files
INTO @VarCDRFileName 

While @@FETCH_STATUS = 0
BEGIN

		set @CDRFileNameWithoutExtension =  substring(@VarCDRFileName , 1 , len(@VarCDRFileName) - len(@CDRFileExtension))
		set @VarCDRFileName = @InputFileFolder + @VarCDRFileName

		delete from #TempUploadCDRFile

		Begin Try

			Select	@SQLStr = 'Bulk Insert #TempUploadCDRFile From ' 
						  + '''' + @VarCDRFileName +'''' + ' WITH (
						  FIELDTERMINATOR  = ''' + @FieldDelimiter + ''','+
						  'ROWTERMINATOR    = ''' + @RowDelimiter + ''''+')'

			--print @SQLStr
			Exec (@SQLStr)

			--select * from #TempUploadCDRFile


		End Try

		Begin Catch

			set @ErrorDescription = 'SP_BSCDRUpload : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + 'ERROR !!!Uploading the key fields file (' + @VarCDRFileName +').' + ERROR_MESSAGE()

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			CLOSE db_cur_get_Upload_CDR_Files
			DEALLOCATE db_cur_get_Upload_CDR_Files

			GOTO ENDPROCESS


		End Catch

		-- Update the CDR File Name in the Records

		update #TempUploadCDRFile
		set CDRFileName = @CDRFileNameWithoutExtension
		
		-- Get the count of records in the temp table in which file is uploaded
		select @TotalRecordCount = count(*)
		from #TempUploadCDRFile
		
		-- Move the File from the Temp table to the Final table
		insert into tb_CDRFileData
		Select * from #TempUploadCDRFile
		
		-- Add an entry for the file in the statistics table 
		insert into tb_CDRUploadStatistics (CDRFileName , TotalRecords , UploadDate)
		values ( @CDRFileNameWithoutExtension , @TotalRecordCount , getdate())
	
		
		FETCH NEXT FROM db_cur_get_Upload_CDR_Files
		INTO @VarCDRFileName   		 

END

CLOSE db_cur_get_Upload_CDR_Files
DEALLOCATE db_cur_get_Upload_CDR_Files

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToUpload') )
		Drop table #tmpGetListOfCDRFilesToUpload

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadCDRFile') )	
	Drop table #TempUploadCDRFile
GO
