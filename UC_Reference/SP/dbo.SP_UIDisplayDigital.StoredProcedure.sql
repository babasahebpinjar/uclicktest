USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDisplayDigital]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIDisplayDigital]
As

Select 0 as ID , 'No' as Name
Union
Select 1 as ID , 'Yes' as Name
GO
