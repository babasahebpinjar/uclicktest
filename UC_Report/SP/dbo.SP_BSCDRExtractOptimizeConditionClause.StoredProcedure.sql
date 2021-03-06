USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtractOptimizeConditionClause]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRExtractOptimizeConditionClause]
(
	@ConditionClause nvarchar(max),
	@ConditionClauseOptimize nvarchar(max) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0 


set @ConditionClauseOptimize = @ConditionClause

-----------------------------------------------------------
-- Open a cursor to loop through list of display fields
-- and optimize the condition clause data
-----------------------------------------------------------

Declare @VarFieldName varchar(100),
		@VarExtractValue varchar(2000)

DECLARE db_Optimize_Dynamic_Condition_Data CURSOR FOR  
Select FieldName , ExtractValue
from tb_CDRExtractMasterReference 
order by len(FieldName) desc -- this order by clause has been added to make sure that fields with longer name are handled first

OPEN db_Optimize_Dynamic_Condition_Data
FETCH NEXT FROM db_Optimize_Dynamic_Condition_Data
INTO @VarFieldName , @VarExtractValue 

Begin Try

WHILE @@FETCH_STATUS = 0   
BEGIN   

        if ( charindex(@VarFieldName , @ConditionClauseOptimize) <> 0 )
		Begin

		        --------------------------------------------------------------
				-- Ensure that we are not replacing an already replaced field
				--------------------------------------------------------------
				if ( charindex('.'+@VarFieldName ,@ConditionClauseOptimize ) = 0 )
				Begin

						set @ConditionClauseOptimize = replace(@ConditionClauseOptimize , @VarFieldName , @VarExtractValue)

				End

		End

		FETCH NEXT FROM db_Optimize_Dynamic_Condition_Data
		INTO @VarFieldName , @VarExtractValue

END 


End Try 

Begin Catch

		set @ErrorDescription = 'ERROR !!! When optimizing the dynamic condition clause. ' + ERROR_MESSAGE()
		set @ResultFlag = 1

          
		CLOSE db_Optimize_Dynamic_Condition_Data  
		DEALLOCATE db_Optimize_Dynamic_Condition_Data 
				
		Return 0

End Catch

CLOSE db_Optimize_Dynamic_Condition_Data  
DEALLOCATE db_Optimize_Dynamic_Condition_Data  

GO
