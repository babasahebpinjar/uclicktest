USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogExtractAlert]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[SP_BSMasterlogExtractAlert]
(
	@MasterlogExtractID int
)
As

Declare @To varchar(1000) ,
		@Subject varchar(500) ,
		@EmailBody varchar(max),
		@LogFileName varchar(1000) = NULL

Declare @MasterlogExtractName varchar(200),
        @MasterlogExtractRequestDate datetime,
		@MasterlogExtractStatusID int,
		@MasterlogExtractCompletionDate datetime,
		@UserID int,
		@MasterlogExtractFileName varchar(100)

-----------------------------------------
-- Get the details for the Masterlog Extract
-----------------------------------------

select @MasterlogExtractName =  MasterlogExtractName,
       @MasterlogExtractRequestDate = MasterlogExtractRequestDate,
	   @MasterlogExtractStatusID = MasterlogExtractStatusID,
	   @MasterlogExtractCompletionDate  = MasterlogExtractCompletionDate,
	   @UserID = UserID,
	   @MasterlogExtractFileName  = MasterlogExtractFileName
from tb_MasterlogExtract
where MasterlogExtractID = @MasterlogExtractID

----------------------------------------------------------
-- Get the email address for the user to whom alert needs
-- to be send
-----------------------------------------------------------

select @To = EmailID
from ReferenceServer.UC_Admin.dbo.tb_Users
where userid = @UserID

------------------------------------------------------------
-- Prepare the Subject and message based on the status of
-- the Masterlog Extract
------------------------------------------------------------

if ( @MasterlogExtractStatusID = -1 ) -- Registered
Begin

		set @Subject = 'Masterlog Extract : Extract ID ' + convert(varchar(10) , @MasterlogExtractID) + ' : ' + 'Registered or Re-Registered'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Masterlog Extract by name : ' + '<b> (' + @MasterlogExtractName + ') </b>' + 
						 ' has been registerd in the system on date : ' + '<b> (' + convert(varchar(20) , @MasterlogExtractRequestDate , 120) + ') </b>' + 
						 '<br><br>' +
						 'You will be alerted once the extract is initiated and completed' +
						 '<br><br>' +
						 'Regards <br> UClick Masterlog Extract System'

End

if ( @MasterlogExtractStatusID = -2 ) -- Running
Begin

		set @Subject = 'Masterlog Extract : Extract ID ' + convert(varchar(10) , @MasterlogExtractID) + ' : ' + 'Running'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Masterlog Extract by name : ' + '<b> (' + @MasterlogExtractName + ') </b>' + 
						 ' is currently selected and data extract is running' +
						 '<br><br>' +
						 'You will be alerted regarding the next status and availability of extract file' +
						 '<br><br>' +
						 'Regards <br> UClick Masterlog Extract System'

End

if ( @MasterlogExtractStatusID = -3 ) -- Completed
Begin

		set @Subject = 'Masterlog Extract : Extract ID ' + convert(varchar(10) , @MasterlogExtractID) + ' : ' + 'Completed'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Masterlog Extract by name : ' + '<b> (' + @MasterlogExtractName + ') </b>' + 
						 ' has successfully completed on date : ' + '<b> (' + convert(varchar(20) , @MasterlogExtractCompletionDate , 120) + ') </b>' + 
						 ' and extract file : '+ '<b> (' + @MasterlogExtractFileName + ') </b>' + ' is available for download' +
						 '<br><br>' +
						 'Regards <br> UClick Masterlog Extract System'
End


if ( @MasterlogExtractStatusID = -4 ) -- Failed
Begin

		set @Subject = 'Masterlog Extract : Extract ID ' + convert(varchar(10) , @MasterlogExtractID) + ' : ' + 'Failed'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Masterlog Extract by name : ' + '<b> (' + @MasterlogExtractName + ') </b>' + 
						 ' has failed during the extraction process due to some reason' + 
						 '<br><br>' + 
						 ' Please login to the GUI to see more details regarding failure' +
						 '<br><br>' +
						 'Regards <br> UClick Masterlog Extract System'
End


if ( @MasterlogExtractStatusID = -5 ) -- Cancelled
Begin

		set @Subject = 'Masterlog Extract : Extract ID ' + convert(varchar(10) , @MasterlogExtractID) + ' : ' + 'Cancelled'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Masterlog Extract by name : ' + '<b> (' + @MasterlogExtractName + ') </b>' + 
						 ' has has been cancelled.' + 
						 '<br><br>' + 
						 'Regards <br> UClick Masterlog Extract System'
End


-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec REFERENCESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName




/****** Object:  StoredProcedure [dbo].[SP_UIGetMasterLogExtractFilePath]    Script Date: 24-04-2019 13:45:02 ******/
SET ANSI_NULLS ON
GO
