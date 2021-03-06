USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardGetServiceLevelCombinations]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardGetServiceLevelCombinations]
(
	@SessionID varchar(60),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag  = 0

--------------------------------------------------------
-- Check to ensure that record exists for the session
-- in the wizard tables with records for all the steps
--------------------------------------------------------

if not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Service Level Assignment' )
Begin

		set @ErrorDescription = 'ERROR !!! Wizard schema does not have information for the passed session id : ' + @SessionID
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------------------
-- Check to ensure that records exist for all the 5 steps
-- required in creation of the service level assignment
---------------------------------------------------------------

if not exists ( 
					select 1 
					from wtb_Wizard_MassSetup 
					where SessionID = @SessionID 
					and WizardName = 'Service Level Assignment' 
					and WizardStep = 1
					and VariableName = 'AgreementID'
			  )
Begin

		set @ErrorDescription = 'ERROR !!! Wizard schema does not have information for Agreement to be used for service level Assignment'
		set @ResultFlag = 1
		Return 1

End

if not exists ( 
					select 1 
					from wtb_Wizard_MassSetup 
					where SessionID = @SessionID 
					and WizardName = 'Service Level Assignment' 
					and WizardStep = 2
					and VariableName = 'SelectDate'
			  )
Begin

		set @ErrorDescription = 'ERROR !!! Wizard schema does not have information for effective date to be used for service level Assignment'
		set @ResultFlag = 1
		Return 1

End

if not exists ( 
					select 1 
					from wtb_Wizard_MassSetup 
					where SessionID = @SessionID 
					and WizardName = 'Service Level Assignment' 
					and WizardStep = 3
					and VariableName = 'ServiceLevelID'
			  )
Begin

		set @ErrorDescription = 'ERROR !!! Wizard schema does not have information for Service Level to be used for service level Assignment'
		set @ResultFlag = 1
		Return 1

End

if not exists ( 
					select 1 
					from wtb_Wizard_MassSetup 
					where SessionID = @SessionID 
					and WizardName = 'Service Level Assignment' 
					and WizardStep = 4
					and VariableName = 'TrunkID'
			  )
Begin

		set @ErrorDescription = 'ERROR !!! Wizard schema does not have information for Commercial Trunks to be used for service level Assignment'
		set @ResultFlag = 1
		Return 1

End

if not exists ( 
					select 1 
					from wtb_Wizard_MassSetup 
					where SessionID = @SessionID 
					and WizardName = 'Service Level Assignment' 
					and WizardStep = 5
					and VariableName = 'DestinationID'
			  )
Begin

		set @ErrorDescription = 'ERROR !!! Wizard schema does not have information for Destination(s) to be used for service level Assignment'
		set @ResultFlag = 1
		Return 1

End

------------------------------------------------------------------
-- Get the End date of the Agreement and use the same as the 
-- End date for the combination of SLAs
------------------------------------------------------------------

Declare @AgreementEndDate date,
        @GlobalEffectiveDate date

select @AgreementEndDate = agr.EndDate
from wtb_Wizard_MassSetup wzd
inner join tb_Agreement agr on convert(int ,wzd.VariableValue) = agr.agreementID
where SessionID = @SessionID 
and WizardName = 'Service Level Assignment' 
and WizardStep = 1
and VariableName = 'AgreementID'

select @GlobalEffectiveDate =  Convert(date , VariableValue)
from wtb_Wizard_MassSetup
where SessionID = @SessionID 
and WizardName = 'Service Level Assignment' 
and WizardStep = 2
and VariableName = 'SelectDate'

if ( (@AgreementEndDate is not NULL) and  ( @GlobalEffectiveDate > @AgreementEndDate ) )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot get Valid combinations as the Agreement is expiring ( ' + convert(varchar(20) , @AgreementEndDate, 120) + ' ) before the effective date for new SLAs ( ' + convert(varchar(20) , @GlobalEffectiveDate, 120) + ' ) '
	set @ResultFlag = 1
	Return 1

End

-------------------------------------------------------------------
-- Depending on the data provided in the Wizard table, build the
-- combination of all possible scenarios
-------------------------------------------------------------------

select tbl1.AgreementID , tbl1.Agreement, tbl2.EffectiveDate,
       tbl3.ServiceLevelID , tbl3.ServiceLevel , tbl4.Trunk , tbl4.TrunkID
into #TempServiceLevelCombinations
from
(
	select agr.AgreementID as AgreementID  , agr.Agreement
	from wtb_Wizard_MassSetup wzd
	inner join tb_Agreement agr on convert(int ,wzd.VariableValue) = agr.agreementID
	where SessionID = @SessionID 
	and WizardName = 'Service Level Assignment' 
	and WizardStep = 1
	and VariableName = 'AgreementID'
) as tbl1
cross join
(
	select Convert(date , VariableValue) as EffectiveDate
	from wtb_Wizard_MassSetup
	where SessionID = @SessionID 
	and WizardName = 'Service Level Assignment' 
	and WizardStep = 2
	and VariableName = 'SelectDate'
) as tbl2
cross join
 ( 
	select sl.ServiceLevelID , sl.ServiceLevel
	from wtb_Wizard_MassSetup wzd
	inner join tb_ServiceLevel sl on convert(int ,wzd.VariableValue) = sl.ServiceLevelID
	where SessionID = @SessionID 
	and WizardName = 'Service Level Assignment' 
	and WizardStep = 3
	and VariableName = 'ServiceLevelID'
 ) as tbl3
cross join
( 
	select trnk.TrunkID , trnk.Trunk
	from wtb_Wizard_MassSetup wzd
	inner join tb_Trunk trnk on convert(int ,wzd.VariableValue) = trnk.TrunkID
	where SessionID = @SessionID 
	and WizardName = 'Service Level Assignment' 
	and WizardStep = 4
	and VariableName = 'TrunkID'
 ) as tbl4


 ----------------------------------------------------------
 -- Add the Destination(s) to the combination depending on
 -- whether it is for All or few destinations
 ----------------------------------------------------------

 if exists    ( 
					select 1 
					from wtb_Wizard_MassSetup 
					where SessionID = @SessionID 
					and WizardName = 'Service Level Assignment' 
					and WizardStep = 5
					and VariableName = 'DestinationID'
					and VariableValue = 0
			  ) -- For All Destinations
Begin

	select AgreementID , Agreement, EffectiveDate,ServiceLevelID , ServiceLevel , 
	       TrunkID , Trunk , 0 as DestinationID , 'All Destinations' as Destination
	from #TempServiceLevelCombinations	

End

Else
Begin

	select tbl1.AgreementID ,tbl1.Agreement, tbl1.EffectiveDate,ServiceLevelID , tbl1.ServiceLevel , 
	       tbl1.TrunkID , tbl1.Trunk , tbl2.DestinationID , tbl2.Destination
	from #TempServiceLevelCombinations	tbl1
	cross join
	(
			select dest.DestinationID , dest.Destination
			from wtb_Wizard_MassSetup wzd
			inner join tb_Destination dest on convert(int , wzd.VariableValue) = dest.DestinationID
			where SessionID = @SessionID 
			and WizardName = 'Service Level Assignment' 
			and WizardStep = 5
			and VariableName = 'DestinationID'
	) as tbl2 

End

 ----------------------------------------------
 -- Drop the temporary tables created in the 
 -- process
 ----------------------------------------------

 drop table #TempServiceLevelCombinations

 return 0

GO
