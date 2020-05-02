USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UIAccountTypeList]
(
	@AccountTypeID int = NULL
)
As

Select Accounttypeid as ID , AccountType as Name
from tb_Accounttype
where AccountTypeID = isnull(@AccountTypeID , AccountTypeID)
and flag & 1 <> 1

return 0
GO
