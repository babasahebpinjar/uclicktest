USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionList]
As

Select RateDimensionID as ID , RateDimension as Name
from tb_RateDimension
GO
