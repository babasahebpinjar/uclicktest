USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAssociatedTechnicalTrunks]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetAssociatedTechnicalTrunks]
(
   @CommercialTrunkID int,
   @DisplayFlag int = 1,
   @AvailablePorts int Output,
   @ActivatedPorts int Output
)
As

set @AvailablePorts = 0
set @ActivatedPorts = 0

Declare @TechnicalTrunkID int
		

Create table #TempTechnicalTrunkDetails
(
    rID int identity(1,1),
	TrunkId int ,
	Trunk varchar(60),
	SwitchId int,
	Switch varchar(60),
	TrunkDetailID int,
	BeginDate Date,
	EndDate Date,
	ActiveStatusID int,
	ActiveStatus varchar(60),
	ActivatedPorts int,
	AvailablePorts int,
	AccountID int,
	Account varchar(60),
	CommercialTrunkID int,
	CommercialTrunk varchar(60),
	DirectionId int,
	Direction varchar(60),
	TargetUsage int,
	ProcessCode char(1),
	ModifiedDate datetime,
	ModifiedbyUser Varchar(60)
)


Create table #TempTechnicalTrunkActiveDetails
(
	TrunkId int ,
	TrunkDetailID int,
	Trunk varchar(60),
	BeginDate Date,
	EndDate Date,
	SwitchID int,
	Switch varchar(60),
	ActivatedPorts int,
	AvailablePorts int
)

-----------------------------------------------------------------------------
-- Get Technical Detail Records for all the Technical Trunks associated
-- with the commercial trunk
-----------------------------------------------------------------------------

Declare Get_All_TechnicalTrunks_Cur Cursor For
Select distinct tbl2.trunkID
from tb_Trunk tbl1
inner join tb_TrunkDetail tbl2 on tbl1.trunkID = tbl2.TrunkID
where tbl2.flag & 1 <> 1
and tbl1.flag & 1 <> 1
and tbl2.commercialtrunkID = @CommercialTrunkID
and tbl1.trunktypeid <> 9 -- Not a commercial trunk

Open Get_All_TechnicalTrunks_Cur
Fetch Next From Get_All_TechnicalTrunks_Cur Into @TechnicalTrunkID 

While @@FETCH_STATUS = 0
Begin

        
		delete from #TempTechnicalTrunkDetails
		
		insert into #TempTechnicalTrunkDetails
		Exec SP_UITechnicalTrunkGetAttributeHistory @TechnicalTrunkID
		
		--------------------------------------------------------
		-- Remove records for the Technical Trunk, when it was
		-- not associated with the commercial trunk
		--------------------------------------------------------
		
		delete from #TempTechnicalTrunkDetails
		where isnull(CommercialTrunkID,0) <> @CommercialTrunkID
		
		--select 'STEP 1' ,*
		--from #TempTechnicalTrunkDetails
		
		update tbl2
		set tbl2.EndDate = tbl1.EndDate,
			tbl2.ActivatedPorts = 
					Case 
						when CONVERT(date , getdate()) between tbl2.BeginDate and ISNULL(tbl2.EndDate , CONVERT(date , getdate()) )
						      Then  tbl2.ActivatedPorts
						else tbl1.ActivatedPorts
					End,
		    tbl2.AvailablePorts = 
					Case 
						when CONVERT(date , getdate()) between tbl2.BeginDate and ISNULL(tbl2.EndDate , CONVERT(date , getdate()) )
						      Then  tbl2.AvailablePorts
						else tbl1.AvailablePorts
					End		    
		from #TempTechnicalTrunkDetails tbl1
		inner join #TempTechnicalTrunkDetails tbl2 on tbl1.rID + 1 = tbl2.rID
		where tbl1.ActiveStatusID = 1
		and tbl2.ActiveStatusID = 1	
		
		--select 'STEP 2' ,*
		--from #TempTechnicalTrunkDetails		
		
		
		delete tbl1
		from #TempTechnicalTrunkDetails tbl1
		inner join #TempTechnicalTrunkDetails tbl2 on tbl1.rID + 1 = tbl2.rID
		where tbl1.ActiveStatusID = 1
		and tbl2.ActiveStatusID = 1
		
		--select 'STEP 3' ,*
		--from #TempTechnicalTrunkDetails	
	
		
		insert into #TempTechnicalTrunkActiveDetails
		( TrunkId , TrunkDetailID , Trunk , BeginDate , EndDate , SwitchID , Switch , ActivatedPorts , AvailablePorts)
		select tbl1.TrunkId , tbl1.TrunkDetailID , tbl2.Trunk , 
			   tbl1.BeginDate , tbl1.EndDate , tbl2.SwitchID , tbl3.switch,
			   tbl1.ActivatedPorts , tbl1.AvailablePorts
		from #TempTechnicalTrunkDetails tbl1
		inner join tb_Trunk tbl2 on tbl1.trunkId = tbl2.TrunkID
		inner join tb_Switch tbl3 on tbl2.SwitchID = tbl3.SwitchId
		where tbl1.TrunkId = @TechnicalTrunkID
		and ActiveStatusID = 1
		and BeginDate = 
		(
			select MAX(BeginDate)
			From #TempTechnicalTrunkDetails
			where TrunkId = @TechnicalTrunkID
			and ActiveStatusID = 1
		)

		Fetch Next From Get_All_TechnicalTrunks_Cur 
		Into @TechnicalTrunkID 


End

Close Get_All_TechnicalTrunks_Cur
Deallocate Get_All_TechnicalTrunks_Cur

if (@DisplayFlag = 1)
Begin
	select TrunkId , TrunkDetailID , Trunk , BeginDate , 
	       EndDate , SwitchID , Switch , ActivatedPorts ,
		   AvailablePorts
	from #TempTechnicalTrunkActiveDetails
	where CONVERT(date , getdate()) between BeginDate and ISNULL(EndDate , CONVERT(date , getdate()) )
	order by Switch, Trunk
End

if (@DisplayFlag = 2)
Begin
	select TrunkId , TrunkDetailID , Trunk , BeginDate , 
	       EndDate , SwitchID , Switch , ActivatedPorts ,
		   AvailablePorts
	from #TempTechnicalTrunkActiveDetails
	where BeginDate > CONVERT(date , getdate())
	order by Switch, Trunk
End

select @ActivatedPorts = isnull(SUM(ActivatedPorts) ,0) ,
       @AvailablePorts = isnull(SUM(AvailablePorts), 0) 
From #TempTechnicalTrunkActiveDetails
where CONVERT(date , getdate()) between BeginDate and ISNULL(EndDate , CONVERT(date , getdate()) )

-----------------------------------------------
-- Drop temporary tables after processing data
-----------------------------------------------

Drop table #TempTechnicalTrunkDetails
Drop table #TempTechnicalTrunkActiveDetails
GO
