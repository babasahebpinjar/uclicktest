USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRerateInitiate]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRerateInitiate]
as

Declare @ErrorDescription varchar(2000),
        @ResultFlag int,
		@RerateID int


if not exists ( select 1 from tb_Rerate where RerateStatusID = -1 ) 
	GOTO ENDPROCESS

-------------------------------------------------------------------
-- Need to ensure that at any point of time, only one Rerate job
-- is running in the system. If there is a job currently running
-- then the process should exit
-------------------------------------------------------------------

if exists ( select 1 from tb_Rerate where RerateStatusID in (-2 , -4) ) -- Running or Failed
Begin

	Return 0

End

-----------------------------------------------------------
-- Get the Rerate ID for the requested Extract with the
-- least Request date
------------------------------------------------------------

Select @RerateID = RerateID
from tb_Rerate
where RerateStatusID = -1
and RerateRequestDate = 
(
	select Min(RerateRequestDate)
	from tb_Rerate
	where RerateStatusID = -1
)

-----------------------------------------------------------------------
-- Call the procedure to initiate the Rerate job for the Selected ID
-----------------------------------------------------------------------

Begin Try

		Exec SP_BSRerateRegisterMain @RerateID , @ErrorDescription Output , @ResultFlag Output

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While registering Rerate job for running for ID: (' + convert(varchar(10) , @RerateID) + '). ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 , @ErrorDescription)

		Return 1

End Catch

ENDPROCESS:

return 0
GO
