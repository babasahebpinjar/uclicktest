USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery37.sql|7|0|C:\Users\PUSHPI~1.MAH\AppData\Local\Temp\~vsA1D0.sql

CREATE procedure [dbo].[SP_UIAgreementUpdate]
(
    @AgreementID int,
	@Agreement varchar(60),
	@AgreementAbbrv varchar(20),
	@BeginDate datetime,
	@EndDate datetime,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As


Declare @AccountId int

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------
-- Check if AgreementID is NULL or not
---------------------------------------

if (@AgreementID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


--------------------------------------------------------
-- Get the associated account id for further processing
--------------------------------------------------------

select @AccountId = accountid
from tb_agreement
where agreementid = @AgreementID

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

if exists (select 1 from tb_agreement where ( ltrim(rtrim(Agreement)) = ltrim(rtrim(@Agreement)) or ltrim(rtrim(AgreementAbbrv)) = ltrim(rtrim(@AgreementAbbrv))) and agreementid <> @AgreementID )
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
and AgreementId <> @AgreementID

Exec  SP_BSCheckDateOverlap @BeginDate , @EndDate , @DateOverlapCheckFlag output

if ( @DateOverlapCheckFlag = 1 )
Begin

	set @ErrorDescription = 'ERROR !!! There exist agreement(s) in the system having dates overlapping with the edit agreement'
	set @ResultFlag = 1
	drop table #TempDateOverlapCheck
	return 1

End

drop table #TempDateOverlapCheck


--------------------------------------------------------------------------------
-- Check if any update to the effective dates of the agreement causes a mismatch
-- with Service Level or POI data
--------------------------------------------------------------------------------

if exists ( select 1 from tb_agreementPOI where AgreementID = @AgreementID and BeginDate < @BeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! there are POI records having begin date lesser than the Agreement effective date : ( '+ convert(varchar(10) , @BeginDate, 120) + ' )'
	set @ResultFlag = 1
	return 1

End

if exists ( select 1 from tb_AgreementSL where AgreementID = @AgreementID and BeginDate < @BeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! there are Service Level Agreement records having begin date lesser than the Agreement effective date : ( '+ convert(varchar(10) , @BeginDate, 120) + ' )'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------------------------
-- Check if any update to the effective dates of the agreement causes a mismatch
-- with Rate Plan and Rating Scenario
--------------------------------------------------------------------------------


if exists ( select 1 from tb_Rateplan where AgreementID = @AgreementID and BeginDate < @BeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! there are Rate Plan records having begin date lesser than the Agreement effective date : ( '+ convert(varchar(10) , @BeginDate, 120) + ' )'
	set @ResultFlag = 1
	return 1

End

if exists ( select 1 from tb_RatingScenario where Attribute1ID = @AgreementID and BeginDate < @BeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! there are Rating Scenario records having begin date lesser than the Agreement effective date : ( '+ convert(varchar(10) , @BeginDate, 120) + ' )'
	set @ResultFlag = 1
	return 1

End

if ( @EndDate is not NULL)
Begin

		if exists ( select 1 from tb_agreementPOI where  AgreementID = @AgreementID and (( EndDate is NULL ) or ( EndDate > @EndDate )))
		Begin

			set @ErrorDescription = 'ERROR !!! there are POI records having End date greater than the Agreement End date : ( '+ convert(varchar(10) , @EndDate, 120) + ' )'
			set @ResultFlag = 1
			return 1

		End

		if exists ( select 1 from tb_agreementSL where  AgreementID = @AgreementID and (( EndDate is NULL ) or ( EndDate > @EndDate )))
		Begin

			set @ErrorDescription = 'ERROR !!! there are Service Level Agreement records having End date greater than the Agreement End date : ( '+ convert(varchar(10) , @EndDate, 120) + ' )'
			set @ResultFlag = 1
			return 1

		End

		if exists ( select 1 from tb_Rateplan where AgreementID = @AgreementID and (( EndDate is NULL ) or ( EndDate > @EndDate )))
		Begin

			set @ErrorDescription = 'ERROR !!! there are Rate Plan records having End date greater than the Agreement End date : ( '+ convert(varchar(10) , @EndDate, 120) + ' )'
			set @ResultFlag = 1
			return 1

		End

		if exists ( select 1 from tb_RatingScenario where Attribute1ID = @AgreementID and ( EndDate is NULL ) or ( EndDate > @EndDate ))
		Begin

			set @ErrorDescription = 'ERROR !!! there are Service Level Agreement records having End date greater than the Agreement End date : ( '+ convert(varchar(10) , @EndDate, 120) + ' )'
			set @ResultFlag = 1
			return 1

		End

End

---------------------------------------------------------
-- Insert record into the database for the new agreement
---------------------------------------------------------

Begin Try

	update tb_agreement
	set Agreement = @Agreement,
		AgreementAbbrv = @AgreementAbbrv,
		BeginDate = @BeginDate,
		EndDate = @EndDate,
		ModifiedDate = Getdate(),
		ModifiedByID = @UserID
     where AgreementID  = @AgreementID


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! During update of Agreement record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch



GO
