USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtractDataPrepare]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRExtractDataPrepare]
(
	@SelectClause nvarchar(max) Output,
	@InsertClause nvarchar(max) Output,
    @SchemaClause nvarchar(max) Output,
	@DisplayClause nvarchar(max) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0 

-----------------------------------------------------------
-- Open a cursor to loop through list of display fields
-- and prepare the different dynamic data
-----------------------------------------------------------

Declare @VarFieldName varchar(100),
        @VarFieldType varchar(100),
		@VarExtractValue varchar(2000),
		@VarJoinClause varchar(2000)

set @SelectClause = ''
set @InsertClause = ''
set @DisplayClause = ''
set @SchemaClause = ''

DECLARE db_Prepare_Dynamic_Extract_Data CURSOR FOR  
Select tbl2.FieldName , tbl2.FieldType , tbl2.ExtractValue , tbl2.JoinClause
from #TempDisplayFieldIDTable tbl1
inner join tb_CDRExtractMasterReference tbl2 on
				convert(int ,tbl1.DisplayFieldID) = tbl2.CDRExtractMasterReferenceID
order by CDRExtractMasterReferenceID desc

OPEN db_Prepare_Dynamic_Extract_Data
FETCH NEXT FROM db_Prepare_Dynamic_Extract_Data
INTO @VarFieldName  , @VarFieldType , @VarExtractValue  , @VarJoinClause

Begin Try

WHILE @@FETCH_STATUS = 0   
BEGIN   

        set @SelectClause = @SelectClause + @VarExtractValue + ',' + char(10)
		set @InsertClause = @InsertClause + @VarExtractValue + ' as ' + @VarFieldName + ',' +  char(10)

		set @SchemaClause =
		      Case

					When @VarJoinClause is NULL then @SchemaClause
					Else
					   Case
							When charindex(@VarJoinClause , @SchemaClause ) <> 0 then @SchemaClause
							Else @SchemaClause + @VarJoinClause + char(10)
					   End

			  End
		
		set @DisplayClause = @DisplayClause + @VarFieldName + ',' + char(10)

		FETCH NEXT FROM db_Prepare_Dynamic_Extract_Data
		INTO @VarFieldName  , @VarFieldType , @VarExtractValue  , @VarJoinClause

END 

CLOSE db_Prepare_Dynamic_Extract_Data  
DEALLOCATE db_Prepare_Dynamic_Extract_Data 

----------------------------------------------------------
-- Remove the extra portion of all the dynamic strings
----------------------------------------------------------

--select @SelectClause , @InsertClause , @SchemaClause , @DisplayClause

set @SelectClause = substring(@SelectClause , 1 , len(@SelectClause)-2)
set @InsertClause = substring(@InsertClause ,  1 , len(@InsertClause)-2)

if ( len(@SchemaClause) > 0 )
	set @SchemaClause = substring(@SchemaClause ,  1 , len(@SchemaClause)-1)

set @DisplayClause = substring(@DisplayClause ,  1 , len(@DisplayClause) -2 )


End Try 

Begin Catch

		set @ErrorDescription = 'ERROR !!! When preparing the dynamic data for select, insert, extract and join clause. ' + ERROR_MESSAGE()
		set @ResultFlag = 1        
				
		Return 0

End Catch


GO
