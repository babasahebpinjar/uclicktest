USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtractInitiate]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRExtractInitiate]
as

Declare @ErrorDescription varchar(2000),
        @ResultFlag int,
		@CDRExtractID int


if not exists ( select 1 from tb_CDRExtract where CDRExtractStatusID = -1 ) 
	GOTO ENDPROCESS

-----------------------------------------------------------
-- Get the CDR Extract ID for the requested Extract with the
-- least Request date
------------------------------------------------------------

Select @CDRExtractID = CDRExtractID
from tb_CDRExtract
where CDRExtractStatusID = -1
and CDRExtractRequestDate = 
(
	select Min(CDRExtractRequestDate)
	from tb_CDRExtract
	where CDRExtractStatusID = -1
)

-----------------------------------------------------------------------
-- Call the procedure to initiate the CDR Rextract for the Selected ID
-----------------------------------------------------------------------

Begin Try

		Exec SP_BSCDRExtracMain @CDRExtractID , @ErrorDescription Output , @ResultFlag Output

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While running CDR Extract for ID: (' + convert(varchar(10) , @CDRExtractID) + '). ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorDescription)
		Return 1

End Catch

ENDPROCESS:

return 0
GO
