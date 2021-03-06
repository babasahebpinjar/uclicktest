USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountAgreementList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIAccountAgreementList]
(
	@AccountID int = NULL,
	@SelectDate datetime
)
As

Select AgreementID , Agreement
from tb_Agreement
where accountID = isnull(@AccountID , accountID)
and flag & 1 <> 1 -- Dont display hidden agreements
and @SelectDate between BeginDate and isnull(Enddate , @SelectDate)
order by BeginDate ,Agreement
GO
