USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCustomValidationStatus]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIGetCustomValidationStatus]
--With Encryption
As

Select 0 , 'All'
union
Select ValidationStatusID , ValidationStatus
from tb_ValidationStatus

Return
GO
