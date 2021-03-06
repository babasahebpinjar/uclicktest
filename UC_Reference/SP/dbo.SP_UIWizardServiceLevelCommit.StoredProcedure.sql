USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardServiceLevelCommit]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardServiceLevelCommit]
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

if not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Service Level Assignment' and WizardStep = 6)
Begin

		set @ErrorDescription = 'ERROR !!! Wizard schema does not have information for the passed session id : ' + @SessionID
		set @ResultFlag = 1
		Return 1

End


-------------------------------------------------------------------
-- Select the essential Result Set and insert records into the 
-- database
--------------------------------------------------------------------

--------------------------------------------------
-- Create temporary table to store the result set
--------------------------------------------------

Create table #TempAgreementSLResultSet
(
	AgreementID int,
	TrunkID int,
	DirectionID int,
	DestinationID int,
	ServiceLevelID int,
	BeginDate date,
	EndDate date,
	ErrorDescription varchar(2000)
)

Declare @ErrorDescription2 varchar(2000),
        @ResultFlag2 int,
		@VarAgreementID varchar(256), 
		@VarSelectDate varchar(256), 
		@VarServiceLevelID varchar(256), 
		@VarTrunkID varchar(256), 
		@VarDestinationID varchar(256)

Declare @AgreementID int, 
		@SelectDate Date, 
		@ServiceLevelID int, 
		@TrunkID int, 
		@DestinationID int,
		@AgreementEndDate date


Declare Ins_SLA_Rec_Cursor cursor for
select VariableValue ,Attribute1 , Attribute2 , Attribute3 , Attribute4
from wtb_Wizard_MassSetup
where SessionID =  @SessionID
and WizardName = 'Service Level Assignment'
and WizardStep = 6

Open Ins_SLA_Rec_Cursor
Fetch Next from Ins_SLA_Rec_Cursor
Into @VarAgreementID , @VarSelectDate , @VarServiceLevelID , @VarTrunkID , @VarDestinationID

While @@FETCH_STATUS = 0
Begin

		Begin Try

		        set @ErrorDescription2 = NULL 
				set @ResultFlag2 = 0
				--------------------------------------------------------
				-- Call the procedure to insert the SLA record into the 
				-- DB
				---------------------------------------------------------

				set @AgreementID = convert(int ,@VarAgreementID)
				set @SelectDate = convert(date , @VarSelectDate)
				set @ServiceLevelID  = convert(int ,@VarServiceLevelID)
				set @TrunkID = convert(int ,@VarTrunkID)
		        set @DestinationID = convert(int ,@VarDestinationID)
				set @DestinationID = nullif(@DestinationID , 0) -- Change the DestinationID to NULL in case of 0 ( All Destinations )

				select @AgreementEndDate =  EndDate
				from tb_Agreement
				where AgreementID = @AgreementID

				Exec SP_UIAgreementServiceLevelInsert @AgreementID ,@TrunkID , 1 , 
				                                      @DestinationID, @ServiceLevelID,
													  @SelectDate , @AgreementEndDate, @UserID,
													  @ErrorDescription2 Output,
													  @ResultFlag2 output

                 
                insert into #TempAgreementSLResultSet
				(
					AgreementID ,
					TrunkID ,
					DirectionID ,
					DestinationID ,
					ServiceLevelID ,
					BeginDate ,
					EndDate,
					ErrorDescription 
				)
				Values
				(
					@AgreementID,
					@TrunkID , 
					1 , 
				    @DestinationID , 
					@ServiceLevelID,
					@SelectDate , 
					@AgreementEndDate,
					@ErrorDescription2
				)

		End Try

		Begin Catch

				set @ErrorDescription = 'ERROR !!! While bulk wizard insertion of SLA records.' + ERROR_MESSAGE()
				set @ResultFlag = 1

				---------------------------------
				-- Remove the cursor declaration
				---------------------------------

				Close Ins_SLA_Rec_Cursor
				DeAllocate Ins_SLA_Rec_Cursor

				-----------------------------------------------
				-- Delete All the previously committed records 
				-- database
				-----------------------------------------------

				Delete tbl1
				from tb_AgreementSL tbl1
				inner join #TempAgreementSLResultSet tbl2 on
					tbl1.AgreementID = tbl2.AgreementID
					and tbl1.ServiceLevelID = tbl2.ServiceLevelID
					and tbl1.BeginDate = tbl2.EffectiveDate
					and tbl1.TrunkID = tbl2.TrunkID
					and isnull(tbl1.DestinationID , 0) = isnull(tbl2.DestinationID , 0)
				where tbl2.ErrorDescription is NULL

				------------------------------
				-- Drop the temporary table
				------------------------------
				
				Drop table #TempAgreementSLResultSet

				Return 1



		End Catch

		Fetch Next from Ins_SLA_Rec_Cursor
		Into @VarAgreementID , @VarSelectDate , @VarServiceLevelID , @VarTrunkID , @VarDestinationID

End

Close Ins_SLA_Rec_Cursor
DeAllocate Ins_SLA_Rec_Cursor

-----------------------------------------------------------
-- Return the complete result set with status of each of
-- the SLA record
-----------------------------------------------------------

Select tbl1.AgreementID, 
	   tbl1.trunkID , tbl2.Trunk,
       tbl1.DirectionID , tbl3.Direction,
	   tbl1.BeginDate ,
	   tbl1.EndDate,
	   tbl1.DestinationID , Case When tbl1.DestinationID is NULL then 'All Destinations' Else tbl5.Destination End as Destination,
	   tbl1.ServiceLevelID , tbl4.ServiceLevel	,
	   tbl1.ErrorDescription	  
from #TempAgreementSLResultSet tbl1
inner join tb_trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID
inner join tb_Direction tbl3 on tbl1.directionId = tbl3.DirectionID
inner join tb_servicelevel tbl4 on tbl1.ServicelevelID = tbl4.ServiceLevelID
left join tb_Destination tbl5 on tbl1.DestinationID = tbl5.DestinationID

------------------------------
-- Drop the temporary table
------------------------------
				
Drop table #TempAgreementSLResultSet

Return 0
GO
