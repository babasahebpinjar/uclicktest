USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementPOIDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAgreementPOIDelete]
(
       @AgreementPOIID int,
       @ErrorDescription varchar(2000) output,
       @ResultFlag int output
)
As
 
set @ErrorDescription = NULL
set @ResultFlag = 0
 
Begin Try
 
			Delete from tb_AgreementPOI
			where agreementPOIID = @AgreementPOIID
 
End Try
 
Begin Catch
 
              set  @ResultFlag = 1
              set  @ErrorDescription = 'ERROR !!! Deleting record for Agreement Point Of Interconnect. '+ ERROR_MESSAGE()
              Return 1     
 
End Catch
 
Return 0
GO
