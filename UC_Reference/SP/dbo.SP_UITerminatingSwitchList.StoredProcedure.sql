USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITerminatingSwitchList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UITerminatingSwitchList]
(
	@OriginatingSwitchID int,
	@TrunkTypeID int
)
As

if (  ( @TrunkTypeID = 5 ) and (  ( select switchtypeid from tb_switch where switchID = @OriginatingSwitchID ) <> 5 ))
Begin

		select switchId as ID , Switch as Name
		from tb_Switch
		where switchtypeid <> 5
		and flag & 1 <> 1
		and switchID <> isnull(@OriginatingSwitchID , switchID )

End

Else
Begin
		select switchId as ID , Switch as Name
		from tb_Switch
		where 1 = 2
End

GO
