USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICustomerSourceGetDetails]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICustomerSourceGetDetails]
(
	@SourceID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


------------------------------------------------------------------
-- Check to ensure that the CustomerSourceID is not null or invalid
------------------------------------------------------------------

if ( ( @SourceID is Null) or not exists (select 1 from tb_Source where SourceID = @SourceID and SourcetypeId = -3) )
Begin

	set @ErrorDescription = 'ERROR !!!! Source ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

Declare @SourceTypeID int

Select @SourceTypeID = SourcetypeID
from tb_Source
where SourceID = @SourceID

------------------------------
-- Get details for the source
------------------------------

if (@SourceTypeID = -3) -- Customer Source Type
Begin

	select Src.SourceID ,Src.[Source] , Src.SourceAbbrv,
	       Acc.AccountID , Acc.Account,
	       Case
				When ActiveStatusID = 1 then 'Active'
				When ActiveStatusID = 2 then 'InActive'
		   End as Status,
	       Rp.RatePlanID , Rp.RatePlan , Cp.CalltypeID , Cp.Calltype,
		   Curr.CurrencyID , Curr.Currency , Nt.Content as Note ,Src.ModifiedDate,
		   UC_Admin.dbo.FN_GetUserName(Src.ModifiedByID) as ModifiedByUser
	from tb_Source Src
	inner join UC_Reference.dbo.tb_Account Acc on Src.ExternalCode = Acc.AccountID
	inner join UC_Reference.dbo.tb_RatePlan Rp on Src.RatePlanID = Rp.RatePlanID
	inner join UC_Reference.dbo.tb_Calltype Cp on Src.CalltypeID = Cp.CallTypeID
	inner join UC_Reference.dbo.tb_Currency Curr on Src.CurrencyID = Curr.CurrencyID
	inner join tb_Note Nt on Src.NoteID = Nt.NoteID
	where SourceID = @SourceID
	
End

Return 0
GO
