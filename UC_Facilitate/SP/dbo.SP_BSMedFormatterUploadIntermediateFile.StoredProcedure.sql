USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterUploadIntermediateFile]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterUploadIntermediateFile]
(
	@AbsoluteIntermediateFileName varchar(1000),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

Declare @Command varchar(1000),
		@RowTerminator varchar(100),
		@FieldTerminator varchar(100),
		@SQLStr varchar(2000),
		@result int,
		@FileExists int

-----------------------------------------------------------------
-- Upload the intermediate Correlated CDR file into the Dynamic
-- table whose name has been passed in the input parameters
-----------------------------------------------------------------

Begin Try

set @RowTerminator = '\n'
set @FieldTerminator = ',' 

Select	@SQLStr = 'Bulk Insert ##temp_MedFormatterRecords From ' 
		          + '''' + @AbsoluteIntermediateFileName +'''' + ' WITH (
		          FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
                  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

print @SQLStr
Exec (@SQLStr)

End Try

Begin Catch

    set @ErrorDescription = 'ERROR: Importing intermediate correlated CDR File :' + @AbsoluteIntermediateFileName + ' into Database.' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSMedFormatterUploadIntermediateFile : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

   set @ResultFlag = 1

   Return 1

 End Catch

 -------------------------------------------------------------------------------
 -- If there are records in the table, then we can delete the intermediate file
 -- post data upload
 ------------------------------------------------------------------------------- 

 if ( (select count(*) from ##temp_MedFormatterRecords) > 0 )
 Begin

		set @FileExists = 0

		Exec master..xp_fileexist  @AbsoluteIntermediateFileName , @FileExists output 

		If (@FileExists = 1)
		Begin

				set @Command = 'del ' + '"'+ @AbsoluteIntermediateFileName +'"'
				--print @Command 

				Exec master..xp_cmdshell @Command

		End

End

Return 0
GO
