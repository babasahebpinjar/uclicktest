USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_LogMessage]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_LogMessage]
(
    @ErrorMsgStr varchar(2000),
    @LogFileName varchar(500)
)
--With Encryption 
As 

---------------------
-- Declare Variables
---------------------

Declare @Command varchar(3000)

set @LogFileName = '"'+@LogFileName+'"'


if ( @ErrorMsgStr is not NULL )
Begin

               
		set @Command =
		    case
		        when charindex('&' , @ErrorMsgStr) <> 0 then 'echo '+ replace(@ErrorMsgStr , '&' , '^&') + ' >> ' + @LogFileName
		        when charindex('>' , @ErrorMsgStr) <> 0 then 'echo '+ replace(@ErrorMsgStr , '>' , '^>') + ' >> ' + @LogFileName
			    else 'echo '+ @ErrorMsgStr + ' >> ' + @LogFileName
		    end
		exec Master.dbo.xp_cmdShell @Command

End

Else
Begin

		set @ErrorMsgStr = '.'
		set @Command = 'echo'+ @ErrorMsgStr + ' >> ' + @LogFileName
		exec Master.dbo.xp_cmdShell @Command

End


Return 0 
GO
