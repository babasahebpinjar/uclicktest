USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountBlockStatus]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIAccountBlockStatus]
(
	@AccountID int
)
As

if exists (select 1 from tb_Trunk where TrunkTypeID <> 9 and AccountID = @AccountID and Flag & 64 = 0 ) -- One or more Unblocked trunks
	Select 0 as BlockStatus
Else
	Select 1 as BlockStatus

Return 0
GO
