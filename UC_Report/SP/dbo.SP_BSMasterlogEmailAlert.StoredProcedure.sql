USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogEmailAlert]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMasterlogEmailAlert]
(
	@EmailSubject varchar(1000),
	@EmailBody varchar(max),
	@ErrorDescription varchar(2000) output,
    @ResultFlag int output

	--@ResultFlag = @ResultFlag OUTPUT, @ErrorDescription = @ErrorDescription OUTPUT;
)
As

Declare @To varchar(1000) ,
		@Subject varchar(500) ,
		@LogFileName varchar(1000) = NULL

set @To = 'babasaheb.pinjar@ccplglobal.com;avinash.bendigeri@ccplglobal.com'

------------------------------------------------------------
-- Prepare the Subject and message based on the status of
-- the Masterlog Extract
------------------------------------------------------------


set @Subject = 'Masterlog Collection Error'


-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @To , @EmailSubject , @EmailBody , @LogFileName
GO
