USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSIncomingTrafficUnBlock]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SP_BSIncomingTrafficUnBlock]
(
	@AccountID INT,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag INT Output 
)

AS


IF CURSOR_STATUS('global','DB_GET_TRUNKS') >= -1
BEGIN
 DEALLOCATE DB_GET_TRUNKS
END


DECLARE @VirtualNetworkID INT,
        @TrunkGroupID INT,
		@TrunkGroupName VARCHAR(1000),
		@CRFRouteProfileID INT,
		@TrunkID INT

DECLARE @XMLHeader VARCHAR(2000)
DECLARE @XMLFooter VARCHAR(2000)
DECLARE @XMLRecordList VARCHAR(3000)
DECLARE @Record VARCHAR(2000)
DECLARE @XMLFile VARCHAR(2000)
DECLARE @XMLFileName VARCHAR(1000)
DECLARE @XmlFileLocalPath varchar(1000)
DECLARE @ExecutionStatus INT
DECLARE @Result INT
DECLARE @localFileGenerated INT
DECLARE @RemoteFileGenerated INT


DECLARE @cmd VARCHAR(3000)
DECLARE @CmdOutput VARCHAR(2000)
DECLARE @bcpCommand VARCHAR(3000)

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
Declare @To varchar(1000) ,
@Subject varchar(500) ,
@EmailBody varchar(max),
@LogFileName varchar(1000) = NULL

SET @bcpServer=@@ServerName
SET @RemoteFileGenerated = 0
SET @localFileGenerated = 0


SELECT @To = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'TrafficBlockUnblockMailingList'
and AccessScopeID = -4 -- Reference Module

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

SET @ExecutionStatus = 0
SET @XMLRecordList = ''
SELECT @AccountName  = Account FROM tb_Account WHERE AccountID = @AccountID

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
begin
SET @ErrorDescription = 'ERROR !!! Login failed, Incorrect Username or Password..!'
SET @ResultFlag = 1
GOTO ENDPROCESS
end

IF @Result = 20
begin
SET @ErrorDescription = 'ERROR !!! Connection timed out'
SET @ResultFlag = 1
GOTO ENDPROCESS
end

IF @Result = 40
begin
SET @ErrorDescription = 'ERROR !!! Unable to authenticate'
SET @ResultFlag = 1
GOTO ENDPROCESS

end

IF @Result = 50
begin
SET @ErrorDescription = 'ERROR !!! Directory%failure'
SET @ResultFlag = 1
GOTO ENDPROCESS
end

IF @Result = 60
begin
SET @ErrorDescription = 'ERROR !!! No such file or directory'
SET @ResultFlag = 1
GOTO ENDPROCESS
end

----------------------------------------------------------
--CHECKING THE VALIDITY OF THE ACCOUNT ID
----------------------------------------------------------

SELECT @Result = COUNT(*) FROM tb_Account WHERE AccountID = @AccountID

IF @Result = 0
BEGIN
SET @ErrorDescription = 'ERROR !!! Invalid Account ID.' 
SET @ResultFlag = 1
GOTO ENDPROCESS
END


-----------------------------------------------------------------------
-- Checking IF the given account has physical trunks associated with it
-----------------------------------------------------------------------
SELECT @Result = COUNT(*)
FROM tb_Account tbl1
INNER JOIN tb_Trunk tbl2 on tbl1.AccountID = tbl2.AccountID
WHERE tbl1.AccountID = @AccountID



IF @Result = 0
BEGIN
SET @ErrorDescription = 'ERROR !!! No physical trunks are configured for this account.'
SET @ResultFlag = 1
GOTO ENDPROCESS
END



-----------------------------------------------------------
-- GENERATING THE XML FILE FOR THE EXECUTION
-----------------------------------------------------------

SET @XMLHeader = '<config ne="ne-xxx" ne-version="R18.5" ne-type="SBC-signaling" soi-version="1.0">
<IbcfTrunkGroupTable xmlns="http://nokia.com/yang/isbc-sig">
<ID>4</ID>
<NAME>IBCF TG 4</NAME>
'

