USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCustomManageIncomingTrafficByTrunk]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSCustomManageIncomingTrafficByTrunk]
(
	@TrunkIDList nvarchar(max),
	@TaskFlag int, -- 0 means Unblock , 1 means Block
	@ReasonDesc varchar(200), -- Reason for action being performed
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrunkIDTable') )
				Drop table #TempTrunkIDTable

Create Table #TempTrunkIDTable (TrunkID varchar(100) )


insert into #TempTrunkIDTable
select * from FN_ParseValueList ( @TrunkIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from #TempTrunkIDTable where ISNUMERIC(TrunkID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Truk IDs passed contain a non numeric value'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

-------------------------------------------------------------------
-- Check to ensure that all the Trunk IDs passed are valid values
-------------------------------------------------------------------
		
if exists ( 
				select 1 
				from #TempTrunkIDTable 
				where TrunkID not in
				(
					Select TrunkID
					from Tb_Trunk
					where trunktypeid <> 9
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Trunk IDs passed contain value(s) which are not valid or do not exist'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

------------------------------------------------
-- Task Flag can only take values of 0 or 1
------------------------------------------------

if (@TaskFlag not in (0,1))
Begin

	set @ErrorDescription = 'ERROR!!! Task Flag can either have value 0 (unblock) or 1 (block)'
	set @ResultFlag = 1
	Return 1

End


----------------------------------------------------------
-- Ensure that appropriate reason is provided for action
----------------------------------------------------------

if ( len(rtrim(ltrim(isnull(@ReasonDesc , '')))) = 0 )
Begin

	set @ErrorDescription = 'ERROR!!! Please provide appropriate reason for the action'
	set @ResultFlag = 1
	Return 1

End


---------------------------------------------------------------------------
-- Get all the trunks (links) associated , irrespective of their direction 
-- and block status
-- This is to ensure that if ststus of trunk in uCLICK is blocked, but in
-- SBC its unblocked, then it will still allow traffic to flow for the account
---------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempElementData') )
		Drop table #TempElementData

Select trnkmap.TrunkID , CustomTrunkExternalMappingID as LinkID,
       convert(int , trnkmap.VirtualNetwork) as VirtualNetworkID,
	   convert(int , trnkmap.TrunkGroup) as TrunkGroupID,
	   Case
			When @TaskFlag = 0 Then trnkmap.RouteProfileID
			Else 0
	   End as CRFRouteProfileID
into #TempElementData
from tb_Trunk trnk
inner join #TempTrunkIDTable temptab on trnk.TrunkID = temptab.TrunkID
inner join tb_CustomTrunkExternalMapping trnkmap on trnk.TrunkID = trnkmap.TrunkID
where trnkmap.Linkstatus != 2 -- Dont select decommissioned links

--Select * from  #TempElementData

---------------------------------------------------------------------
-- Create entry in the External Transaction table for this task
---------------------------------------------------------------------

-- Transaction Entry should created as InProgress

Declare @ActionRegisterDate datetime = getdate(),
        @ExternalNetworkTransactionID int

insert into tb_ExternalNetworkTransaction
( TransactionReason, ActionRegisterDate , ActionCompletionDate , ActionStatusID , ModifiedDate , ModifiedByID)
values
(@ReasonDesc, @ActionRegisterDate , NULL , 1 , getdate() , @UserID) 

Select @ExternalNetworkTransactionID = ExternalNetworkTransactionID
from tb_ExternalNetworkTransaction
where ActionStatusID = 1 -- InProgress
and ActionRegisterDate = @ActionRegisterDate
and TransactionReason = @ReasonDesc

-----------------------------------------------------------------------
-- insert records in the transaction detail table for this transaction
-----------------------------------------------------------------------

-- Trunk

insert into tb_ExternalNetworkTransactionDetail
select distinct @ExternalNetworkTransactionID,
       -2, --Trunk
	   TrunkID,
	   @TaskFlag, -- 0 for unblock and 1 for Block
	   getdate(),
	   @UserID
from #TempElementData 

-- Links

insert into tb_ExternalNetworkTransactionDetail
select distinct @ExternalNetworkTransactionID,
       -3, --Trunk
	   LinkID,
	   @TaskFlag, -- 0 for unblock and 1 for Block
	   getdate(),
	   @UserID
from #TempElementData 

------------------------------------------------------------------------
-- Now Call the Procedure for creating the XML for the essential action
------------------------------------------------------------------------
Declare @XmlFilePath varchar(2000),
        @FileExists int,
		@cmd varchar(2000)

Begin Try

	set @ErrorDescription = NULL
	set @ResultFlag = 0

	Exec SP_BSCustomCreateXML @ErrorDescription Output ,  @ResultFlag Output , @XmlFilePath Output

	if (@ResultFlag  = 1)
	Begin

			set @ErrorDescription = 'Error!!! Creating XML for action. ' + @ErrorDescription
			GOTO ENDPROCESS

	End

End Try

Begin Catch

			set @ErrorDescription = 'Error!!! Creating XML for action. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO ENDPROCESS

End Catch

---------------------------------------------------------------
-- Check if the XMLFile returned actually exists in the system
---------------------------------------------------------------

set @FileExists = 0

Select 'Debug' , @XmlFilePath as XmlFilePath

Exec master..xp_fileexist @XmlFilePath , @FileExists output

if ( @FileExists <> 1 )
Begin

			set @ErrorDescription = 'Error!!! Creating XML for action. File does not exist in the system'
			set @ResultFlag = 1
			GOTO ENDPROCESS

End

----------------------------------------------------------------------------
-- Incase the file exists at the configured location, just extract the name
-- of the XML file for execution
----------------------------------------------------------------------------

Declare @XMLFileNameWithoutPath varchar(2000)

set @XMLFileNameWithoutPath = reverse(substring(reverse(@XmlFilePath) ,1 ,Charindex( '\' , reverse(@XmlFilePath)) - 1))

--select 'Debug' , @XMLFileNameWithoutPath as XMLFileNameWithoutPath

--------------------------------------------------------------
-- Call the procedure to execute the commands in the XML File
--------------------------------------------------------------
Begin Try

	set @ErrorDescription = NULL
	set @ResultFlag = 0

	Exec SP_BSCustomExecuteXML @XMLFileNameWithoutPath ,@ErrorDescription Output , @ResultFlag Output 

	if (@ResultFlag  = 1)
	Begin

			set @ErrorDescription = 'Error!!! Exectuing the XML commands for action. ' + @ErrorDescription
			GOTO ENDPROCESS

	End

End Try

Begin Catch

			set @ErrorDescription = 'Error!!! Exectuing the XML commands for action. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO ENDPROCESS

End Catch

--------------------------------------------------------------------
-- At this point the execution of the desired action is successful
-- and we need to update the transaction table
--------------------------------------------------------------------

update tb_ExternalNetworkTransaction
set ActionCompletionDate = getdate(),
	ActionStatusID = 2, -- Success
	ModifiedDate = getdate(),
	ModifiedByID = @UserID
where ExternalNetworkTransactionID = @ExternalNetworkTransactionID

-------------------------------------------------------
-- Delete the XML file after completion of all actions
--------------------------------------------------------

set @FileExists = 0

--Select 'Debug' , @XmlFilePath as XmlFilePath

Exec master..xp_fileexist @XmlFilePath , @FileExists output

if ( @FileExists = 1 )
Begin

	set @cmd = 'Del ' + @XmlFilePath
	Exec master..xp_cmdshell @cmd
		

End

---------------------------------------------------------------------
-- Lastly set the flag for all the physical trunks belonging to the
-- account to blocked(64) or unblocked based on the Task Flag

-- Set the status of the Links based on the Task Flag
---------------------------------------------------------------------

if (@TaskFlag = 1)
Begin

	update tbl1
	set flag = flag|64
	from tb_Trunk tbl1
	inner join 
	(select distinct TrunkID from #TempElementData) tbl2 on tbl1.TrunkID = tbl2.TrunkID
	where tbl1.Flag & 64 <> 64 -- Change status for only those trunks where the status is not blocked

	update tbl1
	set Linkstatus = 1 -- Block
	from tb_CustomTrunkExternalMapping tbl1
	inner join
	(select distinct LinkID from #TempElementData) tbl2 on tbl1.CustomTrunkExternalMappingID = tbl2.LinkID


End

Else
Begin

	update tbl1
	set flag = flag - 64
	from tb_Trunk tbl1
	inner join 
	(select distinct TrunkID from #TempElementData) tbl2 on tbl1.TrunkID = tbl2.TrunkID
	where tbl1.Flag & 64 = 64 -- Change status for only those trunks where the status is blocked

	update tbl1
	set Linkstatus = 0 -- unblock
	from tb_CustomTrunkExternalMapping tbl1
	inner join
	(select distinct LinkID from #TempElementData) tbl2 on tbl1.CustomTrunkExternalMappingID = tbl2.LinkID

End



ENDPROCESS:

if (@ResultFlag = 1) -- Error Encountered, hence set the status of Transaction to Failed
Begin

	update tb_ExternalNetworkTransaction
	set ActionCompletionDate = getdate(),
		ActionStatusID = 3, -- Failed
		Remarks = substring(@ErrorDescription,1,2000),
		ModifiedDate = getdate(),
		ModifiedByID = @UserID
	where ExternalNetworkTransactionID = @ExternalNetworkTransactionID
		

End


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempElementData') )
		Drop table #TempElementData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrunkIDTable') )
				Drop table #TempTrunkIDTable


Return 0
GO
