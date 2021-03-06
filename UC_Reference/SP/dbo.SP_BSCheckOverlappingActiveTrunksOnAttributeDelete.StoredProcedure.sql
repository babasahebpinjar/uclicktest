USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCheckOverlappingActiveTrunksOnAttributeDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSCheckOverlappingActiveTrunksOnAttributeDelete]
( 
	@CDRMatch varchar(30) ,
	@SwitchID  int,
    @TrunkID int,
	@TrunkDetailID int,
	@ResultFlag int = 0 Output
)
As       

Create Table #TempData
(
	TrunkID int,
	CDRMatch varchar(60),
	SwitchID int,
	ActiveStatusID int,
	EffectiveDate datetime,
) 
       
Create table #TempTrunkDetails
(
    rID int identity(1,1),
	TrunkID int,
	CDRMatch varchar(60),
	SwitchID int,
	ActiveStatusID int,
	EffectiveDate datetime,
) 

Create table #TempTrunk
(
    rID int identity(1,1),
	TrunkID int,
	CDRMatch varchar(60),
	SwitchID int,
	ActiveStatusID int,
	BeginDate datetime,
	EndDate datetime
) 

Create table #TempCDRMatch
(
    rID int identity(1,1),
	CDRMatch varchar(60),
	SwitchID int,
	BeginDate datetime,
	EndDate datetime,
	Flag int
) 

-----------------------------------------------------------------
-- Get all the records for various physical trunks, which have the
-- same CDR Match and switch, excluding the trunk detail record
-- that is being deleted
------------------------------------------------------------------


insert into #TempData
( TrunkID , CDRMatch , SwitchID , ActiveStatusID , EffectiveDate )
select tbl1.TrunkID , tbl1.CDRMatch , tbl1.SwitchID , tbl2.ActiveStatusID , tbl2.EffectiveDate
from tb_trunk tbl1
inner join tb_trunkdetail tbl2 on tbl1.trunkid = tbl2.TrunkID
where tbl1.SwitchID = @SwitchID
and tbl1.CDRMatch = @CDRMatch
and tbl1.TrunkTypeID not in (6,7,8,9)
and tbl1.Flag & 1 <> 1
and tbl2.Flag & 1 <> 1
and tbl2.TrunKDetailID <> @TrunkDetailID -- Exclude the trunk detail record which is being deleted from the selection


---------------------------------------------------------------
-- Add the records to the temp trunk details table, ordered by
-- trunkID , effectivedate
--------------------------------------------------------------	

insert into #TempTrunkDetails
( TrunkID , CDRMatch , SwitchID , ActiveStatusID , EffectiveDate )
select TrunkID , CDRMatch , SwitchID , ActiveStatusID , EffectiveDate
from #TempData
order by TrunkID , EffectiveDate

--select 'STEP 1.. from TrunkDetails' , *
--from #TempTrunkDetails
  
-----------------------------------------------------------------
-- Loop through the records and find all the instances where the
-- CDR match was active for a technical trunk
----------------------------------------------------------------

