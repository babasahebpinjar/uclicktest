USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UITechnicalTrunkGetDetails]
(
	@TrunkID int
)
As



-------------------------------------------------------------------
-- Check if this is a future date dtrunk, or has a detail effective
-- as off current date. Depending on the same, we display the trunk
-- details
--------------------------------------------------------------------

if (    
		 (
				select MAX(EffectiveDate)
				from tb_trunkDetail 
				where trunkID = @TrunkID
				and flag & 1 <> 1
				and EffectiveDate <= GetDate()
		  ) is not null
	)
Begin

		Select tbl1.TrunkID , tbl1.Trunk , tbl1.CLLI , 
			   tbl1.AccountID , tbl5.Account , tbl1.TrunkTypeID , tbl2.TrunkType ,
			   tbl1.SwitchID , tbl3.Switch as OriginatingSwitch , tbl1.TSwitchID , tbl4.Switch as TerminatingSwitch,
			   tbl1.CDRMatch , tbl8.EffectiveDate , tbl8.ActivatedPorts , tbl8.AvailablePorts , 
			   tbl8.ActiveStatusID , tbl9.ActiveStatus as Status, tbl8.CommercialTrunkID , tbl10.trunk as CommercialTrunk,
			   tbl8.DirectionID , tbl11.Direction, tbl1.TimeZoneShiftMinutes , tbl8.TargetUsage,
			   tbl1.OrigPointCode , tbl1.PointCode,tbl1.ReportCode , tbl1.Description ,
			   tbl1.Note , tbl1.TrunkIPAddress,tbl1.TransmissionTypeID , tbl6.TransmissionType,
			   tbl1.SignalingTypeID , tbl7.SignalingType , tbl8.TrunKDetailID , tbl8.ProcessCode ,
			   tbl1.ModifiedDate, UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as MobifiedbyUser	      
		from tb_trunk tbl1
		inner join tb_trunktype tbl2 on tbl1.trunktypeid = tbl2.TrunkTypeID
		inner join tb_Switch tbl3 on tbl1.SwitchID = tbl3.SwitchID
		left join tb_Switch tbl4 on tbl1.TSwitchID = tbl4.SwitchID
		inner join tb_Account tbl5 on tbl1.AccountID = tbl5.AccountID
		left join tb_TransmissionType tbl6 on tbl1.TransmissionTypeID = tbl6.TransmissionTypeID
		left join tb_SignalingType tbl7 on tbl1.SignalingTypeID = tbl7.SignalingTypeID
		inner join tb_trunkDetail tbl8 on tbl1.TrunkId = tbl8.trunkID
		inner join tb_ActiveStatus tbl9 on tbl8.ActiveStatusID = tbl9.ActiveStatusID
		left  join tb_trunk tbl10 on tbl8.CommercialTrunkID = tbl10.TrunkID
		inner join tb_direction tbl11 on tbl8.DirectionID = tbl11.DirectionID
		where tbl1.trunkid = @TrunkID
		and tbl1.Flag & 1 <> 1
		and tbl8.flag & 1 <> 1
		and tbl8.EffectiveDate = 
		   (
				select MAX(tbl81.EffectiveDate)
				from tb_trunkDetail tbl81
				where tbl1.trunkID = tbl81.trunkID
				and tbl81.flag & 1 <> 1
				and tbl81.EffectiveDate <= GetDate()
		   )

End

Else
Begin

		Select tbl1.TrunkID , tbl1.Trunk , tbl1.CLLI , 
			   tbl1.AccountID , tbl5.Account , tbl1.TrunkTypeID , tbl2.TrunkType ,
			   tbl1.SwitchID , tbl3.Switch as OriginatingSwitch , tbl1.TSwitchID , tbl4.Switch as TerminatingSwitch,
			   tbl1.CDRMatch , tbl8.EffectiveDate , tbl8.ActivatedPorts , tbl8.AvailablePorts , 
			   tbl8.ActiveStatusID , tbl9.ActiveStatus as Status, tbl8.CommercialTrunkID , tbl10.trunk as CommercialTrunk,
			   tbl8.DirectionID , tbl11.Direction, tbl1.TimeZoneShiftMinutes , tbl8.TargetUsage,
			   tbl1.OrigPointCode , tbl1.PointCode,tbl1.ReportCode , tbl1.Description ,
			   tbl1.Note , tbl1.TrunkIPAddress,tbl1.TransmissionTypeID , tbl6.TransmissionType,
			   tbl1.SignalingTypeID , tbl7.SignalingType , tbl8.TrunKDetailID , tbl8.ProcessCode ,
			   tbl1.ModifiedDate, UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as MobifiedbyUser	      
		from tb_trunk tbl1
		inner join tb_trunktype tbl2 on tbl1.trunktypeid = tbl2.TrunkTypeID
		inner join tb_Switch tbl3 on tbl1.SwitchID = tbl3.SwitchID
		left join tb_Switch tbl4 on tbl1.TSwitchID = tbl4.SwitchID
		inner join tb_Account tbl5 on tbl1.AccountID = tbl5.AccountID
		left join tb_TransmissionType tbl6 on tbl1.TransmissionTypeID = tbl6.TransmissionTypeID
		left join tb_SignalingType tbl7 on tbl1.SignalingTypeID = tbl7.SignalingTypeID
		inner join tb_trunkDetail tbl8 on tbl1.TrunkId = tbl8.trunkID
		inner join tb_ActiveStatus tbl9 on tbl8.ActiveStatusID = tbl9.ActiveStatusID
		left  join tb_trunk tbl10 on tbl8.CommercialTrunkID = tbl10.TrunkID
		inner join tb_direction tbl11 on tbl8.DirectionID = tbl11.DirectionID
		where tbl1.trunkid = @TrunkID
		and tbl1.Flag & 1 <> 1
		and tbl8.flag & 1 <> 1
		and tbl8.EffectiveDate = 
		   (
				select MIN(tbl81.EffectiveDate)
				from tb_trunkDetail tbl81
				where tbl1.trunkID = tbl81.trunkID
				and tbl81.flag & 1 <> 1
				and tbl81.EffectiveDate >= GetDate()
		   )

End
GO
