USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtractAlert]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRExtractAlert]
(
	@CDRExtractID int
)
As

Declare @To varchar(1000) ,
		@Subject varchar(500) ,
		@EmailBody varchar(max),
		@LogFileName varchar(1000) = NULL

Declare @CDRExtractName varchar(200),
        @CDRExtractRequestDate datetime,
		@CDRExtractStatusID int,
		@CDRExtractCompletionDate datetime,
		@UserID int,
		@CDRExtractFileName varchar(100)

-----------------------------------------
-- Get the details for the CDR Extract
-----------------------------------------

select @CDRExtractName =  CDRExtractName,
       @CDRExtractRequestDate = CDRExtractRequestDate,
	   @CDRExtractStatusID = CDRExtractStatusID,
	   @CDRExtractCompletionDate  = CDRExtractCompletionDate,
	   @UserID = UserID,
	   @CDRExtractFileName  = CDRExtractFileName
from tb_CDRExtract
where CDRExtractID = @CDRExtractID

----------------------------------------------------------
-- Get the email address for the user to whom alert needs
-- to be send
-----------------------------------------------------------

select @To = EmailID
from ReferenceServer.UC_Admin.dbo.tb_Users
where userid = @UserID

------------------------------------------------------------
-- Prepare the Subject and message based on the status of
-- the CDR Extract
------------------------------------------------------------

if ( @CDRExtractStatusID = -1 ) -- Registered
Begin

		set @Subject = 'CDR Extract : Extract ID ' + convert(varchar(10) , @CDRExtractID) + ' : ' + 'Registered or Re-Registered'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'CDR Extract by name : ' + '<b> (' + @CDRExtractName + ') </b>' + 
						 ' has been registerd in the system on date : ' + '<b> (' + convert(varchar(20) , @CDRExtractRequestDate , 120) + ') </b>' + 
						 '<br><br>' +
						 'You will be alerted once the extract is initiated and completed' +
						 '<br><br>' +
						 'Regards <br> UClick CDR Extract System'

End

if ( @CDRExtractStatusID = -2 ) -- Running
Begin

		set @Subject = 'CDR Extract : Extract ID ' + convert(varchar(10) , @CDRExtractID) + ' : ' + 'Running'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'CDR Extract by name : ' + '<b> (' + @CDRExtractName + ') </b>' + 
						 ' is currently selected and data extract is running' +
						 '<br><br>' +
						 'You will be alerted regarding the next status and availability of extract file' +
						 '<br><br>' +
						 'Regards <br> UClick CDR Extract System'

End

if ( @CDRExtractStatusID = -3 ) -- Completed
Begin

		set @Subject = 'CDR Extract : Extract ID ' + convert(varchar(10) , @CDRExtractID) + ' : ' + 'Completed'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'CDR Extract by name : ' + '<b> (' + @CDRExtractName + ') </b>' + 
						 ' has successfully completed on date : ' + '<b> (' + convert(varchar(20) , @CDRExtractCompletionDate , 120) + ') </b>' + 
						 ' and extract file : '+ '<b> (' + @CDRExtractFileName + ') </b>' + ' is available for download' +
						 '<br><br>' +
						 'Regards <br> UClick CDR Extract System'
End


if ( @CDRExtractStatusID = -4 ) -- Failed
Begin

		set @Subject = 'CDR Extract : Extract ID ' + convert(varchar(10) , @CDRExtractID) + ' : ' + 'Failed'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'CDR Extract by name : ' + '<b> (' + @CDRExtractName + ') </b>' + 
						 ' has failed during the extraction process due to some reason' + 
						 '<br><br>' + 
						 ' Please login to the GUI to see more details regarding failure' +
						 '<br><br>' +
						 'Regards <br> UClick CDR Extract System'
End


if ( @CDRExtractStatusID = -5 ) -- Cancelled
Begin

		set @Subject = 'CDR Extract : Extract ID ' + convert(varchar(10) , @CDRExtractID) + ' : ' + 'Cancelled'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'CDR Extract by name : ' + '<b> (' + @CDRExtractName + ') </b>' + 
						 ' has has been cancelled.' + 
						 '<br><br>' + 
						 'Regards <br> UClick CDR Extract System'
End


-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName


GO
