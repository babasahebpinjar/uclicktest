USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCustomCreateXML]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_BSCustomCreateXML]
(	
	@ErrorDescription varchar(2000) Output,
	@ResultFlag INT Output ,
	@XmlFilePath varchar(2000) OUTPUT
)

AS

IF CURSOR_STATUS('global','DB_GET_TRUNKS') >= -1
BEGIN
 DEALLOCATE DB_GET_TRUNKS
END


DECLARE @VirtualNetworkID INT,
        @TrunkGroupID INT,
		@TrunkGroupName VARCHAR(1000),
		@CRFRouteProfileID INT

DECLARE @XMLHeader VARCHAR(2000)
DECLARE @XMLFooter VARCHAR(2000)
--DECLARE @XMLRecordList VARCHAR(3000)


--- 
-- CHANGED THE DATATYPE OF @XMLRecordList FROM VARCHAR TO NVARCHAR(MAX)
-- TO INCREASE THE CAPACITY OF THE TRUNKS RECORD IN THE XML FILE

DECLARE @XMLRecordList NVARCHAR(max)
DECLARE @Record VARCHAR(2000)
--DECLARE @XMLFile VARCHAR(2000)
DECLARE @XMLFile NVARCHAR(max)
DECLARE @XMLFileName VARCHAR(1000)
DECLARE @XmlFileLocalPath varchar(1000)
DECLARE @ExecutionStatus INT
DECLARE @Result INT
DECLARE @ABSOLUTEXMLFileName VARCHAR(1000)
DECLARE @TASK VARCHAR(50)

DECLARE @cmd VARCHAR(3000)
DECLARE @CmdOutput VARCHAR(2000)
DECLARE @bcpCommand VARCHAR(3000)
DECLARE @bcpServer VARCHAR(255)

SET @bcpServer=@@ServerName



SELECT @XmlFileLocalPath = ConfigValue
FROM ReferenceServer.UC_Admin.dbo.tb_Config
WHERE ConfigName = 'XmlFileLocalPath'
and AccessScopeID = -4 -- Reference Module


SET @ExecutionStatus = 0
SET @XMLRecordList = ''



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
	SELECT  Distinct VirtualNetworkID,TrunkGroupID,CRFRouteProfileID FROM #TempElementData 

	OPEN DB_GET_TRUNKS   
	FETCH NEXT FROM DB_GET_TRUNKS
	INTO @VirtualNetworkID , @TrunkGroupID ,@CRFRouteProfileID

	IF @@CURSOR_ROWS = 0
	BEGIN

			SET @ErrorDescription = 'ERROR !!! Trunks are already in the same state for this account (change the statement)' 
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


		SET @XMLRecordList = @XMLRecordList +  @Record 
		FETCH NEXT FROM DB_GET_TRUNKS
		INTO @VirtualNetworkID , @TrunkGroupID  ,@CRFRouteProfileID 
 
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
--SELECT * from ##XMLFile

SET @XMLFileName = 'ExternalNetworkAction' + '_' + FORMAT(getdate(), 'yyyyMMddhhmmss')  + '.xml'
SET @AbSOLUTEXMLFileName = @XmlFileLocalPath + @XMLFileName
SET @bcpCommand = 'bcp "SELECT contents from ##XMLFile" queryout '+ @ABSOLUTEXMLFileName + ' -c -t, -T -S '+ @bcpServer

--PRINT @bcpCommand
EXEC @Result = master..xp_cmdshell @bcpCommand

-- Checking for the Return Status from the Command Line

IF @Result <> 0
BEGIN 

	SET @ErrorDescription = 'ERROR !!! GENERATING THE XML FILE ' + CONVERT(VARCHAR(10),@Result)
	SET @ResultFlag = 1
	GOTO ENDPROCESS

END 

print @ABSOLUTEXMLFileName
set @XmlFilePath = @ABSOLUTEXMLFileName
ENDPROCESS:



GO
