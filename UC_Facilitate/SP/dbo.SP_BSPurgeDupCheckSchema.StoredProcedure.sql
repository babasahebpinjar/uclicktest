USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPurgeDupCheckSchema]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSPurgeDupCheckSchema]
(
	@DuplicateCheckDays int
)
As

--set @DuplicateCheckDays = 10

Declare @VarTableName varchar(100),
        @ErrorMsgStr varchar(2000)

--------------------------------------------
-- Open a cursor to get the name of all the 
-- duplicate check tables which are older
-- than Duplicate Check interval
--------------------------------------------

DECLARE db_GetNamesDupCheck_Schema CURSOR FOR
select name as TableName
from sysobjects 
where name like 'TB_DupCheck_%'
and xtype = 'U'
and Datediff(dd , convert(date ,substring(name , 13 , len(name))) , convert(date, getdate())) > @DuplicateCheckDays

OPEN db_GetNamesDupCheck_Schema
FETCH NEXT FROM db_GetNamesDupCheck_Schema
INTO @VarTableName

While @@FETCH_STATUS = 0
BEGIN

    -------------------------------------------------
	-- Drop all the qualifying duplicate check table
	 -------------------------------------------------
	
	Begin Try

		Exec('Drop table '+ @VarTableName)

	End Try

	Begin Catch

	    set @ErrorMsgStr = 'ERROR !!! While dropping duplicate check table : ' + @VarTableName + '. ' + ERROR_MESSAGE()
		RaisError('%s' , 16, 1, @ErrorMsgStr)

		CLOSE db_GetNamesDupCheck_Schema
		DEALLOCATE db_GetNamesDupCheck_Schema 	
		
		GOTO ENDPROCESS	

	End Catch
		
		FETCH NEXT FROM db_GetNamesDupCheck_Schema
		INTO @VarTableName   		 

END

ENDPROCESS:

CLOSE db_GetNamesDupCheck_Schema
DEALLOCATE db_GetNamesDupCheck_Schema 



GO
