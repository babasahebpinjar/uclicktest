USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UISignalingTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_UISignalingTypeList]
As

select signalingtypeID as ID , SignalingType as Name
from tb_SignalingType
where flag & 1 <> 1
GO
