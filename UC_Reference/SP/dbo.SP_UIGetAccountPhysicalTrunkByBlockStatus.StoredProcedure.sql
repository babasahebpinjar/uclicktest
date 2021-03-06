USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAccountPhysicalTrunkByBlockStatus]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIGetAccountPhysicalTrunkByBlockStatus]
(

	@AccountID int,
	@BlockStatus int , -- 0 : ALL , 1 : Blocked , 2 : Unblocked
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0

----------------------------------------------------------------------
-- Check that the BlockStatus is not NULL and has values as 0,1,2
----------------------------------------------------------------------
if ( 
	(@BlockStatus is NULL)
	or
	(@BlockStatus not in (0,1,2))
   )
Begin

		set @ErrorDEscription = 'ERROR !!!! Block status flag cannot be NULL and should have value as 0,1 or 2'
		set @ResultFlag = 1
		Return 1

End


----------------------------------------------------------------
-- Throw exception if Account ID is NULL or not in the system
----------------------------------------------------------------

if ( 
		@AccountID is NULL 
		or 
		not exists (select 1 from tb_Account where AccountID = @AccountID)
   )
Begin

		set @ErrorDEscription = 'ERROR !!!! Account ID is NULL or invalid and does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

------------------------------------------------------------
-- Get details of all the physical trunks from the system
------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempPhysicalTrunkWithBlockStatus') )
	Drop table #TempPhysicalTrunkWithBlockStatus;

With CTE_PhysicalTrunksForAccounts As
(
	select *
	from tb_Trunk
	where accountID = @AccountID
	and trunktypeID <> 9
),
CTE_PhysicalTrunkAttributes As
(
	select trnkdet.*
	from tb_TrunkDetail trnkdet
	inner join CTE_PhysicalTrunksForAccounts trnk on trnkdet.TrunkID = trnk.TrunkID
),
CTE_PhysicalTrunkLatestAttributes As
(
	select TrunkID , Max(EffectiveDate) as LatestEffectiveDate
	from CTE_PhysicalTrunkAttributes
	group by TrunkID
)
Select trnk.TrunkID,
       trnk.Trunk , 
	   trnkdet.EffectiveDate,
       sts.ActiveStatus as TrunkStatus ,
	   dir.Direction, 
       swt.Switch,
	   ctrnk.Trunk as CommercialTrunk,
	   trnkdet.ActivatedPorts , 
	   trnkdet.AvailablePorts,
	   Case
			When trnk.Flag & 64 = 64 Then 1
			Else 0
	   End IncomingTrafficBlockStatus
into #TempPhysicalTrunkWithBlockStatus
from CTE_PhysicalTrunksForAccounts trnk
inner join CTE_PhysicalTrunkAttributes trnkdet on trnkdet.TrunkID = trnk.TrunkID
inner join CTE_PhysicalTrunkLatestAttributes trnkdetcurr on trnkdet.TrunkID = trnkdetcurr.TrunkID
														and trnkdet.EffectiveDate = trnkdetcurr.LatestEffectiveDate
inner join tb_ActiveStatus sts on trnkdet.ActiveStatusID = sts.ActiveStatusID
inner join tb_Direction dir on trnkdet.DirectionID = dir.DirectionID
inner join tb_Switch swt on trnk.SwitchID = swt.SwitchID
left join tb_Trunk ctrnk on trnkdet.CommercialTrunkID = ctrnk.TrunkID


------------------------------------------------------------------
-- Extract specific trunk records based on the block ststus flag
------------------------------------------------------------------

if (@BlockStatus = 0 ) -- All
	Select * from #TempPhysicalTrunkWithBlockStatus order by Trunk

if (@BlockStatus = 1) -- Incoming Blocked
	Select * from #TempPhysicalTrunkWithBlockStatus where IncomingTrafficBlockStatus = 1 order by Trunk

if (@BlockStatus = 2) -- Incoming not Blocked
	Select * from #TempPhysicalTrunkWithBlockStatus where IncomingTrafficBlockStatus = 0 order by Trunk

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempPhysicalTrunkWithBlockStatus') )
	Drop table #TempPhysicalTrunkWithBlockStatus

Return 0



GO
