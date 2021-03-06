USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCDRProcessingRules]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedCDRProcessingRules]
(
	@DirectionID int,
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL 

Declare @VarTrunk varchar(60),
        @VarCallDate datetime,
		@TrunkID int

		
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRProcessingRule') )
		Drop table #temp_CDRProcessingRule

Select RuleOrder,
PrefixCode,
TrunkID,
ServiceLevelID,
DirectionID,
BeginDate,
EndDate
into #temp_CDRProcessingRule
from UC_Reference.dbo.tb_CDRProcessingRule
where 1 = 2


Declare @MaxRuleOrder int = 0,
        @CurrentRuleOrder int = 0,
		@Prefix varchar(100),
		@ServiceLevelID int

----------------------------------------------------------------
-- Open a cursor on the CDR Records table to extract all the 
-- distinct trunks in the inbound direction and apply the
-- CDR processing rules for Service Level and Prefix
----------------------------------------------------------------

DECLARE db_CDR_Processing_Trunk CURSOR FOR  
select Distinct 
	   Case
			When @DirectionID = 1 then INTrunk
			When @DirectionID = 2 then OUTTrunk
	   End,       
      CallDate
from #temp_MedCDRPrexingOutput


OPEN db_CDR_Processing_Trunk  
FETCH NEXT FROM db_CDR_Processing_Trunk
INTO @VarTrunk , @VarCallDate

WHILE @@FETCH_STATUS = 0   
BEGIN  
  
       --select  @VarTrunk as TRUNK , @VarCallDate as CallDate

       Begin Try

	        ---------------------------------------------------------
			-- Get the Trunk ID associated with the Trunk for the
			-- Trunk Name, based on the CALL DATE
			---------------------------------------------------------

			Select @TrunkID = trnk.TrunkID
			from	UC_Reference.dbo.tb_Trunk trnk
			inner	join
				(
					select	TrunkID,max(EffectiveDate) EffectiveDate
					from	UC_Reference.dbo.tb_TrunkDetail
					where	EffectiveDate <= convert(datetime ,@VarCallDate) 
					group	by TrunkID
				)	x
			on	trnk.TrunkID = x.TrunkID
			inner	join	UC_Reference.dbo.tb_TrunkDetail trnkdet on	x.EffectiveDate = trnkdet.EffectiveDate
			where	trnkdet.ActiveStatusID = 1
			and	trnk.Flag & 1 = 0
			and	trnkdet.Flag & 1 = 0
			and	trnk.TrunkTypeID <> 9
			and trnk.CDRMatch = @VarTrunk

			--select @TrunkID  as TrunkID

			-----------------------------------------------------------
			-- Get the CDR processing rules on the INBOUND side for the
			-- Trunk
			-----------------------------------------------------------

			Delete from #temp_CDRProcessingRule

			insert into #temp_CDRProcessingRule
			Select RuleOrder,
					PrefixCode,
					TrunkID,
					ServiceLevelID,
					DirectionID,
					BeginDate,
					EndDate
			from UC_Reference.dbo.tb_CDRProcessingRule
			where TrunkID = @TrunkID
			and DirectionID = @DirectionID
			and @VarCallDate between BeginDate and isnull(EndDate , @VarCallDate)

			--select 'CDR Processing Rules' , *
			--from #temp_CDRProcessingRule

			-------------------------------------------------------------------------------
			-- Loop through the CDR Processing Rules , based on the Rule Order configured
			-------------------------------------------------------------------------------

			select @CurrentRuleOrder = isnull(MIN(RuleOrder), 0),
			       @MaxRuleOrder = isnull(MAX(RuleOrder), 0)
			from #temp_CDRProcessingRule
			
			While ( (@CurrentRuleOrder <= @MaxRuleOrder ) and ( @CurrentRuleOrder <> 0 ))
			Begin

			        --select @CurrentRuleOrder as CurrentRuleOrder 

			        select @Prefix = PrefixCode,
					       @ServiceLevelID = ServiceLevelID
                    from #temp_CDRProcessingRule
					where RuleOrder = @CurrentRuleOrder 

					if (@DirectionID = 1 )
					Begin

								update #temp_MedCDRPrexingOutput
								set
									EnrichedINCalledNumber = 
										Case
											When @Prefix is NULL then INCalledNumber
											Else 
											   Case
													When Substring(INCalledNumber , 1 , Len(@Prefix)) = @Prefix then Substring(INCalledNumber , Len(@Prefix) +1 , Len(INCalledNumber))
													Else EnrichedINCalledNumber
											   End
										End,
									InServiceLevelID =
										Case
											When @Prefix is NULL then @ServiceLevelID
											Else 
											   Case
													When Substring(INCalledNumber , 1 , Len(@Prefix)) = @Prefix then @ServiceLevelID
													Else INServiceLevelID
											   End
										End						 
								 Where INTrunk = @VarTrunk
									 And
									  CallDate = @VarCallDate


					End

					if (@DirectionID = 2 )
					Begin

								update #temp_MedCDRPrexingOutput
								set
									EnrichedOUTCalledNumber = 
										Case
											When @Prefix is NULL then OUTCalledNumber
											Else 
											   Case
													When Substring(OUTCalledNumber , 1 , Len(@Prefix)) = @Prefix then Substring(OUTCalledNumber , Len(@Prefix) +1 , Len(OUTCalledNumber))
													Else EnrichedOUTCalledNumber
											   End
										End,
									OutServiceLevelID =
										Case
											When @Prefix is NULL then @ServiceLevelID
											Else 
											   Case
													When Substring(OUTCalledNumber , 1 , Len(@Prefix)) = @Prefix then @ServiceLevelID
													Else OutServiceLevelID
											   End
										End						 
								 Where OUTTrunk = @VarTrunk
									 And
									  CallDate = @VarCallDate

					End								
                  
					select @CurrentRuleOrder = isnull(MIN(RuleOrder), 0)
					from #temp_CDRProcessingRule
					where RuleOrder > @CurrentRuleOrder				

			End

	   End Try

	   Begin Catch

			set @ErrorDescription = 'ERROR !!!! During application of CDR Processing Rules on' +
			                        Case
										When @DirectionID = 1 then 'Inbound'
										When @DirectionID = 2 then 'Outbound'
									End +
			                        ' Direction.' + ERROR_MESSAGE()

		    set @ErrorDescription = 'SP_BSMedCDRProcessingRules : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
			
			set @ResultFlag = 1 

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			CLOSE db_CDR_Processing_Trunk 
			DEALLOCATE db_CDR_Processing_Trunk

			GOTO ENDPROCESS


	   End Catch

	   FETCH NEXT FROM db_CDR_Processing_Trunk
	   INTO @VarTrunk , @VarCallDate
 
END   

CLOSE db_CDR_Processing_Trunk 
DEALLOCATE db_CDR_Processing_Trunk


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRProcessingRule') )
		Drop table #temp_CDRProcessingRule
GO
