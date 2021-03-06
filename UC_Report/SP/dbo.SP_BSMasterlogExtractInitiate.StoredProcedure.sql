USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogExtractInitiate]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMasterlogExtractInitiate]
as

Declare @ErrorDescription varchar(2000),
        @ResultFlag int,
		@MasterlogExtractID int


if not exists ( select 1 from tb_MasterlogExtract where MasterlogExtractStatusID = -1 ) 
	GOTO ENDPROCESS

-----------------------------------------------------------
-- Get the Masterlog Extract ID for the requested Extract with the
-- least Request date
------------------------------------------------------------

Select @MasterlogExtractID = MasterlogExtractID
from tb_MasterlogExtract
where MasterlogExtractStatusID = -1
and MasterlogExtractRequestDate = 
(
	select Min(MasterlogExtractRequestDate)
	from tb_MasterlogExtract
	where MasterlogExtractStatusID = -1
)

-----------------------------------------------------------------------
-- Call the procedure to initiate the Masterlog Rextract for the Selected ID
-----------------------------------------------------------------------

Begin Try

		Exec SP_BSMasterlogExtracMain @MasterlogExtractID , @ErrorDescription Output , @ResultFlag Output

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While running Masterlog Extract for ID: (' + convert(varchar(10) , @MasterlogExtractID) + '). ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorDescription)
		Return 1

End Catch

ENDPROCESS:

return 0
GO
