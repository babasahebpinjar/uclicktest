USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetVendorReferenceDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetVendorReferenceDetails]
(
	@ReferenceId int
)
--With Encryption
As

select tbl1.ReferenceID ,tbl1.ReferenceNo , acc.Account, offtemp.offertemplatename, src.Source ,  src2.source as ExtendedVendorSource,
        ParseTemplateName,
	Case
		When MultipleSheetsInOffer = 1 then 'Y'
		When MultipleSheetsInOffer = 0 then 'N'
	End MultipleSheetsInOffer,
	Case
		When AutoOfferUploadFlag = 1 then 'Y'
		When AutoOfferUploadFlag = 0 then 'N'
	End AutoOfferUploadFlag,
	Case
		When SkipRateIncreaseCheck = 1 then 'Y'
		When SkipRateIncreaseCheck = 0 then 'N'
	End SkipRateIncreaseCheck,
	Case
		When EnableEmailCheck = 1 then 'Y'
		When EnableEmailCheck = 0 then 'N'
	End EnableEmailCheck,
	Case
		When CheckNewDestination = 1 then 'Y'
		When CheckNewDestination = 0 then 'N'
	End CheckNewDestination,
	RateIncreasePeriod,
	ModifiedDate,
	usr.Name
from TB_VendorReferenceDetails tbl1
inner join vw_Accounts acc on tbl1.Accountid = acc.AccountID
left join vw_vendorsource src on tbl1.VendorSourceid = src.sourceid
left join vw_OfferTemplate offtemp on tbl1.Offertemplateid = offtemp.OfferTemplateID
left join vw_vendorsource src2 on tbl1.VendorValueSourceid = src2.sourceid
left join tb_Users usr on tbl1.modifiedbyID = usr.userid
where ReferenceId = @ReferenceId

Return
GO
