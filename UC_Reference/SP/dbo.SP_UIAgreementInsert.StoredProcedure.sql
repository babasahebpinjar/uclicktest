USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UIAgreementInsert]
(
	@AccountID int ,
	@Agreement varchar(60),
	@AgreementAbbrv varchar(20),
	@BeginDate datetime,
	@EndDate datetime,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As


set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------
-- Check if AccountID is NULL or not
---------------------------------------

if (@AccountID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Account ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------
-- Check if account exists in system or not
--------------------------------------------

if not exists (select 1 from tb_account where accountid = @AccountID)
Begin

	set @ErrorDescription = 'ERROR !!! No account exists in the system for the ACCOUNTID'
	set @ResultFlag = 1
	return 1

End


--------------------------------------------
-- Check if account is inactive or not
--------------------------------------------

if exists (select 1 from tb_account where accountid = @AccountID and flag & 32 = 32)
Begin

	set @ErrorDescription = 'ERROR !!! Cannot add agreement to an inactive account. Please activate the account to proceed'
	set @ResultFlag = 1
	return 1

End

---------------------------------------------------------------
-- Make sure that agreement and agreement abbrv are not NULL
-- or empty
---------------------------------------------------------------

if( (@Agreement is NULL) or ((@Agreement is not NULL) and (len(ltrim(rtrim(@Agreement))) = 0  )))
Begin

	set @ErrorDescription = 'ERROR !!! Agreement Name cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End

if( (@AgreementAbbrv is NULL) or ((@AgreementAbbrv is not NULL) and (len(ltrim(rtrim(@AgreementAbbrv))) = 0  )))
Begin

	set @ErrorDescription = 'ERROR !!! Agreement abbreviation cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------------------------------
-- Check to ensure that the Agreement name and abbreviation are unique values
-----------------------------------------------------------------------------

if exists (select 1 from tb_agreement where ltrim(rtrim(Agreement)) = ltrim(rtrim(@Agreement)) or ltrim(rtrim(AgreementAbbrv)) = ltrim(rtrim(@AgreementAbbrv)) )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement name and abbreviation need to be unique values'
	set @ResultFlag = 1
	return 1

End


--------------------------------------------------------------------
-- Make sure that the begin date is lesser than equal to End Date
--------------------------------------------------------------------

if( ( @EndDate is not NULL ) and ( @BeginDate >= @EndDate) )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be greater than or equal to the End Date'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------------------
-- Check to see that there are no overlapping agreements in the 
-- system for the account
-----------------------------------------------------------------

Declare @DateOverlapCheckFlag int = 0

create table #TempDateOverlapCheck 
(
	EntityName varchar(100),
	BeginDate datetime,
	EndDate datetime
)

insert into #TempDateOverlapCheck
select distinct agreement , Begindate , EndDate
from tb_agreement
where accountid = @AccountID

Exec  SP_BSCheckDateOverlap @BeginDate , @EndDate , @DateOverlapCheckFlag output

if ( @DateOverlapCheckFlag = 1 )
Begin

	set @ErrorDescription = 'ERROR !!! There exist agreement(s) in the system having dates overlapping with the new agreement'
	set @ResultFlag = 1
	drop table #TempDateOverlapCheck
	return 1

End

drop table #TempDateOverlapCheck

---------------------------------------------------------
-- Insert record into the database for the new agreement
---------------------------------------------------------

Begin Try

	insert into tb_agreement
	(
		AccountID,
		Agreement,
		AgreementAbbrv,
		BeginDate,
		EndDate,
		ModifiedDate,
		ModifiedByID
	)
	values
	(
		@AccountID,
		@Agreement,
		@AgreementAbbrv,
		@BeginDate,
		@EndDate,
		getdate(),
		@UserID
	)


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! During creation of new Agreement record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch


GO
