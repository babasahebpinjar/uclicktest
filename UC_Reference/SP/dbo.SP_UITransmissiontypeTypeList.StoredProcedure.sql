USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITransmissiontypeTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_UITransmissiontypeTypeList]
As

select TransmissiontypeID as ID , TransmissionType as Name
from tb_TransmissionType
where flag & 1 <> 1

GO
