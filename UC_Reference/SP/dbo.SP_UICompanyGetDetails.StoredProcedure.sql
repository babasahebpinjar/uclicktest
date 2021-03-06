USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICompanyGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SP_UICompanyGetDetails] 
(
	@CompanyID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


if ( @CompanyID is null )
Begin

		set @ErrorDescription = 'ERROR !!! Company ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_Company where CompanyID = @CompanyID )
Begin

		set @ErrorDescription = 'ERROR !!! Company does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

select CompanyID,Company FROM tb_Company 
where CompanyID = @CompanyID

Return 0


GO
