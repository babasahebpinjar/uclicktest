USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDestinationTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIDestinationTypeList]
As

Select DestinationTypeID as ID , DestinationType as Name
from tb_DestinationType
where flag & 1 <> 1
GO
