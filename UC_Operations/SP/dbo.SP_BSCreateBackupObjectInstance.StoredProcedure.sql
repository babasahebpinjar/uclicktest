USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCreateBackupObjectInstance]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCreateBackupObjectInstance]
AS

-----------------------------------------------------
-- Prepare the date stamp which needs to be suffixed
-- to the Object Instance name
-----------------------------------------------------

Declare @DateStamp varchar(10)

set @DateStamp = convert(varchar(10) , getdate() , 120 )

---------------------------------------------------
-- Open cursor to loop through all the Database
-- objects listed for backup
---------------------------------------------------

Declare @VarObjectID int,
        @VarObjectName varchar(500)

DECLARE db_Execute_DB_Backup CURSOR FOR  
select ObjectID , ObjectName
from tb_Object
where objecttypeID = 103 -- Database Backup


OPEN db_Execute_DB_Backup   
FETCH NEXT FROM db_Execute_DB_Backup
INTO @VarObjectID , @VarObjectName  

WHILE @@FETCH_STATUS = 0   
BEGIN

        -----------------------------------------------------
		-- Check if the object instance already exists and
		-- create if it is not there
		-----------------------------------------------------

		if not exists 
		(
			select 1 from tb_ObjectInstance
			where objectID = @VarObjectID
			and ObjectInstance = @VarObjectName + ' ' + @DateStamp
		)
		Begin

				Insert into tb_ObjectInstance
				(
					ObjectID, 
					ObjectInstance,
					StatusID,
					ProcessStartTime,
					ModifiedDate,
					ModifiedByID
				)
				Values
				(
					@VarObjectID,
					@VarObjectName + ' ' + @DateStamp,
					10310, -- Database Backup Registered
					Getdate(),
					Getdate(),
					-1
				)

		End

		FETCH NEXT FROM db_Execute_DB_Backup
		INTO @VarObjectID , @VarObjectName 

END   

CLOSE db_Execute_DB_Backup  
DEALLOCATE db_Execute_DB_Backup 

Return 0
GO
