USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingScenarioCommit]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingScenarioCommit]
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

if not exists ( select 1 from wtb_Wizard_MassSetup where SessionID = @SessionID and WizardName = 'Rating Scenario' and WizardStep = 1)
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

Create table #TempAgreementRatingScenarioResultSet
(
	AgreementID int,
	CommercialTrunkID int,
	CallTypeID int,
	CountryID int,
	DirectionID int,
	ServiceLevelID int,
	BeginDate Date,
	EndDate Date,
	TariffTypeID int,
	RatePlanID int,
	Percentage int,
	ErrorDescription varchar(2000)
)

Declare @ErrorDescription2 varchar(2000),
        @ResultFlag2 int,
		@VarAgreementID varchar(256),
		@VarCommercialTrunkID varchar(256),
		@VarCallTypeID varchar(256),
		@VarCountryID varchar(256),
		@VarDirectionID varchar(256),
		@VarBeginDate varchar(256),
		@VarEndDate varchar(256),
		@VarTariffTypeID varchar(256),
		@VarRatePlanID varchar(256),
		@VarPercentage varchar(256),
		@VarServiceLevelID varchar(256)


Declare @AgreementID int,
		@CommercialTrunkID int,
		@CallTypeID int,
		@CountryID int,
		@DirectionID int,
		@BeginDate Date,
		@EndDate Date,
		@TariffTypeID int,
		@RatePlanID int,
		@Percentage int,
		@ServiceLevelID int


Declare Ins_RatingScenario_Rec_Cursor cursor for
select VariableValue ,Attribute1 , Attribute2 , Attribute3 , Attribute4 , Attribute5 , Attribute6 , 
       Attribute7 , Attribute8 , Attribute9, Attribute10
from wtb_Wizard_MassSetup
where SessionID =  @SessionID
and WizardName = 'Rating Scenario'
and WizardStep = 1

Open Ins_RatingScenario_Rec_Cursor
Fetch Next from Ins_RatingScenario_Rec_Cursor
Into @VarAgreementID, @VarCommercialTrunkID , @VarCallTypeID, @VarCountryID,
	 @VarDirectionID , @VarServiceLevelID ,@VarBeginDate, @VarEndDate, @VarTariffTypeID,
	 @VarRatePlanID ,  @VarPercentage 

