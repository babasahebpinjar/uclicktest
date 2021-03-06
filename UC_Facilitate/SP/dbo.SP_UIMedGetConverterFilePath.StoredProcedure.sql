USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedGetConverterFilePath]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedGetConverterFilePath]
(
	@ConfigParamName varchar(1000),
	@CompleteFilePath varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

Declare @FileEXists int

Select @CompleteFilePath = ConfigValue
from tb_Config
where AccessScopeID = -1 -- Med Converter
and ConfigName = @ConfigParamName

if ( @CompleteFilePath is NULL )
Begin

		set @ErrorDescription = 'Error !!! No entry exists for the configuration parameter : ' + @ConfigParamName
		set @ResultFlag = 1
		Return 1

End

------------------------------------------------------------------------
-- Check to ensure that the file exists at the particular location
------------------------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist  @CompleteFilePath , @FileExists output 

If (@FileExists <> 1)
Begin

		set @ErrorDescription = 'Error !!! The file : ' + @CompleteFilePath + ' does not exist or is invalid path'
		set @ResultFlag = 1
		set @CompleteFilePath = NULL
		Return 1

End


----------------------------------------------------------
-- Ensure that the Config File is an XML file, as it needs
-- to be read and translated
----------------------------------------------------------

Declare @FileExtension varchar(100)

if (@ConfigParamName = 'ConfigFilePath')
Begin

		set @FileExtension = reverse(substring(reverse(@CompleteFilePath) , 1 , charindex('.' , reverse(@CompleteFilePath))))

		if (@FileExtension <> '.xml')
		Begin

				set @ErrorDescription = 'Error !!! the config file : ' + @CompleteFilePath + ' is not an XML file'
				set @ResultFlag = 1
				set @CompleteFilePath = NULL
				Return 1

		End

End

Return 0



GO
