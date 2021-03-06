USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateConfigParam]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIUpdateConfigParam]
(
	@AccessScopeID int,
	@ConfigName varchar(200),
	@ConfigValue varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------
-- Check to ensure that the Config Value is not NULL
-------------------------------------------------------------

if ( (@ConfigValue is NULL) or (len(@ConfigValue) = 0))
Begin

		set @ErrorDescription = 'ERROR !!! Value provided for configuration paramater is either NULL or empty'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------
-- Call the procedure to validate the configuration value,
-- based on the configuration type
-------------------------------------------------------------

Exec  SP_BSValidateConfigParam @AccessScopeID , @ConfigNAme , @ConfigValue,
                               @ErrorDescription Output,
							   @ResultFlag Output 

if (@ResultFlag = 0)
Begin

		----------------------------------------------------------------
		-- Uptate the value of the Configuration Parameter to the new
		-- value
		----------------------------------------------------------------

		update tb_COnfig
		set ConfigValue = @ConfigValue
		where AccessScopeID = @AccessScopeID
		and ConfigName = @ConfigName

End
GO
