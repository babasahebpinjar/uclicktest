USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCorrelateCollect]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSMedCorrelateCollect]
(
   @SourcePath varchar(1000),
   @SourceFileIdentifier varchar(200),
   @AbsoluteLogFilePath varchar(1000),
   @ErrorDescription varchar(2000) Output,
   @ResultFlag int Output

)
As

Declare @Command varchar(500)


set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------------------------
-- Prepare the command for polling the directory in which the CDR files are expected. --
----------------------------------------------------------------------------------------

if ( right(@SourcePath,1) <> '\' )
     
    set @SourcePath = @SourcePath + '\'

set @Command = 'dir '+ @SourcePath+@SourceFileIdentifier + ' /b'

insert into #TempMedCorrelateCollect
Exec master..xp_cmdshell @Command

-------------------------------------------------------------------------
-- In case the Source Path specified does not exist , then throw error --
-------------------------------------------------------------------------

if exists ( select 1 from #TempMedCorrelateCollect where CDRFileName = 'The system cannot find the path specified.' )
Begin

       set @ErrorDescription = 'SP_BSMedCorrelateCollect : '+ convert(varchar(30) ,getdate() , 120) + ' : ERROR !!!! Specified SourcePath : ( '+ @SourcePath + ' ) for File collection does not exist'
       Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath
       set @ResultFlag = 1
       Return 1
End

-------------------------------------------------------------------------------------
-- In case no Files exist, then empty the table so that PROCESSOR does not pick up --
-- wrong information. --
-------------------------------------------------------------------------------------

if exists ( select 1 from #TempMedCorrelateCollect where CDRFileName = 'File Not Found' )

    delete from #TempMedCorrelateCollect

--------------------------------------------------------------------
-- Delete the default appended row with NULL value from the table --
--------------------------------------------------------------------

delete from #TempMedCorrelateCollect where CDRFileName is NULL

return 0
GO
