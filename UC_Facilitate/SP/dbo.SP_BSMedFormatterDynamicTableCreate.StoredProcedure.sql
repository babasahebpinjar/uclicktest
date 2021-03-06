USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterDynamicTableCreate]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterDynamicTableCreate]
(
	@FileDefinitionID int,
	@TableName Varchar(200),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

Declare @RowTerminator varchar(100),
		@FieldTerminator varchar(100),
		@SQLStr nvarchar(max)

-------------------------------------------
-- Check if the file definition is NULL
-------------------------------------------

if (@FileDefinitionID is NULL)
Begin

    set @ErrorDescription = 'ERROR: File Definiton ID passed for dynamic table creation is NULL'
  
    set @ErrorDescription = 'SP_BSMedFormatterDynamicTableCreate : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

   set @ResultFlag = 1

   Return 1

End

---------------------------------------------------------------
-- Check if the file definition exists in the system or not
---------------------------------------------------------------

if not exists ( Select 1 from tb_FileDefinition where FileDefinitionID = @FileDefinitionID ) 
Begin

    set @ErrorDescription = 'ERROR: File Definiton ID : ' + convert(varchar(100) , @FileDefinitionID) + ' does not exist in the system'
  
    set @ErrorDescription = 'SP_BSMedFormatterDynamicTableCreate : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

   set @ResultFlag = 1

   Return 1

End

------------------------------------------------------------------
-- Based on the uploaded Field Definition file, create the dynamic
-- SQL for creating the table
------------------------------------------------------------------

Declare @VarFieldName varchar(200),
        @VarFieldOrder int,
		@VarFieldType varchar(100)

set @SQLStr = ' Create table ' + @TableName + ' ( ' + Char(10) 


---------------------------------------------------------------------
-- Start a cursor to process all the Field Definitions and build SQL
---------------------------------------------------------------------

DECLARE db_Create_Dynamic_Query CURSOR FOR 
select FieldName , FieldOrder , FieldType
from tb_FileDefinition tbl1
inner join tb_FieldDefinition tbl2 on tbl1.FileDefinitionID = tbl2.FileDefinitionID
where tbl1.FileDefinitionID = @FileDefinitionID
order by tbl2.FieldOrder

OPEN db_Create_Dynamic_Query   
FETCH NEXT FROM db_Create_Dynamic_Query
INTO @VarFieldName  , @VarFieldOrder , @VarFieldType

WHILE @@FETCH_STATUS = 0   
BEGIN  

       set @SQLStr = @SQLStr + @VarFieldName + ' ' + @VarFieldType + ',' + Char(10)

	   FETCH NEXT FROM db_Create_Dynamic_Query
	   INTO @VarFieldName  , @VarFieldOrder , @VarFieldType
 
END   

CLOSE db_Create_Dynamic_Query  
DEALLOCATE db_Create_Dynamic_Query

set @SQLStr = SUBSTRING(@SQLStr , 1 , len(@SQLStr) -2 ) + ')'

------------------------------------------------------------
-- Execute the dynmaic SQL to create the Temporary table
------------------------------------------------------------
Begin Try

	--print @SQLStr
	Exec (@SQLStr)

End Try

Begin Catch

    set @ErrorDescription = 'ERROR: Executing Query for creating table definition for File Definition ID :' + convert(varchar(10) , @FileDefinitionID) + '. ' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSMedFormatterDynamicTableCreate : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

   set @ResultFlag = 1

   GOTO ENDPROCESS

End Catch

--Select 'Debug : Table created successfully without errors'


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFormatFileDefinition') )
	Drop table #tempFormatFileDefinition

return 0




GO
