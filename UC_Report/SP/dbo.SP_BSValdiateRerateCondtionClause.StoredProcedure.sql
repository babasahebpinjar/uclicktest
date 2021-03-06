USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSValdiateRerateCondtionClause]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSValdiateRerateCondtionClause]
(
	@ConditionClause nvarchar(max),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0 

Declare @SQLStr nvarchar(max)

-----------------------------------------------------------
-- Open a cursor to loop through list of display fields
-- and prepare the different dynamic data
-----------------------------------------------------------

Declare @VarFieldName varchar(100),
        @VarFieldType varchar(100),
		@ExtractTableName varchar(100) = 'tb_Rerate_' + replace(replace(replace(convert(varchar(20) , GetDate(), 120), '-', ''), ':' , ''), ' ', '')

set @SQLStr = 'Create table ' + @ExtractTableName + ' (' + char(10)

DECLARE db_Prepare_Dynamic_Extract_Data CURSOR FOR  
Select FieldName , FieldType 
from tb_CDRExtractMasterReference
where DataExtractSchema = 'CDR'
order by CDRExtractMasterReferenceID desc

OPEN db_Prepare_Dynamic_Extract_Data
FETCH NEXT FROM db_Prepare_Dynamic_Extract_Data
INTO @VarFieldName  , @VarFieldType 

Begin Try

		WHILE @@FETCH_STATUS = 0   
		BEGIN   

				set @SQLStr = @SQLStr + @VarFieldName + ' ' + @VarFieldType + ',' + char(10)

				FETCH NEXT FROM db_Prepare_Dynamic_Extract_Data
				INTO @VarFieldName  , @VarFieldType 

		END 

		----------------------------------------------------------
		-- Remove the extra portion of all the dynamic strings
		----------------------------------------------------------

		set @SQLStr = substring(@SQLStr , 1 , len(@SQLStr)-2) + ')'

		-----------------------------------
		-- Create the temporary table
		-----------------------------------

		--print @SQLStr

		Exec(@SQLStr)

		
		----------------------------------------------------------------------
		-- Prepare the dynamic query to execute with the conditional clause
		-- to verify that it is semantically correct
		----------------------------------------------------------------------

		set @SQLStr = 'Select * from ' + @ExtractTableName + char(10) + ' Where ' + @ConditionClause

		--print @SQLStr

		Exec (@SQLStr)

End Try 

Begin Catch

		set @ErrorDescription = 'ERROR !!! When validating the Conditon Clause String for Rerate job. ' + ERROR_MESSAGE()
		set @ResultFlag = 1

          
		CLOSE db_Prepare_Dynamic_Extract_Data  
		DEALLOCATE db_Prepare_Dynamic_Extract_Data 
				
		GOTO ENDPROCESS

End Catch

CLOSE db_Prepare_Dynamic_Extract_Data  
DEALLOCATE db_Prepare_Dynamic_Extract_Data


ENDPROCESS:

if exists (select 1 from sysobjects where name = @ExtractTableName and xtype = 'U' )
	Exec('Drop table ' + @ExtractTableName)  

GO
