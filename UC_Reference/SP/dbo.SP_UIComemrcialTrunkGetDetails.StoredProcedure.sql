USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIComemrcialTrunkGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIComemrcialTrunkGetDetails]
(
   @CommercialTrunkID int
)
As

------------------------------------------------------------------
-- Get the Available and Activated ports on the commercial trunk
------------------------------------------------------------------

Declare @ActivatedPorts int,
        @AvailablePorts int


Exec SP_UIGetAssociatedTechnicalTrunks @CommercialTrunkID , 0 , @AvailablePorts output , @ActivatedPorts output


-----------------------------------------------------------------
-- Check if the commercial trunk has only future records or
-- there are other detail records as well effective current date
-----------------------------------------------------------------
----------------------------------------------------
-- Depending on the same get Latest Commercial Trunk
-- Details from DB
----------------------------------------------------

-- Current Date Trunk

if  (  ( 
			select MAX(EffectiveDate)
			from tb_trunkDetail 
			where trunkID = @CommercialTrunkID
			and flag & 1 <> 1
			and EffectiveDate <= convert(Date , GetDate())
		) is not null
	)
Begin

		Select tbl1.TrunkID , tbl1.Trunk ,  
			   tbl1.AccountID , tbl5.Account , tbl1.TrunkTypeID , tbl2.TrunkType ,
			   tbl1.SwitchID , tbl3.Switch  , tbl1.Description , 
			   tbl8.EffectiveDate ,tbl8.ActiveStatusID , tbl9.ActiveStatus as Status, 
			   @AvailablePorts as AvailablePorts , @ActivatedPorts as ActivatedPorts,
			   tbl8.DirectionID , tbl11.Direction, tbl1.Note ,
			   Case
					when tbl1.ModifiedDate >= tbl8.ModifiedDate then tbl1.ModifiedDate
					Else tbl8.ModifiedDate
			   End as ModifiedDate,
			   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as MobifiedbyUser      
		from tb_trunk tbl1
		inner join tb_trunktype tbl2 on tbl1.trunktypeid = tbl2.TrunkTypeID
		inner join tb_Switch tbl3 on tbl1.SwitchID = tbl3.SwitchID
		inner join tb_Account tbl5 on tbl1.AccountID = tbl5.AccountID	
		inner join tb_trunkDetail tbl8 on tbl1.TrunkId = tbl8.trunkID
		inner join tb_ActiveStatus tbl9 on tbl8.ActiveStatusID = tbl9.ActiveStatusID
		inner join tb_direction tbl11 on tbl8.DirectionID = tbl11.DirectionID
		where tbl1.trunkid = @CommercialTrunkID
		and tbl1.Flag & 1 <> 1
		and tbl8.flag & 1 <> 1
		and tbl8.EffectiveDate = 
		   (
				select MAX(tbl81.EffectiveDate)
				from tb_trunkDetail tbl81
				where tbl1.trunkID = tbl81.trunkID
				and tbl81.flag & 1 <> 1
				and tbl81.EffectiveDate <= convert(Date , GetDate())
		   )

End

-- Future Date Trunk

Else
Begin

		Select tbl1.TrunkID , tbl1.Trunk ,  
			   tbl1.AccountID , tbl5.Account , tbl1.TrunkTypeID , tbl2.TrunkType ,
			   tbl1.SwitchID , tbl3.Switch  , tbl1.Description , 
			   tbl8.EffectiveDate ,tbl8.ActiveStatusID , tbl9.ActiveStatus as Status, 
			   @AvailablePorts as AvailablePorts , @ActivatedPorts as ActivatedPorts,
			   tbl8.DirectionID , tbl11.Direction, tbl1.Note ,
			   Case
					when tbl1.ModifiedDate >= tbl8.ModifiedDate then tbl1.ModifiedDate
					Else tbl8.ModifiedDate
			   End as ModifiedDate,
			   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as MobifiedbyUser      
		from tb_trunk tbl1
		inner join tb_trunktype tbl2 on tbl1.trunktypeid = tbl2.TrunkTypeID
		inner join tb_Switch tbl3 on tbl1.SwitchID = tbl3.SwitchID
		inner join tb_Account tbl5 on tbl1.AccountID = tbl5.AccountID	
		inner join tb_trunkDetail tbl8 on tbl1.TrunkId = tbl8.trunkID
		inner join tb_ActiveStatus tbl9 on tbl8.ActiveStatusID = tbl9.ActiveStatusID
		inner join tb_direction tbl11 on tbl8.DirectionID = tbl11.DirectionID
		where tbl1.trunkid = @CommercialTrunkID
		and tbl1.Flag & 1 <> 1
		and tbl8.flag & 1 <> 1
		and tbl8.EffectiveDate = 
		   (
				select MIN(tbl81.EffectiveDate)
				from tb_trunkDetail tbl81
				where tbl1.trunkID = tbl81.trunkID
				and tbl81.flag & 1 <> 1
				and tbl81.EffectiveDate >= convert(Date , GetDate())
		   )

End

GO
