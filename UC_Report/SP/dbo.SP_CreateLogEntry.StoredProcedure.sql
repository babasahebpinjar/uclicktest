USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_CreateLogEntry]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE Procedure [dbo].[SP_CreateLogEntry]
(
     @LogDate varchar(100),
     @CallID varchar(100),
     @CallingNumber varchar(100),
     @CalledNumber varchar(100),
	@ServerName varchar(100),
     @LogFilename varchar(100),
	 @MasterLogName varchar(100),
	@ResultFlag int Output,
     @ErrorDescription varchar(200) Output
)

AS
set @ErrorDescription = NULL
set @ResultFlag = 0

declare @RecordsCount int
set @RecordsCount = 0


--------------------------------
-- Update the user information
--------------------------------

SET NOCOUNT ON

Begin Try
	
	IF NOT EXISTS( select * from tb_LogEntries where LogFilename = @LogFilename and ServerName = @ServerName)
	BEGIN
		insert into tb_LogEntries( LogDate , CallID , CallingNumber , CalledNumber ,ServerName, LogFilename,RecordsCount,MasterLogName)
		values (@LogDate,@CallID,@CallingNumber,@CalledNumber,@ServerName,@LogFilename,1,@MasterLogName)
	END
	ELSE
		BEGIN
			select @RecordsCount = RecordsCount 
			from tb_LogEntries
			where LogFilename = @LogFilename and ServerName = @ServerName

			update tb_LogEntries
			set RecordsCount = @RecordsCount + 1
			where LogFilename = @LogFilename and ServerName = @ServerName
		END
	
End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
