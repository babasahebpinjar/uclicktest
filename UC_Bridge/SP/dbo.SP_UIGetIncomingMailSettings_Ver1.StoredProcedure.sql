USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetIncomingMailSettings_Ver1]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetIncomingMailSettings_Ver1]
(
	@UserID int
)
--With Encryption
As


-----------------------------------------------------
-- Get all essential details of the logged in USER
-----------------------------------------------------

Declare @LoggedUserStatusID int,
        @LoggedUserPrivilegeID int


select @LoggedUserStatusID = UserStatusID,
       @LoggedUserPrivilegeID = UserPrivilegeID
from tb_users
where UserID = @UserID


-------------------------------------------------------------
-- Make sure that the logged in user exists in system and is
-- not in an inactive state
-- This is to cover a corner scenario where logged in user
-- might have been deleted
-------------------------------------------------------------
 
if ( ( @LoggedUserStatusID is NULL ) or ( @LoggedUserStatusID = 2 ) )               
Begin

	select NULL as KeyName , NULL as Value
	return

End


---------------------------------------------------
--  Check if the session user has the essential
-- privilege to update the user information
---------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Email Settings' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	select NULL as KeyName , NULL as Value
	return

End


-------------------------------------------
-- In case everything is okay, return the 
-- dataset to be displayd on UI
-------------------------------------------

Declare @VarColumnName varchar(100),
        @SQLStr varchar(2000)

------------------------------------------------
-- Create temp table to store the result set
------------------------------------------------

create table #TempResultSet
(
   KeyName varchar(100),
   Value varchar(1000)
)

-------------------------------------------
-- Open a cursor to traverse through all the
-- columns of the table holding the incoming
-- email configuration
--------------------------------------------

Declare GetAllColsName Cursor For
select tbl1.name
from syscolumns tbl1
inner join sysobjects tbl2 on tbl1.id = tbl2.id
where tbl2.name = 'tblincomingmailsettings'
and tbl2.xtype = 'u'
and  tbl1.name not in ( 'ID' , 'ClientID' , 'MailLastUID' , 'Status' , 'PortNumber' , 'SSL')

OPEN GetAllColsName
FETCH NEXT FROM GetAllColsName
INTO @VarColumnName 

While @@FETCH_STATUS = 0
BEGIN

	set @SQLStr = 'Select ''' + @VarColumnName + ''' ,' + @VarColumnName + ' from  tblincomingmailsettings'
	
	Insert into #TempResultSet
        Exec (@SQLStr)

	FETCH NEXT FROM GetAllColsName
	INTO @VarColumnName   

END

CLOSE GetAllColsName
DEALLOCATE GetAllColsName


Select *
from #TempResultSet

Drop table #TempResultSet


Return
GO
