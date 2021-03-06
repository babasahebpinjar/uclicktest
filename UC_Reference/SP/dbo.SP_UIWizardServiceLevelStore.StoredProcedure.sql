USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardServiceLevelStore]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardServiceLevelStore]
(
	@SessionID varchar(60),
	@VariableName varchar(256),
	@VariableValue nvarchar(max),
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

-- STEP 1 : AGREEMENT
-- STEP 2 : SELECT DATE
-- STEP 3 : SERVICE LEVEL
-- STEP 4 : TRUNK
-- STEP 5 : DESTINATION

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @AccountID int,
        @AgreementID int

---------------------------------------------------
-- Check that the variable name is a valid value
---------------------------------------------------

if ( @VariableName not in ('AgreementID' , 'SelectDate' , 'ServiceLevelID' , 'TrunkID' , 'DestinationID') )
Begin

	set @ErrorDescription = 'ERROR !!! Variable Name is not a valid value'
	set @ResultFlag = 1
	Return 1

End

if ( @VariableName = 'AgreementID' )
Begin

		----------------------------------------------------------
		-- Check to ensure that the AgreementID passed in the 
		-- Variable is indeed a valid value
		----------------------------------------------------------

		if ( isnumeric(replace(@VariableValue , ',' , '|')) = 0 ) -- Delibrately used replace because ISNUMERIC function considers comma separated values as numeric
		Begin

			set @ErrorDescription = 'ERROR !!! AgreementID passed is not a valid numerical value'
			set @ResultFlag = 1
			Return 1

		End

		if not exists (select 1 from tb_Agreement where AgreementID = convert(int, @VariableValue) )
		Begin

			set @ErrorDescription = 'ERROR !!! No Agreement exists in the system for the passed AgreementID'
			set @ResultFlag = 1
			Return 1

		End

		--------------------------------------------------------------------
		-- Insert record into the database for the Agreement and Session ID
		--------------------------------------------------------------------

		------------------------------------------------------
		-- Marks the beginning of using the UI for creating new
		-- Service level assignments
		-------------------------------------------------------

		Delete from wtb_Wizard_MassSetup
		where SessionID = @SessionID

		insert into wtb_Wizard_MassSetup
		(SessionID , WizardName , WizardStep , UserID , VariableName , VariableDataType , IsMultiRecord , VariableValue)
		values
		( @SessionID , 'Service Level Assignment' , '1' , @UserID , @VariableName , 'int' , 0 , @VariableValue)

End

Else -- In all other steps before inserting record we need to check for the Agreement record
Begin
		--------------------------------------------------------------
		-- There should be a record existing in the Wizard table for
		-- Session and Agreement
		--------------------------------------------------------------

		if not exists (
							select 1 
							from wtb_Wizard_MassSetup 
							where VariableName = 'AgreementID' 
							and WizardStep = 1 
							and IsMultiRecord = 0 
					   )
		Begin

				set @ErrorDescription = 'ERROR !!! Data integrity not correct. There is no record in wizard schema for session and agreement'
				set @ResultFlag = 1
				Return 1

		End

		Else -- Get the agreement and account IDs for use in further processing
		Begin

				select @AgreementID = convert(int ,VariableValue )
				from wtb_Wizard_MassSetup 
				where VariableName = 'AgreementID' 
				and WizardStep = 1 
				and IsMultiRecord = 0 
		        
				select @AccountId = AccountID
				from tb_Agreement
				where AgreementID = @AgreementID

		End

End


if ( @VariableName = 'SelectDate' )
Begin

		----------------------------------------------------------
		-- Check to ensure that value passed is indeed a valid date
		----------------------------------------------------------

		if ( isDate(@VariableValue) = 0 ) 
		Begin

			set @ErrorDescription = 'ERROR !!! Begin Date passed is not a valid date'
			set @ResultFlag = 1
			Return 1

		End

	    --------------------------------------------------------------------
		-- Insert record into the database for the Date and Session ID
		--------------------------------------------------------------------

		Delete from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and VariableName = 'SelectDate'
		and IsMultiRecord = 0
		and WizardStep = 2

		insert into wtb_Wizard_MassSetup
		(SessionID , WizardName , WizardStep , UserID , VariableName , VariableDataType , IsMultiRecord , VariableValue)
		values
		( @SessionID , 'Service Level Assignment' , '2' , @UserID , @VariableName , 'Date' , 0 , @VariableValue)

End


if ( @VariableName = 'ServiceLevelID' )
Begin

		---------------------------------------------------------------------
		-- Check to ensure that value passed is indeed a valid Service Level
		---------------------------------------------------------------------

		if not exists ( select 1 from tb_ServiceLevel where ServiceLevelID = convert(int , @VariableValue) ) 
		Begin

			set @ErrorDescription = 'ERROR !!! Service Level passed is not a valid value'
			set @ResultFlag = 1
			Return 1

		End

	    ------------------------------------------------------------------------
		-- Insert record into the database for the Service Level and Session ID
		------------------------------------------------------------------------

		Delete from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and VariableName = 'ServiceLevelID'
		and IsMultiRecord = 0
		and WizardStep = 3

		insert into wtb_Wizard_MassSetup
		(SessionID , WizardName , WizardStep , UserID , VariableName , VariableDataType , IsMultiRecord , VariableValue)
		values
		( @SessionID , 'Service Level Assignment' , '3' , @UserID , @VariableName , 'ServiceLevelID' , 0 , @VariableValue)

End


if ( @VariableName = 'TrunkID' )
Begin

        ----------------------------------------------------------------
		-- Since this is a multi record step, we need to parse the comma
		-- separated values to get TRUNK IDs
		----------------------------------------------------------------

		Declare @TrunkIDList table (TrunkID varchar(100) )

		insert into @TrunkIDList
		select * from FN_ParseValueList( @VariableValue )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from @TrunkIDList where ISNUMERIC(TrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Trunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End
		
        -------------------------------------------------------------------
		-- Check to ensure that all the trunk IDs passed are valid values
		-------------------------------------------------------------------

		if exists ( 
						select 1 
						from @TrunkIDList 
						where TrunkID not in
						(
							Select TrunkID
							from tb_Trunk
							where trunktypeid = 9
							and flag & 1 <> 1
							and AccountID = @AccountID
						)
				  )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Trunk IDs passed contain value(s) which are not associated with the account'
			set @ResultFlag = 1
			Return 1

		End


	    ------------------------------------------------------------------------
		-- Insert record into the database for the TrunkID and Session ID
		------------------------------------------------------------------------

		Delete from wtb_Wizard_MassSetup
		where SessionID = @SessionID
		and VariableName = 'TrunkID'
		and IsMultiRecord = 1
		and WizardStep = 4

		insert into wtb_Wizard_MassSetup
		(SessionID , WizardName , WizardStep , UserID , VariableName , VariableDataType , IsMultiRecord , VariableValue)
		select  @SessionID , 'Service Level Assignment' , '4' , @UserID , @VariableName , 'TrunkID' , 1 , TrunkID
		from @TrunkIDList


End


if ( @VariableName = 'DestinationID' )
Begin

        ----------------------------------------------------------------
		-- Since this is a multi record step, we need to parse the comma
		-- separated values to get Destination IDs
		----------------------------------------------------------------

		Declare @DestinationIDList table (DestinationID varchar(100) )

		insert into @DestinationIDList
		select * from FN_ParseValueList( @VariableValue )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from @DestinationIDList where ISNUMERIC(DestinationID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End
		
        -------------------------------------------------------------------
		-- Check to ensure that all the Destination IDs passed are valid 
		-- values
		-------------------------------------------------------------------

		if exists ( select 1 from @DestinationIDList where destinationID = 0 ) -- All Destinations
		Begin

					------------------------------------------------------------------------
					-- Insert record into the database for the DestinationID and Session ID
					------------------------------------------------------------------------

					Delete from wtb_Wizard_MassSetup
					where SessionID = @SessionID
					and VariableName = 'DestinationID'
					and IsMultiRecord = 1
					and WizardStep = 5

					insert into wtb_Wizard_MassSetup
					(SessionID , WizardName , WizardStep , UserID , VariableName , VariableDataType , IsMultiRecord , VariableValue)
					values
					(@SessionID , 'Service Level Assignment' , '5' , @UserID , @VariableName , 'DestinationID' , 1 , 0 )					


		End

		Else -- Selected List of Destinations
		Begin

					if exists ( 
									select 1 
									from @DestinationIDList 
									where DestinationID not in
									(
										Select DestinationID
										from tb_Destination
										where numberplanid = -1  -- Outbound routing plan
										and flag & 1 <> 1
									)
							  )
					Begin

						set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain value(s) which are not part of the reference numbering plan'
						set @ResultFlag = 1
						Return 1

					End

					------------------------------------------------------------------------
					-- Insert record into the database for the DestinationID and Session ID
					------------------------------------------------------------------------

					Delete from wtb_Wizard_MassSetup
					where SessionID = @SessionID
					and VariableName = 'DestinationID'
					and IsMultiRecord = 1
					and WizardStep = 5

					insert into wtb_Wizard_MassSetup
					(SessionID , WizardName , WizardStep , UserID , VariableName , VariableDataType , IsMultiRecord , VariableValue)
					select  @SessionID , 'Service Level Assignment' , '5' , @UserID , @VariableName , 'DestinationID' , 1 , DestinationID
					from @DestinationIDList

		End


End


return 0
GO
