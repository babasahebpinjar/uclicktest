USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardGetUniqueSessionID]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_UIWizardGetUniqueSessionID]
(
	@SessionID varchar(200) output
)
AS


	Declare @RandomVal varchar(20)
	        
    set @RandomVal = convert(varchar(20) ,convert(int , RAND()*10000))        

	set @SessionID = @RandomVal + '-' +
					 replace(replace(replace(CONVERT(varchar(30) , getdate() , 120), ' ', ''), '-' ,''), ':' , '')
					 
	return 				 
       
       
    
GO
