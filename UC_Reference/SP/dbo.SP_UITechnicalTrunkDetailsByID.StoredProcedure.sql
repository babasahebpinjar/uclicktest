USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkDetailsByID]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_UITechnicalTrunkDetailsByID]
(
	@TrunkDetailID int
)
As

create Table #TempTrunkAttributehistory
(
	rID int identity (1,1),
	TrunkId int ,
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
	ModifiedbyID int
)

--------------------------------------------------
-- Get the TrunkID from the TrunkDetailID record
--------------------------------------------------

Declare @TrunkID int

Select @TrunkId = TrunkID
from tb_TrunkDetail
where trunkdetailID = @TrunkDetailID

----------------------------------------------------------------------
-- Get all the different trunk detail records for the technical trunk
----------------------------------------------------------------------

insert into #TempTrunkAttributehistory
(
	TrunkId,
	TrunkDetailID ,
	BeginDate ,
	EndDate ,
	ActiveStatusID ,
	ActiveStatus ,
	ActivatedPorts ,
	AvailablePorts ,
	AccountID ,
	Account ,
	CommercialTrunkID ,
	CommercialTrunk ,
	DirectionId ,
	Direction ,
	TargetUsage ,
	ProcessCode ,
	ModifiedDate ,
	ModifiedbyID 
)
Select tbl1.TrunkID , tbl8.TrunKDetailID ,
	   tbl8.EffectiveDate , NULL ,tbl8.ActiveStatusID , tbl9.ActiveStatus as Status,
	   tbl8.ActivatedPorts , tbl8.AvailablePorts , 
	   tbl1.AccountID , tbl5.Account ,	   
	   tbl8.CommercialTrunkID , tbl10.trunk as CommercialTrunk,
	   tbl8.DirectionID , tbl11.Direction, tbl8.TargetUsage, tbl8.ProcessCode ,
	   tbl8.ModifiedDate, tbl8.ModifiedByID	      
from tb_trunk tbl1
inner join tb_Account tbl5 on tbl1.AccountID = tbl5.AccountID
inner join tb_trunkDetail tbl8 on tbl1.TrunkId = tbl8.trunkID
inner join tb_ActiveStatus tbl9 on tbl8.ActiveStatusID = tbl9.ActiveStatusID
left  join tb_trunk tbl10 on tbl8.CommercialTrunkID = tbl10.TrunkID
inner join tb_direction tbl11 on tbl8.DirectionID = tbl11.DirectionID
where tbl1.trunkid = @TrunkID
and tbl1.Flag & 1 <> 1
and tbl8.flag & 1 <> 1
order by tbl8.EffectiveDate

-------------------------------------------------------
-- Update the End date for all the trunk attributes
-------------------------------------------------------

update tbl1
set tbl1.EndDate = DATEADD(dd , -1 , tbl2.BeginDate)
from #TempTrunkAttributehistory tbl1
left join #TempTrunkAttributehistory tbl2 on tbl1.rID + 1 = tbl2.rID
where tbl2.rId is not NULL

---------------------------------------------------------
-- Display record for the particular Trunk Detail ID
---------------------------------------------------------

select 	TrunkId,
		TrunkDetailID ,
		BeginDate ,
		EndDate ,
		ActiveStatusID ,
		ActiveStatus ,
		ActivatedPorts ,
		AvailablePorts ,
		AccountID ,
		Account ,
		CommercialTrunkID ,
		CommercialTrunk ,
		DirectionId ,
		Direction ,
		TargetUsage ,
		ProcessCode ,
		ModifiedDate ,
		UC_Admin.dbo.FN_GetUserName(ModifiedbyID) as ModifiedByUser 
From #TempTrunkAttributehistory
where TrunkDetailID = @TrunkDetailID -- Display only specific trunk detail record

Drop table #TempTrunkAttributehistory

Return 0
GO
