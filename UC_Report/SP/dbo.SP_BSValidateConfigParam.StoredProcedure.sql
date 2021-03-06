USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSValidateConfigParam]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSValidateConfigParam]
(
	@AccessScopeID int,
	@ConfigName varchar(200) = NULL,
	@ConfigValue varchar(1000) = NULL,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @ConfigDataTypeID int,
		@TempConfigName varchar(200),
		@Command varchar(2000),
		@FileExists int,
		@AccessScopeName varchar(100)


-------------------------------------------
-- Check if the Access Scope exists or not
-------------------------------------------

if not exists ( select 1 from TB_Masterlog_AccessScope where AccessScopeID = @AccessScopeID )
Begin

	 set @ErrorDescription = 'ERROR: Access Scope or Module does not exists in the system configuration '
	 --Raiserror('%s' ,16, 1, @ErrorDescription) 
	 set @ResultFlag = 1
     return 1		

End


Select @AccessScopeName = AccessScopeName
from TB_Masterlog_AccessScope
where AccessScopeID = @AccessScopeID


---------------------------------------------------------------
-- Check to ensure that the config being validated exists in
-- the Config table
---------------------------------------------------------------

if not exists ( select 1 from TB_Masterlog_Config where ConfigName = @ConfigName and AccessScopeID = @AccessScopeID  )
Begin

		set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' does not exist under the module or scope : ' + @AccessScopeName
		--Raiserror('%s' ,16, 1, @ErrorDescription) 
		set @ResultFlag = 1
		return 1		

End

-----------------------------------------------------------------
-- Get the Config Data Type of the Parameter to establish the
-- Validation process
-----------------------------------------------------------------

select @ConfigDataTypeID = ConfigDataTypeID
from TB_Masterlog_Config 
where ConfigName = @ConfigName 
and AccessScopeID = @AccessScopeID

---------------------------------------------------------------
-- Plan the validation action, based on the configuration data
-- type
---------------------------------------------------------------

if ( @ConfigDataTypeID in (-3,-9) ) -- Folder or Log File Path
Begin

		create table #tempCommandoutput
		(
			CommandOutput varchar(500)
		)

End

------------------------------------------
-- Integer ConfigType should be numeric
------------------------------------------

if ( ( @ConfigDataTypeID = -1) and (ISNUMERIC(@ConfigValue) = 0) ) 
Begin

		set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( INTEGER ) and does not have numerical value defined'
		--Raiserror('%s' ,16, 1, @ErrorDescription) 
		set @ResultFlag = 1
		return 1

End

-------------------------------------------------------------
-- Numerical ConfigType should be numeric and greater than 0
-------------------------------------------------------------

if ( ( @ConfigDataTypeID = -2) and ( (ISNUMERIC(@ConfigValue) = 0) or (convert(int ,@ConfigValue) < 0 )) )
Begin

		set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( NUMERICAL ) and does not have numerical or greate tha 0 value defined'
		--Raiserror('%s' ,16, 1, @ErrorDescription) 
		set @ResultFlag = 1
		return 1

End


------------------------------------------------
-- Folder Path should exist and be accessible
------------------------------------------------

if (@ConfigDataTypeID = -3)
Begin

        set @TempConfigName = @ConfigValue

		delete from #tempCommandoutput

		if ( right(@TempConfigName , 1) <> '\')
				set @TempConfigName = @TempConfigName + '\'

		set @Command = 'dir ' + @TempConfigName + '/b'

		insert into #tempCommandoutput
		Exec master..xp_cmdshell @Command

  		if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the path specified.'  )
		Begin
				set @ResultFlag = 1
		End

  		if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the file specified.'  )
		Begin
				set @ResultFlag = 1
		End

		if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The network path was not found.'  )
		Begin
				set @ResultFlag = 1
		End

		Drop table #tempCommandoutput

		if ( @ResultFlag = 1)
		Begin

				set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( FOLDER PATH ) and does not exist or invalid'
				--Raiserror('%s' ,16, 1, @ErrorDescription) 
				return 1

		End
		
End

------------------------------------------------
-- File Name should exist and be accessible
------------------------------------------------

if (@ConfigDataTypeID = -4)
Begin

        set @FileExists = 0

	    Exec master..xp_fileexist @ConfigValue , @FileExists output 

		if ( @FileExists <> 1 )
		Begin
		     
			   set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( FILE NAME ) and does not exist or is unaccessible'
			   --Raiserror('%s' ,16, 1, @ErrorDescription) 
		       set @ResultFlag = 1

		End
	
End

------------------------------------------------
-- Email Address should be valid value
------------------------------------------------

if (@ConfigDataTypeID = -5)
Begin

    Declare @EmailAddress varchar(200)

	set @EmailAddress = LTRIM(RTRIM(@ConfigValue)) -- remove leading and trailing blanks

	set @ResultFlag = Case

				When patindex ('%[ &'',":;!+=\/()<>]%', @EmailAddress) > 0 then  1         -- Invalid characters
				When patindex ('[@.-_]%', @EmailAddress) > 0 then 1                        -- Valid but cannot be starting character
				When patindex ('%[@.-_]', @EmailAddress) > 0  then 1                       -- Valid but cannot be ending character
				When @EmailAddress not like '%@%.%'   then 1                               -- Must contain at least one @ and one .
				When @EmailAddress like '%..%'        then 1                               -- Cannot have two periods in a row
				When @EmailAddress like '%@%@%'       then 1                               -- Cannot have two @ anywhere
				When @EmailAddress like '%.@%' or @EmailAddress like '%@.%' then 1         -- Cant have @ and . next to each other
				When @EmailAddress like '%.cm' or @EmailAddress like '%.co' then 1         -- Unlikely. Probably typos 
				When @EmailAddress like '%.or' or @EmailAddress like '%.ne' then 1         -- Missing last letter
				When substring(@EmailAddress, 1,1) in ('|' , '-' , '_' , '<' , '>') then 1 -- Starts with special character
                Else 0
			End

 		if ( @ResultFlag = 1 )
		Begin
		     
			   set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( EMAIL ADDRESS ) and is not syntactically valid'
			   --Raiserror('%s' ,16, 1, @ErrorDescription) 
		       set @ResultFlag = 1

		End    
	
End


--------------------------------------------
-- File Extension should be valid
--------------------------------------------

if  ( (@ConfigDataTypeID = -6 ) and ( left(@ConfigValue , 1) <> '.' ) )
Begin

		set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( FILE EXTENSION ) and is not a valid value'
		--Raiserror('%s' ,16, 1, @ErrorDescription) 
		set @ResultFlag = 1


End


--------------------------------------------
-- Boolean should be value either 0 or 1
--------------------------------------------

if ( (@ConfigDataTypeID = -8) and ( convert(int ,@ConfigValue) not in (0,1)) )
Begin

		set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( BOOLEAN ) and does not have value as either 0 or 1'
		--Raiserror('%s' ,16, 1, @ErrorDescription) 
		set @ResultFlag = 1

End

----------------------------------------------------------------
-- Log File Path should have the Folder existing and accessible
----------------------------------------------------------------

if (@ConfigDataTypeID = -9)
Begin

        set @TempConfigName = reverse(substring(reverse(@ConfigValue),patindex( '%\%',reverse(@ConfigValue )),len(reverse(@ConfigValue))))

		Delete from #tempCommandoutput

		if ( right(@TempConfigName , 1) <> '\')
				set @TempConfigName = @TempConfigName + '\'

		set @Command = 'dir ' + @TempConfigName + '/b'

		insert into #tempCommandoutput
		Exec master..xp_cmdshell @Command

  		if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the path specified.'  )
		Begin
				set @ResultFlag = 1
		End

  		if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the file specified.'  )
		Begin
				set @ResultFlag = 1
		End

		if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The network path was not found.'  )
		Begin
				set @ResultFlag = 1
		End

		Drop table #tempCommandoutput

		if ( @ResultFlag = 1)
		Begin

				set @ErrorDescription = 'ERROR: Config parameter : '+ @ConfigName +' is of the type : ( LOG FILE PATH ) and does not exist or invalid'
				--Raiserror('%s' ,16, 1, @ErrorDescription) 
				return 1

		End
		
End


return 0
GO
