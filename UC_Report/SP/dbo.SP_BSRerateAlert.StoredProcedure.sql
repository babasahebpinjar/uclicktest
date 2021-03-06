USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRerateAlert]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRerateAlert]
(
	@RerateID int
)
As

Declare @To varchar(1000) ,
		@Subject varchar(500) ,
		@EmailBody varchar(max),
		@LogFileName varchar(1000) = NULL

Declare @RerateName varchar(200),
        @RerateRequestDate datetime,
		@RerateStatusID int,
		@RerateCompletionDate datetime,
		@UserID int,
		@RerateFileName varchar(100)

-----------------------------------------
-- Get the details for the Rerate Job
-----------------------------------------

select @RerateName =  RerateName,
       @RerateRequestDate = RerateRequestDate,
	   @RerateStatusID = RerateStatusID,
	   @RerateCompletionDate  = RerateCompletionDate,
	   @UserID = UserID
from tb_Rerate
where RerateID = @RerateID

----------------------------------------------------------
-- Get the email address for the user to whom alert needs
-- to be send
-----------------------------------------------------------

select @To = EmailID
from ReferenceServer.UC_Admin.dbo.tb_Users
where userid = @UserID

------------------------------------------------------------
-- Prepare the Subject and message based on the status of
-- the Rerate Job
------------------------------------------------------------

if ( @RerateStatusID = -1 ) -- Registered
Begin

		set @Subject = 'Rerate Job : Rerate ID ' + convert(varchar(10) , @RerateID) + ' : ' + 'Registered or Re-Registered'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Rerate Job by name : ' + '<b> (' + @RerateName + ') </b>' + 
						 ' has been registerd in the system on date : ' + '<b> (' + convert(varchar(20) , @RerateRequestDate , 120) + ') </b>' + 
						 '<br><br>' +
						 'You will be alerted once the rerate is initiated and completed' +
						 '<br><br>' +
						 'Regards <br> UClick Rerate Job Alert'

End

if ( @RerateStatusID = -2 ) -- Running
Begin

		set @Subject = 'Rerate Job : Rerate ID ' + convert(varchar(10) , @RerateID) + ' : ' + 'Running'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Rerate Job by name : ' + '<b> (' + @RerateName + ') </b>' + 
						 ' is currently selected and running' +
						 '<br><br>' +
						 'You will be alerted regarding the next status of the rerate job' +
						 '<br><br>' +
						 'Regards <br> UClick Rerate Job Alert'

End

if ( @RerateStatusID = -3 ) -- Completed
Begin

		set @Subject = 'Rerate Job : Rerate ID ' + convert(varchar(10) , @RerateID) + ' : ' + 'Completed'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Rerate Job by name : ' + '<b> (' + @RerateName + ') </b>' + 
						 ' has successfully completed on date : ' + '<b> (' + convert(varchar(20) , @RerateCompletionDate , 120) + ') </b>' +
						 '<br><br>' +
						 'Regards <br> UClick Rerate Job Alert'
End


if ( @RerateStatusID = -4 ) -- Failed
Begin

		set @Subject = 'Rerate Job : Rerate ID ' + convert(varchar(10) , @RerateID) + ' : ' + 'Failed'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Rerate Job by name : ' + '<b> (' + @RerateName + ') </b>' + 
						 ' has failed during execution due to some exception' + 
						 '<br><br>' + 
						 ' Please login to the GUI to see more details regarding failure' +
						 '<br><br>' +
						 'Regards <br> UClick Rerate Job Alert'
End


if ( @RerateStatusID = -5 ) -- Cancelled
Begin

		set @Subject = 'Rerate Job : Rerate ID ' + convert(varchar(10) , @RerateID) + ' : ' + 'Cancelled'

		set @EmailBody = 'Dear User,' + '<br><br>' +
						 'Rerate Job by name : ' + '<b> (' + @RerateName + ') </b>' + 
						 ' has has been cancelled.' + 
						 '<br><br>' + 
						 'Regards <br> UClick Rerate Job Alert'
End


-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

--select @To , @Subject , @EmailBody

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @Subject , @EmailBody , @LogFileName


GO
