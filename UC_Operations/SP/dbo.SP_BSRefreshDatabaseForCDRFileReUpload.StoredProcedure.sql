USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRefreshDatabaseForCDRFileReUpload]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRefreshDatabaseForCDRFileReUpload]
(
	@ObjectInstanceID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


set @ResultFlag = 0
set @ErrorDescription = NULL

Declare @BeginDate datetime,
        @EndDate datetime,
		@ObjectID int

---------------------------------------------------
-- Extract the Begin and End Date from the Object
-- Instance entry to establish the dates for which
-- schema needs to be refreshed
---------------------------------------------------

Select @BeginDate = tbl1.StartDate,
       @EndDate = tbl1.EndDate,
	   @ObjectID = tbl1.ObjectID
from tb_ObjectInstance tbl1
inner join tb_Object tbl2 on tbl1.ObjectID = tbl2.ObjectID
inner join tb_ObjectType tbl3 on tbl2.ObjectTypeID = tbl3.ObjectTypeID
where tbl1.ObjectInstanceID = @ObjectInstanceID
and tbl3.ObjecttypeID = 100 -- CDR File Object Type

-------------------------------------------
-- Check if OBJECT ID is NULL or valid
-------------------------------------------

if ( @ObjectID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!!! The Object Instance does not belong to CDR File Object Type'
	set @ResultFlag = 1
	Return 1

End

-------------------------------------------------------------
-- Find out the CDR Server and Database from which the data
-- needs to be deleted
-------------------------------------------------------------

Declare @CDRServer varchar(50),
        @DatabaseAliasName varchar(50),
		@DatabaseName varchar(50),
		@ServerID int,
		@DatabaseID int

Select @CDRServer = Substring(ObjectName , 1 ,charindex('_' , ObjectName) - 1 ),
       @DatabaseAliasName = Substring(ObjectName ,charindex('_' , ObjectName) + 1 ,  len(ObjectName))
from tb_Object 
where ObjectID = @ObjectID

select @ServerID = ServerID
from tb_Server
where ServerAlias = @CDRServer

if (@ServerID is NULL) 
Begin

	set @ErrorDescription = 'ERROR !!! There does not exist any Server in the system for server alias : ' + @CDRServer
	set @ResultFlag = 1
	Return 1
End 

Select @DatabaseID = DatabaseID,
       @DatabaseName = DatabaseName 
from tb_Database
where DatabaseAlias = @DatabaseAliasName

if (@DatabaseID is NULL) 
Begin

	set @ErrorDescription = 'ERROR !!! There does not exist any Database in the system for name : ' + @DatabaseAliasName
	set @ResultFlag = 1
	Return 1
End 

-----------------------------------------------------------------
-- Check to ensure that there exists mapping between CDR Server
-- and Database
-----------------------------------------------------------------

if not exists  ( select 1 from tb_ServerDatabase where ServerID = @ServerID and DatabaseID = @DatabaseID )
Begin

	set @ErrorDescription = 'ERROR !!! There is no mapping in the system for Server : ' + @CDRServer + ' and Database : ' + @DatabaseAliasName
	set @ResultFlag = 1
	Return 1
End

-------------------------------------------------------------
-- Loop through all the dates and delete data from the 
-- following schema :
-- 1. tb_EER
-- 2. tb_FTRSummary
-- 3. tb_FTR
--------------------------------------------------------------

Declare @VarCallDate datetime,
        @EERTable varchar(20),
		@FTRTable varchar(20),
		@FTRSummaryTable varchar(20),
		@SQLStr varchar(2000)

set @VarCallDate = @BeginDate

Begin Try

	While ( @VarCallDate <= @EndDate)
	Begin

		   set @EERTable = 'tb_EER_' + 
						   Right(convert(varchar(4) , year(@VarCallDate)),2) + 
						   Right('0' +convert(varchar(2) , Month(@VarCallDate)),2) +
						   Right('0' +convert(varchar(2) , Day(@VarCallDate)),2)

		   set @FTRTable = 'tb_FTR_' + 
						   Right(convert(varchar(4) , year(@VarCallDate)),2) + 
						   Right('0' +convert(varchar(2) , Month(@VarCallDate)),2) +
						   Right('0' +convert(varchar(2) , Day(@VarCallDate)),2)

		   set @FTRSummaryTable = 'tb_FTRSummary_' + 
						   Right(convert(varchar(4) , year(@VarCallDate)),2) + 
						   Right('0' +convert(varchar(2) , Month(@VarCallDate)),2) +
						   Right('0' +convert(varchar(2) , Day(@VarCallDate)),2)

           set @SQLStr = 'Delete from ' + @CDRServer + '.' + @DatabaseName + '.dbo.' + @EERTable + ' where ObjectInstanceID = ' + convert(varchar(100) , @ObjectInstanceID)

		   --print @SQLStr
		   Exec(@SQLStr)

           set @SQLStr = 'Delete from ' + @CDRServer + '.' + @DatabaseName + '.dbo.' + @FTRTable + ' where ObjectInstanceID = ' + convert(varchar(100) , @ObjectInstanceID)

		   --print @SQLStr
		   Exec(@SQLStr)

           set @SQLStr = 'Delete from ' + @CDRServer + '.' + @DatabaseName + '.dbo.' + @FTRSummaryTable + ' where ObjectInstanceID = ' + convert(varchar(100) , @ObjectInstanceID)

		   --print @SQLStr
		   Exec(@SQLStr)

		   set @VarCallDate = DateAdd(dd , 1 , @VarCallDate)

	End	

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While deleting data from CDR schema for date : ' + convert(varchar(10) , @VarCallDate , 120) + '. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch
GO
