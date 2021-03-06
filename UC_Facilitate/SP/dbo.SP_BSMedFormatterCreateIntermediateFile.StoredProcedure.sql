USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCreateIntermediateFile]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCreateIntermediateFile]
(
	@AbsoluteIntermediateFileName varchar(1000),
	@OutputFileNameWithoutExtension varchar(1000),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


Declare @SQLStr nvarchar(max),
        @TempTableName varchar(100)

--------------------------------------------------------------
-- Create the name of the temporary table to hold the combined
-- CDR records and output to the intermediate file
--------------------------------------------------------------

set @TempTableName = Replace(@OutputFileNameWithoutExtension , 'TELES_MGC' , 'Temp_MedFormatter_Intermediate')

if exists ( select 1 from sysobjects where name = @TempTableName and xtype = 'U')
	Exec('Drop table '+ @TempTableName)

-------------------------------------------------------------
-- Combine the inbound and outboud CDR legs together to
-- form the CDR records
-------------------------------------------------------------

set @SQLStr = 
		'Select tbl1.RecordID , tbl1.CorrelationID , tbl2.RecData as RecData1  , tbl3.RecData as RecData2 ' + CHAR(10) +
		'into ' + @TempTableName + Char(10) +
		'from #temp_MedFormatterMapBER tbl1 ' + Char(10) +
		'inner join tb_ITypeRecords tbl2 on tbl1.I_CDRFileID = tbl2.CDRFileID and tbl1.I_BERID = tbl2.BERID ' + Char(10)+
		'inner join tb_OTypeRecords tbl3 on tbl1.O_CDRFileID = tbl3.CDRFileID and tbl1.O_BERID = tbl3.BERID'

Begin Try

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running dynamic SQL to create the intermediate table for Correlated CDRs. ' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterCreateIntermediateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End Catch

Select 'Debug : In SP_BSMedFormatterCreateIntermediateFile after creating data Date is : ' + convert(varchar(30) , getdate() , 120)

-------------------------------------------------------
-- Output the intermediate table contents to the file
-------------------------------------------------------

Declare @QualifiedTableName varchar(500) ,
		@FileExists int,
		@Command varchar(2000),
		@bcpCommand varchar(2000)

set @QualifiedTableName = db_name() + '.dbo.' + @TempTableName

--------------------------------------------------------------
-- Remove any previous instance of the OUTPUT file if exists
--------------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist  @AbsoluteIntermediateFileName , @FileExists output 

If (@FileExists = 1)
Begin

		set @Command = 'del ' + '"'+@AbsoluteIntermediateFileName +'"'
		--print @Command 

		Exec master..xp_cmdshell @Command

End

-----------------------------------------------------------
-- Run the BCP command to create the output intermediate file
-----------------------------------------------------------

SET @bcpCommand = 'bcp "SELECT *  from ' +
                    @QualifiedTableName +'" queryout ' + '"'+ltrim(rtrim(@AbsoluteIntermediateFileName)) + '"' +' -c -t "," -r"\n" -T -S '+ @@servername

exec master..xp_cmdshell @bcpCommand

Select 'Debug : In SP_BSMedFormatterCreateIntermediateFile after file output Date is : ' + convert(varchar(30) , getdate() , 120)

------------------------------------------------------
-- Check to ensure that the intermdiate output file 
-- has been created successfully
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist  @AbsoluteIntermediateFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = ' ERROR !!! Failed to Create the intermdiate output file : ' + @OutputFileNameWithoutExtension + ' for Correlated CDR Records'

	set @ErrorDescription = 'SP_BSMedFormatterCreateIntermediateFile : '+ convert(varchar(30) ,getdate() , 120) +
			                    ' : ' + @ErrorDescription

	Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath
	
	set @ResultFlag = 1

	GOTO ENDPROCESS

End



ENDPROCESS:

if exists ( select 1 from sysobjects where name = @TempTableName and xtype = 'U')
	Exec('Drop table '+ @TempTableName)

GO