While @@FETCH_STATUS = 0
Begin

		Begin Try

		        set @ErrorDescription2 = NULL 
				set @ResultFlag2 = 0
				--------------------------------------------------------
				-- Call the procedure to insert the Rating Scenario record 
				-- into the DB
				---------------------------------------------------------

				set @AgreementID = convert(int ,@VarAgreementID)
				set @CommercialTrunkID = convert(int ,@VarCommercialTrunkID)
				set @CallTypeID = convert(int ,@VarCallTypeID)
				set @CountryID = convert(int ,@VarCountryID)
				set @DirectionID = convert(int ,@VarDirectionID)
				set @BeginDate = convert(date ,@VarBeginDate)
				set @EndDate = 
				       Case 
							When @VarEndDate is Not NULL then convert(date ,@VarEndDate)
							Else NULL
					   End
				set @TariffTypeID = convert(int ,@VarTariffTypeID)
				set @RatePlanID = convert(int ,@VarRatePlanID)
				set @Percentage = convert(int ,@VarPercentage)
				set @ServiceLevelID = convert(int , @VarServiceLevelID)

				Exec SP_UIRatingScenarioHubbingInsert @AgreementID ,@CommercialTrunkID , @CallTypeID , 
				                                      @CountryID, @DirectionID, @ServiceLevelID,
													  @BeginDate , @EndDate, NULL , NULL ,
													  @TariffTypeID , @RatePlanID , @Percentage,
													  @UserID,
													  @ErrorDescription2 Output,
													  @ResultFlag2 output

                 
                insert into #TempAgreementRatingScenarioResultSet
				(
					AgreementID ,
					CommercialTrunkID ,
					CallTypeID ,
					CountryID ,
					DirectionID ,
					ServiceLevelID,
					BeginDate ,
					EndDate ,
					TariffTypeID ,
					RatePlanID ,
					Percentage ,
					ErrorDescription
				)
				Values
				(
					@AgreementID ,
					@CommercialTrunkID ,
					@CallTypeID ,
					@CountryID ,
					@DirectionID ,
					@ServiceLevelID,
					@BeginDate ,
					@EndDate ,
					@TariffTypeID ,
					@RatePlanID ,
					@Percentage ,
					@ErrorDescription2
				)

		End Try

		Begin Catch

				set @ErrorDescription = 'ERROR !!! While bulk wizard insertion of Rating Scenario records.' + ERROR_MESSAGE()
				set @ResultFlag = 1

				---------------------------------
				-- Remove the cursor declaration
				---------------------------------

				Close Ins_RatingScenario_Rec_Cursor
				DeAllocate Ins_RatingScenario_Rec_Cursor

				-----------------------------------------------
				-- Delete All the previously committed records 
				-- from database
				-----------------------------------------------

				Delete tbl1
				from tb_RatingSettlement tbl1
				inner join tb_RatingScenario tbl2 on tbl1.RatingScenarioID = tbl2.RatingScenarioID
				inner join #TempAgreementRatingScenarioResultSet tbl3 on
				           tbl2.Attribute1ID = tbl3.AgreementID
						   and
						   tbl2.Attribute2ID = tbl3.CommercialTrunkID
						   and
						   tbl2.Attribute3ID = tbl3.CallTypeID
						   and
						   tbl2.Attribute4ID = tbl3.CountryID
						   and 
						   tbl2.Attribute5ID = tbl3.DirectionID
                where tbl2.RatingScenarioTypeID = -3

				Delete tbl2
				from tb_RatingScenario tbl2
				inner join #TempAgreementRatingScenarioResultSet tbl3 on
				           tbl2.Attribute1ID = tbl3.AgreementID
						   and
						   tbl2.Attribute2ID = tbl3.CommercialTrunkID
						   and
						   tbl2.Attribute3ID = tbl3.CallTypeID
						   and
						   tbl2.Attribute4ID = tbl3.CountryID
						   and 
						   tbl2.Attribute5ID = tbl3.DirectionID
				 where tbl2.RatingScenarioTypeID = -3
				
					   
				------------------------------
				-- Drop the temporary table
				------------------------------
				
				Drop table #TempAgreementRatingScenarioResultSet

				Return 1



		End Catch

		Fetch Next from Ins_RatingScenario_Rec_Cursor
		Into @VarAgreementID, @VarCommercialTrunkID , @VarCallTypeID, @VarCountryID,
			 @VarDirectionID , @VarServiceLevelID , @VarBeginDate, @VarEndDate, @VarTariffTypeID,
			 @VarRatePlanID ,  @VarPercentage 

End

Close Ins_RatingScenario_Rec_Cursor
DeAllocate Ins_RatingScenario_Rec_Cursor

-----------------------------------------------------------
-- Return the complete result set with status of each of
-- the Rating Scenario record
-----------------------------------------------------------

 Select tbl1.AgreementID, 
	   tbl1.CommercialtrunkID , tbl2.Trunk as CommercialTrunk,
	   100 as Percentage,
	   tbl3.CallTypeID , tbl3.CallType,
	   tbl4.CountryID , tbl4.Country,
       tbl5.DirectionID , tbl5.Direction,
	   tbl8.ServiceLevelID ,
	   Case
			when tbl8.ServiceLevelID is NULL then 'All Service Level'
			Else tbl8.ServiceLevel
	   End as ServiceLevel,
	   tbl1.BeginDate ,  tbl1.EndDate,
	   tbl6.TariffTypeID , tbl6.TariffType,
	   tbl1.RatePlanID , tbl7.RatePlan	,
	   tbl1.ErrorDescription	  
from #TempAgreementRatingScenarioResultSet tbl1
inner join tb_trunk tbl2 on tbl1.CommercialTrunkID = tbl2.TrunkID
inner join tb_CallType tbl3 on tbl1.CallTypeID = tbl3.CallTypeID
inner join tb_Country tbl4 on tbl1.CountryID = tbl4.CountryID
inner join tb_Direction tbl5 on tbl1.DirectionID = tbl5.DirectionID
inner join tb_TariffType tbl6 on tbl1.tariffTypeID = tbl6.TariffTypeID
inner join tb_RatePlan tbl7 on tbl1.RatePlanID = tbl7.RatePlanID
left join tb_ServiceLevel tbl8 on tbl1.ServiceLevelID = tbl8.ServiceLevelID
order by tbl5.Direction , tbl4.Country , tbl2.Trunk

------------------------------
-- Drop the temporary table
------------------------------
				
Drop table #TempAgreementRatingScenarioResultSet

Return 0
GO
