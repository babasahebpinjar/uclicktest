USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPhysicalTrunkBlockStatus]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIPhysicalTrunkBlockStatus]
(
	@TrunkID int
)
As

select 
	Case
		When Flag & 64 = 64 then 1
		Else 0
	End as BlockStatus
from tb_Trunk
Where TrunkTypeID <> 9
and TrunkID = @TrunkID
GO