SET @XMLFooter = '</IbcfTrunkGroupTable>
</config>'

BEGIN TRY

DECLARE DB_GET_TRUNKS CURSOR FOR  

SELECT  
		tbl1.TrunkID AS TrunkID,
		CONVERT(INT,SUBSTRING(tbl1.OrigPointCode,1,4)) AS VirtualNetworkID,
		CONVERT(INT,SUBSTRING(tbl1.OrigPointCode,5,8)) AS TrunkGroupID,
		CONVERT(INT,tbl1.PointCode) AS CRFRouteProfileID	

		FROM tb_Trunk tbl1
	INNER JOIN tb_Account tbl3 ON tbl1.AccountID = tbl3.AccountID
	WHERE tbl3.AccountID = @AccountID 
	AND tbl1.ReportCode = 'Incoming Blocked'
	AND tbl1.TrunkTypeID = 4 -- Technical Trunks
	ORDER BY TrunkGroupID


OPEN DB_GET_TRUNKS   
FETCH NEXT FROM DB_GET_TRUNKS
INTO @TrunkID, @VirtualNetworkID , @TrunkGroupID ,@CRFRouteProfileID

IF @@CURSOR_ROWS = 0
BEGIN

		SET @ErrorDescription = 'ERROR !!! Trunks are already unblocked for this account : ' + @AccountName
		SET @ResultFlag = 1
		GOTO ENDPROCESS

END

WHILE @@FETCH_STATUS = 0   
BEGIN

SET @Record = '<Record>
	<VN_ID>'+CONVERT(VARCHAR(10),@VirtualNetworkID)+'</VN_ID>
	<TG_ID>'+CONVERT(VARCHAR(10),@TrunkGroupID)+'</TG_ID>
	<CRF_ROUTINE_PROFILE_ID>'+CONVERT(VARCHAR(10),@CRFRouteProfileID)+'</CRF_ROUTINE_PROFILE_ID>
</Record>
' 

--SET @XMLFile = @XMLHeader + @Record + @XMLFooter

SET @XMLRecordList = @XMLRecordList +  @Record 

FETCH NEXT FROM DB_GET_TRUNKS
INTO @TrunkID, @VirtualNetworkID , @TrunkGroupID  ,@CRFRouteProfileID 
 
END

END TRY

BEGIN CATCH

		SET @ErrorDescription = 'ERROR !!! Getting the Trunks from the IBCF TRUNK TABLE.' + ERROR_MESSAGE()
		SET @ResultFlag = 1

		CLOSE DB_GET_TRUNKS  
		DEALLOCATE DB_GET_TRUNKS

		--GOTO ENDPROCESS

END CATCH


CLOSE DB_GET_TRUNKS

DEALLOCATE DB_GET_TRUNKS
-- End of the Cursor


-- Create the XML File

SET @XMLFile = @XMLHeader + @XMLRecordList + @XMLFooter

IF EXISTS (SELECT 1 from tempdb.dbo.sysobjects WHERE xtype = 'U' and id = object_id(N'tempdb..##XMLFile') )
Drop table ##XMLFile

CREATE TABLE ##XMLFile(contents nvarchar(max))

INSERT INTO ##XMLFile(contents) SELECT @XMLFile

SElECT * from ##XMLFile

SET @XMLFileName = 'UNBLOCK'+ '_' + FORMAT(getdate(), 'yyyyMMddhhmmss') + '_' + CONVERT(VARCHAR,@AccountID) + '.xml'

DECLARE @ABSOLUTEXMLFileName VARCHAR(1000)

SET @AbSOLUTEXMLFileName = @XmlFileLocalPath + @XMLFileName

SET @bcpCommand = 'bcp "SELECT contents from ##XMLFile" queryout '+ @ABSOLUTEXMLFileName + ' -c -t, -T -S '+ @bcpServer



EXEC @Result = master..xp_cmdshell @bcpCommand

-- Checking for the Return Status from the Command Line

IF @Result <> 0
BEGIN 

SET @ErrorDescription = 'ERROR !!! GENERATING THE XML FILE ' + CONVERT(VARCHAR(10),@Result)
SET @ResultFlag = 1
GOTO ENDPROCESS

