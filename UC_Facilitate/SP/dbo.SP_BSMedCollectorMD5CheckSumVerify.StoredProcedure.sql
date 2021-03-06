USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCollectorMD5CheckSumVerify]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedCollectorMD5CheckSumVerify]
(
	@Md5EncryptionFile varchar(1000),
	@CDRFileName varchar(1000),
	@MD5CheckExecutablePath varchar(1000),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
    @ResultFlag int Output
)
As

--Declare @Md5EncryptionFile varchar(1000) = 'C:\uClick_Product_Suite\uClickFacilitate\TEST MD5\MGC1-UNIT1_1511060000.16.cdr.md5',
--        @CDRFileName varchar(1000) = 'C:\uClick_Product_Suite\uClickFacilitate\TEST MD5\Working Directory\MGC1-UNIT1_1511060000.16.cdr'

--Declare @ErrorDescription varchar(2000),
--        @ResultFlag int,
--		@AbsoluteLogFilePath varchar(1000) = 'C:\uClick_Product_Suite\uClickFacilitate\TELES_MGC\Logs\MedCollector.log'

Declare @Command varchar(1000),
		@RowTerminator varchar(100),
		@FieldTerminator varchar(100),
		@SQLStr varchar(2000),
		@result int,
		@FileExists int,
		@CheckSumValuefromMD5File varchar(500)


set @ErrorDescription = NULL
set @ResultFlag = 0

if ( right(@MD5CheckExecutablePath , 1) <> '\')
	set @MD5CheckExecutablePath  = @MD5CheckExecutablePath  + '\'

Declare @CDRFileNameWithoutExtension varchar(1000) = reverse(substring(Reverse(@CDRFileName) , 1 , charindex('\' ,Reverse(@CDRFileName)) - 1))

----------------------------------------------------------
-- Create a temp table to upload the contents of the MD5
-- file and extract the key
----------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#Temp_MD5Details') )
	Drop table #Temp_MD5Details

Create table #Temp_MD5Details ( RecordData varchar(2000))

Begin Try

set @RowTerminator = '\n'

Select	@SQLStr = 'Bulk Insert #Temp_MD5Details From ' 
		          + '''' + @Md5EncryptionFile +'''' + ' WITH (
		          ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

print @SQLStr
Exec (@SQLStr)

End Try

Begin Catch

    set @ErrorDescription = 'ERROR: Importing MD5 file :' + @Md5EncryptionFile + ' into Database for checksum validation.' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSMedCollectorMD5CheckSum : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

    set @ResultFlag = 1

    GOTO ENDPROCESS

End Catch

-------------------------------------------------------
-- Remove any records with NULL records from the table
-------------------------------------------------------

Delete from #Temp_MD5Details
where RecordData is NULL
 
select @CheckSumValuefromMD5File = rtrim(ltrim(substring(RecordData ,1 , Charindex(@CDRFileNameWithoutExtension , RecordData) - 3)))
from #Temp_MD5Details

if ( @CheckSumValuefromMD5File is NULL )
Begin

    set @ErrorDescription = 'ERROR: Checksum Value : ' + @CheckSumValuefromMD5File + ' cannot be extracted from file : ' + @Md5EncryptionFile 
  
    set @ErrorDescription = 'SP_BSMedCollectorMD5CheckSum : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

    set @ResultFlag = 1

    GOTO ENDPROCESS

End

select @CheckSumValuefromMD5File

-----------------------------------------------------------
-- Run the utility to check the MD5 value for the CDR file
-----------------------------------------------------------

Delete from #Temp_MD5Details

-------------------------------------------------------------
-- Build command to get the MD5 encryption value for the file
-------------------------------------------------------------

set @Command = '""'+@MD5CheckExecutablePath + 'FCIV" ' + '"' + @CDRFileName + '"'

print @Command

insert into #Temp_MD5Details
Exec master..xp_cmdshell @Command

Delete from #Temp_MD5Details
where RecordData is NULL

select *
from #Temp_MD5Details

------------------------------------------------------------------
-- Check if there exists a record in the temp table for the MD5
-- encryption value
------------------------------------------------------------------

if not exists (select 1 from #Temp_MD5Details where charindex(@CheckSumValuefromMD5File ,RecordData) <> 0 )
Begin

    set @ErrorDescription = 'ERROR: Checksum Value : ' + @CheckSumValuefromMD5File + ' present in MD5 file : ' + @Md5EncryptionFile + ' does not match with value calculated by utility.'
  
    set @ErrorDescription = 'SP_BSMedCollectorMD5CheckSum : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

    set @ResultFlag = 1

    GOTO ENDPROCESS

End

  
ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#Temp_MD5Details') )
	Drop table #Temp_MD5Details

GO
