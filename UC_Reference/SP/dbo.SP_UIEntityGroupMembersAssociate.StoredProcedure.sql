USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupMembersAssociate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIEntityGroupMembersAssociate]
(
	@SessionID varchar(60),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


set @ErrorDescription = NULL 
set @ResultFlag = 0

Declare @EntityGroupTypeID int,
        @ErrorDescription2 varchar(2000),
		@ResultFlag2 int,
		@EntityGroupID int

------------------------------------------------------------
-- Check that the session and Entity Group are valid values
------------------------------------------------------------

if ( @SessionID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Session ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

-----------------------------------------------------------------------
-- Make sure that a single wizard session is associated with a single
-- Entity Group Type
-----------------------------------------------------------------------

if (
		(
			select count(distinct  isnull(convert(int ,VariableValue),0)) 
			from wtb_Wizard_MassSetup 
			where sessionID = @SessionID 
			and WizardName = 'Group Assignment'
		)  > 1
   )
Begin

	set @ErrorDescription = 'ERROR !!! Session ID associated with multiple Entity Group Types'
	set @ResultFlag = 1
	Return 1


End

-------------------------------------------------------------
-- Get the Entity Group Type ID value from the wizard table
-------------------------------------------------------------

select @EntityGroupTypeID = EntityGroupTypeID
from
(
	select top 1 convert(int ,VariableValue) as EntityGroupTypeID
	from wtb_Wizard_MassSetup 
	where sessionID = @SessionID 
	and WizardName = 'Group Assignment'
) as tbl1

----------------------------------------------------------
-- Check to ensure that the entity group type is a valid
-- value
----------------------------------------------------------

if ( ( @EntityGroupTypeID is NULL ) or (@EntityGroupTypeID not in (-2 , -3 , -4)) )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group Type ID is NULL or not a valid value'
	set @ResultFlag = 1
	Return 1

End

-----------------------------------------------------------------------
-- Make sure that a single wizard session is associated with a single
-- Entity Group Type and Entity Group
-----------------------------------------------------------------------

if (
		(
			select count(distinct  isnull(convert(int ,Attribute1),0)) 
			from wtb_Wizard_MassSetup 
			where sessionID = @SessionID 
			and WizardName = 'Group Assignment'
			and convert(int ,VariableValue) = @EntityGroupTypeID
		)  > 1
   )
Begin

	set @ErrorDescription = 'ERROR !!! Invalid association. Multiple entity groups are being handled via single session'
	set @ResultFlag = 1
	Return 1


End


select @EntityGroupID = EntityGroupID
from
(
	select top 1 convert(int ,Attribute1) as EntityGroupID
	from wtb_Wizard_MassSetup 
	where sessionID = @SessionID 
	and WizardName = 'Group Assignment'
	and convert(int ,VariableValue) = @EntityGroupTypeID
) as tbl1

------------------------------------------------------------
-- Ensure that the Entity Group type of the Entity Group is
-- similiar to what has been entered in the wizard table.
-- Caution to ensure that data integrity is maintained
------------------------------------------------------------

if exists ( 
				select 1
				from wtb_Wizard_MassSetup tbl1
				inner join tb_EntityGroup tbl2 on convert(int ,tbl1.Attribute1) = tbl2.EntityGroupID
				where sessionID = @SessionID 
				and WizardName = 'Group Assignment'
				and convert(int ,VariableValue) = @EntityGroupTypeID
				and tbl2.EntityGroupTypeID <> @EntityGroupTypeID
		 )
Begin

	set @ErrorDescription = 'ERROR !!! Entity Group type in wizard table does not match that of entity group in schema'
	set @ResultFlag = 1
	Return 1

End


---------------------------------------------------
-- If a NULL entry exists, then it is an indication
-- to disassociate all the members
---------------------------------------------------

if exists ( 
				select 1 
				from wtb_Wizard_MassSetup 
				where sessionID = @SessionID 
				and convert(int ,VariableValue) = @EntityGroupTypeID
				and WizardName = 'Group Assignment'
				and Attribute2 is NULL
			)
Begin

        set @ErrorDescription2 = NULL
		set @ResultFlag2 = 0

		Exec SP_UIEntityGroupMembersDelete @EntityGroupID , @UserID , @ErrorDescription2 output , @ResultFlag2 Output

		if (@ResultFlag2 = 1)
		Begin

			set @ErrorDescription = @ErrorDescription2
			set @ResultFlag = 1
			Return 1

		End

		Return 0

End

--------------------------------------------------------------
-- Ensure that the member IDs provided should actually be
-- of same type as the group.
-- Example: Country Group should have only Countries as members
---------------------------------------------------------------

if ( @EntityGroupTypeID = -2 ) -- Destination
Begin

		if exists (
						select 1 
						from wtb_Wizard_MassSetup 
						where sessionID = @SessionID 
						and convert(int ,VariableValue) = @EntityGroupTypeID
						and WizardName = 'Group Assignment'
						and convert(int , Attribute2) not in
						(
							select distinct destinationID
							from tb_destination dest
							inner join tb_numberplan np on dest.numberplanid = np.numberplanid
							where np.NumberPlanTypeID = 1
						)
					)
		Begin
		
			set @ErrorDescription = 'ERROR !!! Destinations to be associated with the Group do not exist in the Destination master schema'
			set @ResultFlag = 1
			Return 1

		End


End


if ( @EntityGroupTypeID = -3 ) -- Account
Begin

		if exists (
						select 1 
						from wtb_Wizard_MassSetup 
						where sessionID = @SessionID 
						and convert(int ,VariableValue) = @EntityGroupTypeID
						and WizardName = 'Group Assignment'
						and convert(int , Attribute2) not in
						(
							select distinct AccountID
							from tb_Account 						
						)
					)
		Begin
		
			set @ErrorDescription = 'ERROR !!! Account(s) to be associated with the Group do not exist in the Account master schema'
			set @ResultFlag = 1
			Return 1

		End


End

if ( @EntityGroupTypeID = -4 ) -- Country
Begin

		if exists (
						select 1 
						from wtb_Wizard_MassSetup 
						where sessionID = @SessionID 
						and convert(int ,VariableValue) = @EntityGroupTypeID
						and WizardName = 'Group Assignment'
						and convert(int , Attribute2) not in
						(
							select distinct CountryID
							from tb_Country 						
						)
					)
		Begin
		
			set @ErrorDescription = 'ERROR !!! Countries to be associated with the Group do not exist in the Country master schema'
			set @ResultFlag = 1
			Return 1

		End

End

------------------------------------------------------------------------------
-- Add or remove the records from the entity group depending on the data in
-- the wizard table
------------------------------------------------------------------------------ 

Begin Transaction InsertRecEG

----------------------------------------------------------------------------
-- STEP 1 : Delete all members, which are not part of the current selection
----------------------------------------------------------------------------

if ( @EntityGroupTypeID in (-3 , -4) ) --Account or Country Group
Begin

	Delete from tb_EntityGroupMember
	where EntityGroupID = @EntityGroupID
	and InstanceID not in
	(
		select convert(int, Attribute2)
		from wtb_Wizard_MassSetup
		where sessionID = @SessionID 
		and convert(int ,VariableValue) = @EntityGroupTypeID
		and WizardName = 'Group Assignment'
		and convert(int , Attribute1) = @EntityGroupID
	)

End

if ( @EntityGroupTypeID = -2 ) -- Destination Group
Begin

		------------------------------------------------------------
		-- Get the distinct number of Number Plans whose destinations
		-- have been selected for Addition to the Group
		-------------------------------------------------------------

		Create Table #TempDistinctNumberPlan (NumberPlanID int )

		insert into #TempDistinctNumberPlan
		select distinct numberplanID
		from wtb_Wizard_MassSetup tbl1
		inner join tb_Destination tbl2 on convert(int, tbl1.Attribute2) = tbl2.DestinationID
		where sessionID = @SessionID 
		and convert(int ,VariableValue) = @EntityGroupTypeID
		and WizardName = 'Group Assignment'
		and convert(int , Attribute1) = @EntityGroupID

		------------------------------------------------------------------
		-- Delete only those members from the Entity Group, which are not
		-- part of current member list and have the same number plan
		------------------------------------------------------------------

		Delete tbl1
		from tb_EntityGroupMember tbl1
		inner join tb_Destination  tbl2 on tbl1.InstanceID = tbl2.DestinationID
		inner join #TempDistinctNumberPlan tbl3 on tbl2.NumberPlanID = tbl3.NumberPlanID
		where tbl1.EntityGroupID = @EntityGroupID
		and tbl1.InstanceID not in
		(
			select convert(int, Attribute2)
			from wtb_Wizard_MassSetup
			where sessionID = @SessionID 
			and convert(int ,VariableValue) = @EntityGroupTypeID
			and WizardName = 'Group Assignment'
			and convert(int , Attribute1) = @EntityGroupID
		)
		

		Drop table #TempDistinctNumberPlan

End

------------------------------------------------
-- STEP 2 : Add members to the entity group
------------------------------------------------

Declare @VarMemberID int

Declare Associate_Entity_Members_Cur Cursor For
Select convert(int, Attribute2) 
from wtb_Wizard_MassSetup
where sessionID = @SessionID 
and convert(int ,VariableValue) = @EntityGroupTypeID
and WizardName = 'Group Assignment'
and convert(int , Attribute1) = @EntityGroupID

Open Associate_Entity_Members_Cur
Fetch Next from Associate_Entity_Members_Cur
Into @VarMemberID

While @@FETCH_STATUS = 0
Begin

		Begin Try

				if not exists ( select 1 from tb_EntityGroupMember where EntityGroupID = @EntityGroupID and InstanceID = @VarMemberID )
				Begin

						insert into tb_EntityGroupMember
						( InstanceID , EntityGroupID , ModifiedDate , ModifiedByID , Flag )
						Values
						( @VarMemberID , @EntityGroupID , GetDate() , @UserID , 0 )

				End

		End Try

		Begin Catch

				set @ErrorDescription = 'ERROR !!! Could not associate members to the entity group.' + ERROR_MESSAGE()
				set @ResultFlag = 1

				Close Associate_Entity_Members_Cur
				DeAllocate Associate_Entity_Members_Cur

				Rollback Transaction InsertRecEG
				Return 1

		End Catch

		Fetch Next from Associate_Entity_Members_Cur
		Into @VarMemberID

End

Close Associate_Entity_Members_Cur
DeAllocate Associate_Entity_Members_Cur

Commit Transaction InsertRecEG












GO
