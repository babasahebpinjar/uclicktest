USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCustomExecuteXML]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[SP_BSCustomExecuteXML]
(
	@XMLFileName VARCHAR(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag INT Output 
)

AS


DECLARE @cmd VARCHAR(3000)
DECLARE @CmdOutput VARCHAR(2000)
DECLARE @bcpCommand VARCHAR(3000)

DECLARE @XmlFileLocalPath varchar(1000)
DECLARE @ABSOLUTEXMLFileName VARCHAR(1000)

DECLARE @SwitchUserName VARCHAR(255)
DECLARE @SwitchIpaddress VARCHAR(255)
DECLARE @NetconfProvPath VARCHAR(255)
DECLARE @EMSIPAdress VARCHAR(255)
DECLARE @EMSUsername VARCHAR(255)
DECLARE @EMSPassword VARCHAR(255)
DECLARE @SwitchXMLPath VARCHAR(255)
DECLARE @SwitchPassword VARCHAR(255)
DECLARE @bcpServer VARCHAR(255)
DECLARE @plinkExecutable VARCHAR(255)
DECLARE @pscpExecutable VARCHAR(255)
DECLARE @AccountName VARCHAR(255)



DECLARE @Result INT
DECLARE @ExecutionStatus INT


SELECT @SwitchUserName = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'SwitchUsername'
and AccessScopeID = -4 -- Reference Module

SELECT @SwitchIpaddress = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'SwitchIPAddress'
and AccessScopeID = -4 -- Reference Module

SELECT @NetconfProvPath = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'NetConfProvPath'
and AccessScopeID = -4 -- Reference Module

SELECT @EMSIPAdress = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'EMSIPAddress'
and AccessScopeID = -4 -- Reference Module

SELECT @EMSUsername = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'EMSUsername'
and AccessScopeID = -4 -- Reference Module

SELECT @EMSPassword = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'EMSPassword'
and AccessScopeID = -4 -- Reference Module

SELECT @SwitchXMLPath = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'SwitchXMLFilePath'
and AccessScopeID = -4 -- Reference Module

SELECT @XmlFileLocalPath = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'XmlFileLocalPath'
and AccessScopeID = -4 -- Reference Module

SELECT @SwitchPassword = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'SwitchPassword'
and AccessScopeID = -4 -- Reference Module

SELECT @plinkExecutable = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'plinkExecutable'
and AccessScopeID = -1 -- Reference Module

SELECT @pscpExecutable = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'pscpExecutable'
and AccessScopeID = -1 -- Reference Module



----------------------------------------------------------
-- Check FTP connection
----------------------------------------------------------

EXEC	[dbo].[SP_BSCheckFTPConnection]
		@FTPSiteIPAddress = @SwitchIpaddress,
		@FTPSiteUsername = @SwitchUserName,
		@FTPSitePassword = @SwitchPassword,
		@WorkDirectory = @XmlFileLocalPath,
		@ResultFlag = @Result OUTPUT


IF @Result = 10
BEGIN
	SET @ErrorDescription = 'ERROR !!! Login failed, Incorrect Username or Password..!'
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

IF @Result = 20
BEGIN
	SET @ErrorDescription = 'ERROR !!! Connection timed out..!'
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

IF @Result = 40
BEGIN
	SET @ErrorDescription = 'ERROR !!! Unable to authenticate..!'
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

IF @Result = 50
BEGIN
	SET @ErrorDescription = 'ERROR !!! The specified Directory is not found..!'
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

IF @Result = 60
BEGIN
	SET @ErrorDescription = 'ERROR !!! No such file or directory..!'
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END


-----------------------------------------------------------
-- TRANSFERRING THE XML FILE TO THE SBC FOR THE EXECUTION
-----------------------------------------------------------
-- Creating temp table for storing return values
IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE xtype = 'U' and id = object_id(N'tempdb..#CmdOuputTbl') )
	DROP TABLE #CmdOuputTbl

CREATE TABLE #CmdOuputTbl(message nvarchar(max)) 

SET @AbSOLUTEXMLFileName = @XmlFileLocalPath + @XMLFileName

