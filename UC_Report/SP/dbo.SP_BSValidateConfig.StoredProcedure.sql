USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSValidateConfig]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSValidateConfig]
(
	@AccessScopeID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @ConfigDataTypeID int,
        @ConfigName varchar(200),
		@ConfigValue varchar(2000),
		@Command varchar(2000),
		@FileExists int


-------------------------------------------
-- Check if the Access Scope exists or not
-------------------------------------------

if not exists ( select 1 from TB_Masterlog_AccessScope where AccessScopeID = @AccessScopeID )
Begin

	 set @ErrorDescription = 'ERROR: Access Scope or Module does not exists in the system configuration '
	 Raiserror('%s' ,16, 1, @ErrorDescription) 
	 set @ResultFlag = 1
     return 1		

End

---------------------------------------------------------------------
-- Start a cursor to process all the config parameters and validate
---------------------------------------------------------------------

DECLARE db_Validate_Config_Param CURSOR FOR 
select Configname , ConfigValue
from TB_Masterlog_Config tbl1
where AccessScopeID = @AccessScopeID 

OPEN db_Validate_Config_Param   
FETCH NEXT FROM db_Validate_Config_Param
INTO @ConfigName  , @ConfigValue 

WHILE @@FETCH_STATUS = 0   
BEGIN  

	   set @ErrorDescription = NULL
	   set @ResultFlag = 0

	   Exec SP_BSValidateConfigParam @AccessScopeID , @ConfigName , @ConfigValue,
	                                         @ErrorDescription output,
											 @ResultFlag Output

       if ( @ResultFlag =  1 )
	   Begin
				CLOSE db_Validate_Config_Param  
				DEALLOCATE db_Validate_Config_Param

				return 1	

	   End
       

	   FETCH NEXT FROM db_Validate_Config_Param
	   INTO @ConfigName  , @ConfigValue 
 
END   

CLOSE db_Validate_Config_Param  
DEALLOCATE db_Validate_Config_Param


return 0
GO