END 

SET @localFileGenerated = 1


-----------------------------------------------------------
-- TRANSFERRING THE XML FILE TO THE SBC FOR THE EXECUTION
-----------------------------------------------------------
-- Creating temp table for storing return values
IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE xtype = 'U' and id = object_id(N'tempdb..#CmdOuputTbl') )
DROP TABLE #CmdOuputTbl

CREATE TABLE #CmdOuputTbl(message nvarchar(max)) 

set @cmd =  @pscpExecutable + ' -pw ' + @SwitchPassword + ' ' + @ABSOLUTEXMLFileName + ' ' +  @SwitchUserName+ '@' + @SwitchIpaddress + ':' + @SwitchXMLPath + @XMLFileName


INSERT INTO #CmdOuputTbl(message) EXEC master..xp_cmdshell @cmd
--SELECT * from #xyzout

SELECT @CmdOutput = count(*) from #CmdOuputTbl
WHERE message like '%Connection timed out%'
IF @CmdOutput <> 0
BEGIN 
SET @ErrorDescription = 'ERROR !!! SSH TIMED OUT DURING THE FILE TRANSFER' 
SET @ResultFlag = 1
GOTO ENDPROCESS
END

SELECT @CmdOutput = count(*) from #CmdOuputTbl
WHERE message like '%No such file or directory%'
IF @CmdOutput <> 0
BEGIN 
SET @ErrorDescription = 'ERROR !!! Remote Path not found' 
SET @ResultFlag = 1
GOTO ENDPROCESS
END

SELECT @CmdOutput = count(*) from #CmdOuputTbl
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

SELECT @CmdOutput = count(*) from #CmdOuputTbl
WHERE message like '%No such file or directory%'
IF @CmdOutput <> 0
BEGIN 
SET @ErrorDescription = 'ERROR !!! No such file or directory' 
SET @ResultFlag = 1
GOTO ENDPROCESS
END


SELECT @CmdOutput = count(*) from #CmdOuputTbl
WHERE message like '%is not recognized as an internal or external command%'
IF @CmdOutput <> 0
BEGIN 
SET @ErrorDescription = 'ERROR !!! plink is not installed or path is not set' 
SET @ResultFlag = 1
GOTO ENDPROCESS
END

SET @RemoteFileGenerated = 1
---------------------------------------------------------------
-- EXECUTION OF THE GENERATED XML OVER THE SBC SWITCH USING SSH	
---------------------------------------------------------------

SET @cmd = @plinkExecutable + ' -ssh -batch -pw ' + @SwitchPassword + ' ' + @SwitchUserName+ '@' + @SwitchIpaddress + ' ' + @NetconfProvPath + ' --plane signaling --host ' + @EMSIPAdress + ' --user ' + @EMSUsername +' --passwd '+@EMSPassword + ' --onerror abort ' + @SwitchXMLPath + @XMLFileName

-- EXECUTE 
INSERT INTO #CmdOuputTbl(message) EXEC master..xp_cmdshell @cmd


SELECT @CmdOutput = count(*) from #CmdOuputTbl
WHERE message like '%is not recognized as an internal or external command%'
IF @CmdOutput <> 0
BEGIN 
SET @ErrorDescription = 'ERROR !!! plink is not installed or path is not set' 
SET @ResultFlag = 1
GOTO ENDPROCESS
END

SELECT @ExecutionStatus = count(*) FROM #CmdOuputTbl
WHERE message like '%Error%'

IF @ExecutionStatus !=0 
BEGIN 
SELECT @ErrorDescription  = COALESCE(@ErrorDescription + ', ', '') + message FROM #CmdOuputTbl WHERE message like '%Error%'
--SELECT @ErrorDescription
SET @ResultFlag = 1
GOTO ENDPROCESS
END


-----------------------------------------------------------
-- Updation of the block status
-----------------------------------------------------------


BEGIN TRY
-- Updating the Block Status at the Table
IF(@ExecutionStatus = 0)

BEGIN

DECLARE DB_GET_TRUNKS CURSOR FOR  