Declare @InsertFlag int = 0,
		@Counter int  = ( select Min(rID) from #TempTrunkDetails where ActiveStatusID = 1 ),
		@MaxCounter int = ( select Max(rID) from #TempTrunkDetails where ActiveStatusID = 1 )
		

Declare @Prev_CDRMatch varchar(30),
		@Prev_SwitchID  int,
		@Prev_ActiveStatusID int,
		@Prev_TrunkID int 		
		
While ( @Counter < = @MaxCounter)	
Begin

		if ( @InsertFlag = 0 )
		Begin
		
				insert into #TempTrunk
				(TrunkID , CDRMatch , ActiveStatusID , SwitchID , BeginDate)
				select TrunkID , CDRMatch , ActiveStatusID , SwitchID , EffectiveDate
				from #TempTrunkDetails
				where rID = @Counter
				
				set @InsertFlag = 1
		
		
		End
		
		Else
		Begin
		
				if exists (
								Select 1
								from #TempTrunkDetails
								where rID = @Counter
								and
								(
									TrunkID <> @Prev_TrunkID
									or
									ActiveStatusID <> @Prev_ActiveStatusID
								)
						  )
				Begin
				
						insert into #TempTrunk
						(TrunkID , CDRMatch , ActiveStatusID , SwitchID , BeginDate)
						select TrunkID , CDRMatch , ActiveStatusID , SwitchID , EffectiveDate
						from #TempTrunkDetails
						where rID = @Counter	
						and ActiveStatusID = 1 -- Pick up the active record						
				
				End		
		
		
		End
		
	    select  @Prev_CDRMatch = CDRMatch,
				@Prev_SwitchID  = SwitchID,
				@Prev_ActiveStatusID = ActiveStatusID ,
				@Prev_TrunkID = TrunkID 
		from #TempTrunkDetails
		where rID = @Counter
		
		set @Counter = @Counter + 1							


End	

--select 'STEP 2.. from Trunk' , *
--from #TempTrunk
  

-------------------------------------------------------------------
-- Populate the End Date for sll the active trunks extracted above
-- by comparing against the trunk details
-- The end date would be the date when the status of the trunk
-- was changed to inactive from Active state
-- This will establish the actual period for which the trunk was
-- active
------------------------------------------------------------------

update tbl1
set tbl1.EndDate = tbl2.EffectiveDate -1
from #TempTrunk tbl1
inner join #TempTrunkDetails tbl2 on tbl1.TrunkID = tbl2.TrunkID
and tbl1.SwitchID = tbl2.SwitchID
and tbl1.CDRMatch = tbl2.CDRMatch
and tbl2.ActiveStatusID = 2
and tbl2.EffectiveDate = 
(
	select MIN(tbl11.EffectiveDate)
	from #TempTrunkDetails tbl11
	where tbl1.TrunkID = tbl11.TrunkID 
	and tbl1.SwitchID = tbl11.SwitchID
	and tbl1.CDRMatch = tbl11.CDRMatch
	and tbl11.ActiveStatusID = 2
	and tbl1.BeginDate < tbl11.EffectiveDate
)

--select 'STEP 3.. from Trunk after update End Date' , *
--from #TempTrunk

delete t2
from	#TempTrunk t2
	left join #TempTrunk t1
	on	t1.rID + 1 = t2.rID
	and	t2.BeginDate <= t1.EndDate
	and	t1.TrunkID = t2.TrunkID
	and	t1.SwitchID = t2.SwitchID
	and	t1.CDRMatch = t2.CDRMatch	
where	t1.rID is not null

--select 'STEP 4.. from Trunk after deleting redundant records' , *
--from #TempTrunk


-------------------------------------------------
-- Insert records into temp table which holds
-- only CDR Match , Switch and Begin/End dates
-------------------------------------------------

insert into #TempCDRMatch
(CDRMatch , SwitchID , BeginDate , EndDate, Flag)
select CDRMatch , SwitchID , BeginDate , EndDate , 0
from #TempTrunk
order by CDRMatch , SwitchID , BeginDate

------------------------------------------------------------------------
-- Update flag as error for all records which have the following anomaly
-- 1. End Date is greater than the Begin Date of subsequent record
-- 2. End Date is Null for the record, but there is a subsequent record

-- These are scenarios for overlapping records.
------------------------------------------------------------------------


update	c1
set
	Flag = 1
from	#TempCDRMatch c1
	left	join #TempCDRMatch c2
	on	c1.rID + 1 = c2.rID
	and	c1.SwitchID = c2.SwitchID
	and	c1.CDRMatch = c2.CDRMatch
where	(c1.EndDate is null and c2.rID is not null)
or	c1.EndDate >= c2.BeginDate

--select 'STEP 5.. from CDR Match after update of Error Flag' , *
--from #TempCDRMatch

if  ( ( select COUNT(*) from #TempCDRMatch where Flag = 1 ) > 0 )
Begin

		set @ResultFlag = 1

End
 
--select @ResultFlag    
    
-----------------------------------------------------------
-- Drop all the temporary tables created during processing
-----------------------------------------------------------  
    
drop table #TempData
drop table #TempTrunkDetails
drop table #TempTrunk
drop table #TempCDRMatch


--Return 0
GO
