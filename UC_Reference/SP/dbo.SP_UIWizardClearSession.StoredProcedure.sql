USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardClearSession]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIWizardClearSession]
(
	@SessionID varchar(60)
)
As

Delete from wtb_Wizard_MassSetup
where SessionID = @SessionID
GO
