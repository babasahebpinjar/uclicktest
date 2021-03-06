USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetDestinationDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetDestinationDetails]
(
	@DestinationID int
)
As

Select tbl1.DestinationID , tbl1.Destination , tbl1.DestinationAbbrv , tbl2.DestinationTypeID , tbl2.DestinationType,
       tbl3.CountryID , tbl3.Country , tbl4.NumberPlanID ,tbl4.NumberPlan , tbl1.BeginDate , tbl1.EndDate,
	   tbl1.ModifiedDate,
	   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
from tb_Destination tbl1
inner join tb_DestinationType tbl2 on tbl1.DestinationTypeID = tbl2.DestinationTypeID
inner join tb_Country tbl3 on tbl1.CountryID = tbl3.CountryID
inner join tb_Numberplan tbl4 on tbl1.numberplanid = tbl4.NumberPlanID
where DestinationID = @DestinationID
GO
