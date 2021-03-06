USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSDatabaseBackupCreateMain]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[SP_BSDatabaseBackupCreateMain]
(
	@ObjectID int	
)
As

Declare @ErrorDescription varchar(2000),
	    @ResultFlag int

--------------------------------------------------------------
-- Get the oldest Object Instance for DB Backup object based
-- on the Process Register Date
---------------------------------------------------------------

Declare @ObjectInstanceID int

Select @ObjectInstanceID = ObjectInstanceID
from ReferenceServer.UC_Operations.dbo.tb_ObjectInstance
where ObjectID = @ObjectID
and statusid = 10310 -- DB Backup Registered 
and ProcessStartTime in
(
	Select min(ProcessStartTime)
	from ReferenceServer.UC_Operations.dbo.tb_ObjectInstance
	where ObjectID = @ObjectID
	and statusid = 10310
)

if ( @ObjectInstanceID is NULL )
	Return 0 --  Exit from here, as there is no object instance registered for backup

--------------------------------------------
-- Change the status of the DB Backup Object
-- Instance to Running
--------------------------------------------

update ReferenceServer.UC_Operations.dbo.tb_ObjectInstance
set statusid = 10311,
    modifiedDate = getdate()
where ObjectInstanceID = @ObjectInstanceID

--------------------------------------------
-- Call the procedure to initiate the DB
-- back up
--------------------------------------------

Begin Try

		Exec SP_BSDatabaseBackupCreate @ObjectInstanceID ,
		                               @ErrorDescription Output,
									   @ResultFlag Output

        if ( @ResultFlag = 1 ) 
		Begin

			 GOTO ENDPROCESS

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While Executing database back up. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:

----------------------------------------------------------
-- Update the status of the ObjectInstance, based on the
-- Result Flag
----------------------------------------------------------

update ReferenceServer.UC_Operations.dbo.tb_ObjectInstance
set Statusid = 
       Case
			When @ResultFlag = 1 then 10313 -- Database Backup Fail
			When @ResultFlag = 0 then 10312 -- Database Backup Completed
	   End ,
	ProcessEndTime = getdate(),
	Remarks =
       Case
			When @ResultFlag = 1 then @ErrorDescription 
			When @ResultFlag = 0 then NULL
	   End ,
	ModifiedDate = getdate()
Where ObjectInstanceID = @ObjectInstanceID

Return 0

GO
