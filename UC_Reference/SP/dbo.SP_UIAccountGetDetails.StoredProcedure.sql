USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIAccountGetDetails]
(
	@AccountID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

if ( @AccountID is null )
Begin

		set @ErrorDescription = 'ERROR !!! AccountID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_Account where accountid = @AccountID )
Begin

		set @ErrorDescription = 'ERROR !!! Account does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

----------------------------------
-- Display details of the Account
----------------------------------

select
tbl1.AccountID,
tbl1.Account,
tbl1.AccountAbbrv,
tbl1.AccountNumber,
tbl1.CreditLimit,
tbl1.Deposit,
tbl1.Address1,
tbl1.Address2,
tbl1.City,
tbl1.State,
tbl1.Zip,
tbl1.Phone,
tbl1.Fax,
tbl1.Comment,
tbl1.AccountTypeID,
tbl2.AccountType,
tbl1.CompanyID,
tbl3.Company,
tbl4.Salutation + ' ' + tbl4.LastName + ' ' + tbl4.FirstName as Buyer,
tbl1.BuyerID,
tbl5.Salutation + ' ' + tbl5.LastName + ' ' + tbl5.FirstName as  Seller,
tbl1.SellerID,
tbl6.Salutation + ' ' + tbl6.LastName + ' ' + tbl6.FirstName as  ContactPerson,
tbl1.ContactPersonID,
tbl1.CountryID,
tbl7.Country,
tbl1.ModifiedDate,
UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser ,
Case
	 when tbl1.Flag & 32 = 32 then 'InActive'
	 Else 'Active'
End as AccountStatus,
Case
	 when tbl1.Flag & 32 = 32 then 2
	 Else 1
End as AccountStatusID
from tb_account tbl1
inner join tb_AccountType tbl2 on tbl1.AccountTypeID = tbl2.AccountTypeID
inner join tb_Company tbl3 on tbl1.CompanyID = tbl3.CompanyID
left join tb_Person tbl4 on tbl1.BuyerID = tbl4.PersonID
left join tb_Person tbl5 on tbl1.SellerID = tbl5.PersonID
left join tb_Person tbl6 on tbl1.ContactPersonID = tbl6.PersonID
left join tb_Country tbl7 on tbl1.CountryID = tbl7.CountryID
Where tbl1.AccountID = isnull( @AccountID , tbl1.AccountID)
and tbl1.Flag & 1 <> 1

return 0
GO