SELECT  
		tbl1.TrunkID AS TrunkID,
		CONVERT(INT,SUBSTRING(tbl1.OrigPointCode,1,4)) AS VirtualNetworkID,
		CONVERT(INT,SUBSTRING(tbl1.OrigPointCode,5,8)) AS TrunkGroupID,
		CONVERT(INT,tbl1.PointCode) AS CRFRouteProfileID	

		FROM tb_Trunk tbl1
	INNER JOIN tb_Account tbl3 ON tbl1.AccountID = tbl3.AccountID
	WHERE tbl3.AccountID = @AccountID 
	AND tbl1.ReportCode = 'Incoming Blocked'
	AND tbl1.TrunkTypeID = 4 -- Technical Trunks
	ORDER BY TrunkGroupID


OPEN DB_GET_TRUNKS  
FETCH NEXT FROM DB_GET_TRUNKS
INTO @TrunkID, @VirtualNetworkID , @TrunkGroupID ,@CRFRouteProfileID


WHILE @@FETCH_STATUS = 0  
BEGIN

UPDATE tb_Trunk SET ReportCode = 'Incoming UnBlocked'
--WHERE OrigPointCode = FORMAT(@VirtualNetworkID,'D4') + FORMAT(@TrunkGroupID,'D4') 
WHERE TrunkID = @TrunkID
  
FETCH NEXT FROM DB_GET_TRUNKS
INTO @TrunkID, @VirtualNetworkID , @TrunkGroupID ,@CRFRouteProfileID
 
END

CLOSE DB_GET_TRUNKS

DEALLOCATE DB_GET_TRUNKS

END

END TRY

BEGIN CATCH

SET @ErrorDescription = 'ERROR !!! Getting the Trunks from the IBCF TRUNK TABLE.' + ERROR_MESSAGE()
SET @ResultFlag = 1

CLOSE DB_GET_TRUNKS  
DEALLOCATE DB_GET_TRUNKS

GOTO ENDPROCESS

END CATCH

-- Send mail

-----------------------------------------------------------
-- DELETION OF THE GENERATED XML OVER THE SBC SWITCH USING SSH	
-----------------------------------------------------------
--SET @ErrorDescription = 'SUCESS'
ENDPROCESS:
print ' Enterred ENDPROCESS:'

-- Delete Local File
IF @LocalFileGenerated = 1
BEGIN
SET @cmd = 'del  ' + @ABSOLUTEXMLFileName
-- EXECUTE
--insert into #CmdOuputTbl(message) exec master..xp_cmdshell @cmd
END


-- Delete Remote File
IF @RemoteFileGenerated = 1
BEGIN
SET @cmd = @plinkExecutable + ' -ssh -batch -pw ' + @SwitchPassword +  ' ' + @SwitchUserName+ '@' + @SwitchIpaddress + ' ' + ' rm ' + @SwitchXMLPath + @XMLFileName
-- EXECUTE
--insert into #CmdOuputTbl(message) exec master..xp_cmdshell @cmd
END

-----------
--send mail
-----------

set @Subject =  ' Incoming Traffic Blocking/Unblocking for ' +   @AccountName  + ' Account - ' +  CONVERT(varchar, GETDATE()) 

If @ErrorDescription is NULL
BEGIN

set @EmailBody = 'Dear User,' + '<br><br>' +
'The Account is <b>UNBLOCKED</b> Succesfully  on : ' + '<b> (' +  CONVERT(varchar, GETDATE()) + ') </b>' +
'<br><br>' +
'Incoming traffic will be allowed for this account until it is blocked' +
'<br><br>' +
'Regards <br> UClick Blocking/Unblocking'
END

IF @ErrorDescription is not NULL
BEGIN

set @EmailBody = 'Dear User,' + '<br><br>' +
'Error occurred during <b>UNBLOCKING</b> on : ' + '<b> (' +  CONVERT(varchar, GETDATE()) + ') </b>' +
'<br><br>' + @ErrorDescription +
'<br><br>' +
'Regards <br> UClick Blocking/Unblocking'
END


print 'Enterred sending mail'
Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName

GO
