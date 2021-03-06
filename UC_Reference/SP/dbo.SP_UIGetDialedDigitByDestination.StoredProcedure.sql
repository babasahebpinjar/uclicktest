USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetDialedDigitByDestination]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetDialedDigitByDestination]
(
	@DestinationID int ,
	@SelectDate date
)
As

select DialedDigitsID , DialedDigits , IntIndicator , BeginDate , EndDate ,
       ModifiedDate , UC_Admin.dbo.FN_GetUserName(ModifiedByID) as ModifiedByUser
from tb_DialedDigits 
where DestinationID = @DestinationID
and @SelectDate between BeginDate and isnull(EndDate , @SelectDate)
GO
