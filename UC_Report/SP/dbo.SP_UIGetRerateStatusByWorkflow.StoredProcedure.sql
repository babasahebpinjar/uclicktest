USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetRerateStatusByWorkflow]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetRerateStatusByWorkflow]
(
	@RerateID int
)
As

Declare @RerateCurrentStatusID int

--------------------------------------------------------
-- Get the current status of the CDR Extract from schema
--------------------------------------------------------

Select @RerateCurrentStatusID = RerateStatusID
From tb_Rerate
where RerateID = @RerateID


--------------------------------------------------------
-- Check the next permissible status(es) for the Extract
-- from the workflow schema
---------------------------------------------------------

Select tbl2.RerateStatusID as ID , tbl2.RerateStatus as Name
from tb_RerateStatusWorkflow tbl1
inner join tb_RerateStatus tbl2 on tbl1.ToRerateStatusID = tbl2.RerateStatusID
where tbl1.FromRerateStatusID = @RerateCurrentStatusID
order by tbl2.RerateStatus

Return 0
GO
