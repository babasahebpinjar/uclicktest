USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRErrorTypeList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICDRErrorTypeList]
As

select CDRErrorTypeID as ID , CDRErrorType as Name
from tb_CDRErrorType
where flag & 1 <> 1
order by CDRErrorTypeID
GO
