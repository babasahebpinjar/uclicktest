USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UIAgreementGetDetails]
(
	@AgreementId int
)
As

Select AgreementID, Agreement , AgreementAbbrv , BeginDate , EndDate, AccountID,
ModifiedDate , UC_Admin.dbo.FN_GetUserName(ModifiedById) as ModifiedByUser
from tb_Agreement
where AgreementID = @AgreementID
GO
