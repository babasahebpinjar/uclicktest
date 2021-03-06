USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCDRProcessingRuleDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetCDRProcessingRuleDetails]
(
	@CDRProcessingRuleID int ,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-----------------------------------------------------------------------
-- Check to ensure that the Processing Rule is not NULL and exists
-- in the system
------------------------------------------------------------------------

if ( (@CDRProcessingRuleID is NULL) or not exists (select 1 from tb_CDRProcessingRule where CDRProcessingRuleID = @CDRProcessingRuleID) )
Begin

		set @ErrorDescription = 'ERROR !!!! CDR Processing Rile ID passed is either NULL or does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

------------------------
-- Return the data set
------------------------

select tbl1.CDRProcessingRuleID, tbl1.RuleOrder, tbl1.PrefixCode, tbl1.ServiceLevelID, tbl4.ServiceLevel ,tbl1.TrunkID, tbl2.Trunk ,
       tbl1.DirectionID, tbl3.Direction,
       BeginDate, EndDate, tbl1.ModifiedDate,
       UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
From tb_CDRProcessingRule tbl1
inner join tb_Trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID
inner join tb_Direction tbl3 on tbl1.DirectionID = tbl3.DirectionID
inner join tb_ServiceLevel tbl4 on tbl1.ServiceLevelID = tbl4.ServiceLevelID
where CDRProcessingRuleID = @CDRProcessingRuleID

Return 0
GO