set @cmd =  @pscpExecutable + ' -pw ' + @SwitchPassword + ' ' + @ABSOLUTEXMLFileName + ' ' +  @SwitchUserName+ '@' + @SwitchIpaddress + ':' + @SwitchXMLPath + @XMLFileName

-- Creating temp table for storing return values

INSERT INTO #CmdOuputTbl(message) EXEC master..xp_cmdshell @cmd
--SELECT * from #CmdOuputTbl

SELECT @CmdOutput = count(*) 
FROM #CmdOuputTbl
WHERE message like '%Connection timed out%'

IF @CmdOutput <> 0
BEGIN 
	SET @ErrorDescription = 'ERROR !!! SSH Timed out during file transfer' 
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

SELECT @CmdOutput = count(*) 
FROM #CmdOuputTbl
WHERE message like '%No such file or directory%'

IF @CmdOutput <> 0
BEGIN 
	SET @ErrorDescription = 'ERROR !!! Remote Path not found' 
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

SELECT @CmdOutput = count(*) 
FROM #CmdOuputTbl
WHERE message like '%is not recognized as an internal or external command%'

IF @CmdOutput <> 0
BEGIN 
	SET @ErrorDescription = 'ERROR !!! pscp is not installed or the path is not set' 
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

-----------------------------------------------------------
-- CHECKING IF THE FILE IS PRESENT
-----------------------------------------------------------

SET @cmd = @plinkExecutable + ' -ssh -batch -pw ' + @SwitchPassword + ' ' + @SwitchUserName+ '@' + @SwitchIpaddress +  ' ls ' + @SwitchXMLPath +@XMLFileName 

INSERT INTO #CmdOuputTbl(message) EXEC master..xp_cmdshell @cmd

SELECT @CmdOutput = count(*) 
FROM #CmdOuputTbl
WHERE message like '%No such file or directory%'

IF @CmdOutput <> 0
BEGIN 
	SET @ErrorDescription = 'ERROR !!! No such file or directory' 
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END


SELECT @CmdOutput = count(*) 
FROM #CmdOuputTbl
WHERE message like '%is not recognized as an internal or external command%'

IF @CmdOutput <> 0
BEGIN 
	SET @ErrorDescription = 'ERROR !!! plink is not installed or path is not set' 
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

---------------------------------------------------------------
-- EXECUTION OF THE GENERATED XML OVER THE SBC SWITCH USING SSH	
---------------------------------------------------------------

SET @cmd = @plinkExecutable + ' -ssh -batch -pw ' + @SwitchPassword + ' ' + @SwitchUserName+ '@' + @SwitchIpaddress + ' ' + @NetconfProvPath + ' --plane signaling --host ' + @EMSIPAdress + ' --user ' + @EMSUsername +' --passwd '+@EMSPassword + ' --onerror abort ' + @SwitchXMLPath + @XMLFileName
-- EXECUTE 
INSERT INTO #CmdOuputTbl(message) EXEC master..xp_cmdshell @cmd

SELECT @CmdOutput = count(*) 
FROM #CmdOuputTbl
WHERE message like '%is not recognized as an internal or external command%'

IF @CmdOutput <> 0
BEGIN 
	SET @ErrorDescription = 'ERROR !!! plink is not installed or path is not set' 
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END

SELECT @ExecutionStatus = count(*) 
FROM #CmdOuputTbl
WHERE message like '%Error%'

IF @ExecutionStatus !=0 
BEGIN 
	SELECT @ErrorDescription  = COALESCE(@ErrorDescription + ', ', '') + message FROM #CmdOuputTbl WHERE message like '%Error%'
	SELECT @ErrorDescription
	SET @ResultFlag = 1
	GOTO ENDPROCESS
END



-----------------------------------------------------------
-- DELETION OF THE GENERATED XML OVER THE SBC SWITCH USING SSH	
-----------------------------------------------------------

ENDPROCESS:
print 'Enterred ENDPROCESS'

-- Delete Remote File

SET @cmd = @plinkExecutable + ' -ssh -batch -pw ' + @SwitchPassword +  ' ' + @SwitchUserName+ '@' + @SwitchIpaddress + ' ' + ' rm ' + @SwitchXMLPath + @XMLFileName
SELECT @cmd
-- EXECUTE
--insert into #CmdOuputTbl(message) exec master..xp_cmdshell @cmd


GO
