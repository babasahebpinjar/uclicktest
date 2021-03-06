USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCustomValidation]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCustomValidation]
(
    @CallingProcessID int, -- 0 means Processing 1 means Reprocessing Exceptions
    @AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

if ( @CallingProcessID = 0 )
Begin

		----------------------------------------------------------
		-- Update the Date time fields in the correct format for
		-- further processing
		----------------------------------------------------------

		update ##temp_MedFormatterRecords
		set 
		  ConnectTime = 
				Case
					When ConnectTime is NULL then ConnectTime
					Else substring(ConnectTime , 7,4) + '-'+
						 substring(ConnectTime , 4,2) + '-'+
						 substring(ConnectTime , 1,2) + ' '+
						 substring(ConnectTime , 12, 8)
				 End,
		  AlertTime = 
				Case
					When AlertTime is NULL then AlertTime
					Else substring(AlertTime , 7,4) + '-'+
						 substring(AlertTime , 4,2) + '-'+
						 substring(AlertTime , 1,2) + ' '+
						 substring(AlertTime , 12, 8)
				 End,
		  StartTime = 
				Case
					When StartTime is NULL then StartTime
					Else substring(StartTime , 7,4) + '-'+
						 substring(StartTime , 4,2) + '-'+
						 substring(StartTime , 1,2) + ' '+
						 substring(StartTime , 12, 8)
				 End,
		  EndTime = 
				Case
					When EndTime is NULL then EndTime
					Else substring(EndTime , 7,4) + '-'+
						 substring(EndTime , 4,2) + '-'+
						 substring(EndTime , 1,2) + ' '+
						 substring(EndTime , 12, 8)
				 End

End

--------------------------------------------------------------
-- Update the incoming and outgoing calle numbers to remove
-- any no related suffixes
--------------------------------------------------------------

update ##temp_MedFormatterRecords
set
	INCalledNumber1 = 
        Case
			When INCalledNumber1 is NULL then INCalledNumber1
			Else Replace(Replace(Replace(Replace(Replace(INCalledNumber1 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End,
	INCalledNumber2 = 
        Case
			When INCalledNumber2 is NULL then INCalledNumber2
			Else Replace(Replace(Replace(Replace(Replace(INCalledNumber2 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End,
	INCalledNumber3 = 
        Case
			When INCalledNumber3 is NULL then INCalledNumber3
			Else Replace(Replace(Replace(Replace(Replace(INCalledNumber3 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End,
	INCalledNumber4 = 
        Case
			When INCalledNumber4 is NULL then INCalledNumber4
			Else Replace(Replace(Replace(Replace(Replace(INCalledNumber4 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End,
	OUTCalledNumber1 = 
        Case
			When OUTCalledNumber1 is NULL then OUTCalledNumber1
			Else Replace(Replace(Replace(Replace(Replace(OUTCalledNumber1 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End,
	OUTCalledNumber2 = 
        Case
			When OUTCalledNumber2 is NULL then OUTCalledNumber2
			Else Replace(Replace(Replace(Replace(Replace(OUTCalledNumber2 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End,
	OUTCalledNumber3 = 
        Case
			When OUTCalledNumber3 is NULL then OUTCalledNumber3
			Else Replace(Replace(Replace(Replace(Replace(OUTCalledNumber3 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End,
	OUTCalledNumber4 = 
        Case
			When OUTCalledNumber4 is NULL then OUTCalledNumber4
			Else Replace(Replace(Replace(Replace(Replace(OUTCalledNumber4 , 'ii' , '') , 'si' , ''), '#' , ''), 'iu' , ''), 'uu' , '')
		 End

update ##temp_MedFormatterRecords
set
	INCalledNumber1 = Replace(Replace(Replace(INCalledNumber1 , '+' , '') , 'ui' , ''), 'ni', ''),   
	INCalledNumber2 = Replace(Replace(Replace(INCalledNumber2 , '+' , '') , 'ui' , ''), 'ni', ''), 	     
	INCalledNumber3 = Replace(Replace(Replace(INCalledNumber3 , '+' , '') , 'ui' , ''), 'ni', ''), 	
	INCalledNumber4 = Replace(Replace(Replace(INCalledNumber4 , '+' , '') , 'ui' , ''), 'ni', ''), 	
    OUTCalledNumber1 = Replace(Replace(Replace(OUTCalledNumber1 , '+' , '') , 'ui' , ''), 'ni', ''),
	OUTCalledNumber2 = Replace(Replace(Replace(OUTCalledNumber2 , '+' , '') , 'ui' , ''), 'ni', ''),
	OUTCalledNumber3 = Replace(Replace(Replace(OUTCalledNumber3 , '+' , '') , 'ui' , ''), 'ni', ''),
	OUTCalledNumber4 = Replace(Replace(Replace(OUTCalledNumber4 , '+' , '') , 'ui' , ''), 'ni', '')


--------------------------------------------------------------------
-- Update the Start Time with End Time for all the Records where the
-- Start Time is NULL and Charge Duration is NULL
---------------------------------------------------------------------

update ##temp_MedFormatterRecords
	set StartTime =
			Case 
				When StartTime is NULL then EndTime
				Else StartTime
			End,
		ChargeDuration =
			Case 
				When ChargeDuration is NULL then 0
				Else ChargeDuration
			End			


-------------------------------------------------------------------------------
-- Mark all records for DISCARD, which have the RELEASE CAUSE as CAU_SIP_MTMP 	
-------------------------------------------------------------------------------

Update ##temp_MedFormatterRecords
	set ErrorDescription = 'DISCARD RULE: Release Cause for CDR is CAU_SIP_MTMP',
	    ErrorType = -1
Where rtrim(ltrim(ReleaseCause)) = 'CAU_SIP_MTMP'


------------------------------------------------------------------------------
-- Use the START TIME field in the CDR record as the CALL DATE to traverse
-- through each record and perform validation on the INTRUNK and OUTTRUNK
-------------------------------------------------------------------------------

Declare @VarCallDate varchar(10)

DECLARE db_get_distinct_calldate CURSOR FOR
select distinct substring(StartTime , 1,10) 
from ##temp_MedFormatterRecords

OPEN db_get_distinct_calldate
FETCH NEXT FROM db_get_distinct_calldate
INTO @VarCallDate 


WHILE @@FETCH_STATUS = 0
BEGIN

     BEGIN TRY

			 --------------------------------------------------------------
			 -- Get all the technical trunks that were active during the
			 -- call date period.
			 --------------------------------------------------------------

			if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_TrunkInfo') )
				Drop table #temp_TrunkInfo

			 Select trnk.trunkid , trnk.cdrmatch , trnk.trunk , swt.switch , trnkdet.effectivedate,
					trnkdet.activestatusid , trnk.TransmissionTypeID , trnk.trunktypeid , trnkdet.directionid,
					trnk.AccountID
			 into #temp_TrunkInfo
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
			inner join UC_Reference.dbo.tb_switch swt on trnk.switchid = swt.switchid
			and	trnk.TrunkID = trnkdet.TrunkID
			where	trnkdet.ActiveStatusID = 1
			and	trnk.Flag & 1 = 0
			and	trnkdet.Flag & 1 = 0
			and	trnk.TrunkTypeID <> 9

			----------------------------------------------------------------
			-- Check if the incoming trunk CDR match exists in the 
			-- reference data or not.
			----------------------------------------------------------------

			update tbl1
			set tbl1.ErrorDescription = '"REJECT RULE: Incoming Route ' + INTrunk  + ' not present for call date ' + @VarCallDate + '"'  ,
			    tbl1.ErrorType = 1                    
			from ##temp_MedFormatterRecords tbl1
			where substring(StartTime , 1,10)   = @VarCallDate 
			and tbl1.INTrunk not in
			(
			   select distinct CDRMatch
			   from #temp_TrunkInfo
			)
			and tbl1.ErrorDescription is NULL

			----------------------------------------------------------------
			-- Check if the Outgoing trunk CDR match exists in the 
			-- reference data or not.
			----------------------------------------------------------------

			update tbl1
			set tbl1.ErrorDescription = '"REJECT RULE: Outgoing Route ' + OUTTrunk  + ' not present for call date ' + @VarCallDate + '"'  ,
			    tbl1.ErrorType = 2                    
			from ##temp_MedFormatterRecords tbl1
			where substring(StartTime , 1,10)   = @VarCallDate 
			and tbl1.OutTrunk not in
			(
			   select distinct CDRMatch
			   from #temp_TrunkInfo
			)
			and tbl1.ErrorDescription is NULL

			--------------------------------------------------------------------
			-- Check the direction of the incoming and outgoing trunks.
			-- Incoming Trunk : Inbound or bidirectional.
			-- Outgoing Trunk : Outbound or Bidirectional.
			--------------------------------------------------------------------

			update tbl1
			set tbl1.ErrorDescription = '"REJECT RULE: Outgoing Route ' + OUTTrunk  + ' for call date ' + @VarCallDate + ' is set as Inbound trunk'+'"' ,                    
			    tbl1.ErrorType = 3
			from ##temp_MedFormatterRecords tbl1
				inner join #temp_TrunkInfo tbl2 on tbl1.OUTTrunk = tbl2.cdrmatch
			where substring(StartTime , 1,10) = @VarCallDate  
			and tbl1.ErrorDescription is NULL
				and tbl2.directionid not in (2,3)

			update tbl1
			set tbl1.ErrorDescription = '"REJECT RULE: Incoming Route ' + INTrunk  + ' for call date ' + @VarCallDate + ' is set as Outbound trunk'+'"' ,                     
				tbl1.ErrorType = 4
			from ##temp_MedFormatterRecords tbl1
				inner join #temp_TrunkInfo tbl2 on tbl1.INTrunk = tbl2.cdrmatch
			where substring(StartTime , 1,10) = @VarCallDate
			and tbl1.ErrorDescription is NULL
				and tbl2.directionid not in (1,3)

			--------------------------------------------------------------------
			-- Check to ensure that the transmission type is defined for each
			-- trunk
			--------------------------------------------------------------------

			update tbl1
			set tbl1.ErrorDescription = '"REJECT RULE: Outgoing Route ' + OUTTrunk  + ' for call date ' + @VarCallDate + ' does not have transmission type defined'+'"' ,                    
			    tbl1.ErrorType = 5
			from ##temp_MedFormatterRecords tbl1
				inner join #temp_TrunkInfo tbl2 on tbl1.OUTTrunk = tbl2.cdrmatch
			where substring(StartTime , 1,10) = @VarCallDate  
			and tbl1.ErrorDescription is NULL
				and tbl2.TransmissionTypeID is NULL

			update tbl1
			set tbl1.ErrorDescription = '"REJECT RULE: Incoming Route ' + INTrunk  + ' for call date ' + @VarCallDate + ' does not have transmission type defined'+'"' ,                     
				tbl1.ErrorType = 6
			from ##temp_MedFormatterRecords tbl1
				inner join #temp_TrunkInfo tbl2 on tbl1.INTrunk = tbl2.cdrmatch
			where substring(StartTime , 1,10) = @VarCallDate
			and tbl1.ErrorDescription is NULL
				and tbl2.TransmissionTypeID is NULL


			---------------------------------------------------------------------
			-- Perform all the business specific validations and rejections
			---------------------------------------------------------------------

			set @ResultFlag = 0
			set @ErrorDescription = NULL

			if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CustomValidation') )
				Drop table #temp_CustomValidation

            select tbl1.* , 
			      tbl2.TransmissionTypeID as INTransmissionTypeID , 
				  tbl3.TransmissionTypeID as OUTTransmissionTypeID,
				  tbl2.AccountID as INAccountID,
				  tbl3.AccountID as OUTAccountID
            into #temp_CustomValidation
			from ##temp_MedFormatterRecords tbl1
			inner join #temp_TrunkInfo tbl2 on tbl1.INtrunk = tbl2.trunk
			inner join #temp_TrunkInfo tbl3 on tbl1.OUTtrunk = tbl3.trunk
			where substring(tbl1.StartTime , 1,10) = @VarCallDate
			and tbl1.ErrorDescription is NULL

			Exec SP_BSMedFormatterBusinessDiscardCustomValidations @AbsoluteLogFilePath,
															       @ErrorDescription Output,
															       @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

					set @ErrorDescription = 'ERROR !!! During business based discard validations.'
  
					set @ErrorDescription = 'SP_BSMedFormatterCustomValidation : '+ convert(varchar(30) ,getdate() , 120) +
											' : ' + @ErrorDescription
					Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

					set @ResultFlag = 1					

					CLOSE db_get_distinct_calldate   
					DEALLOCATE db_get_distinct_calldate

					GOTO ENDPROCESS

			End

			------------------------------------------------------------
			-- Update the processed records status in the main CDR
			-- records table
			------------------------------------------------------------

			update tbl1
				set ErrorType = tbl2.ErrorType,
				    ErrorDescription = tbl2.ErrorDescription
			from ##temp_MedFormatterRecords tbl1
			inner join #temp_CustomValidation tbl2 on tbl1.RecordID = tbl2.RecordID
			

	END TRY

	BEGIN CATCH

			set @ErrorDescription = 'ERROR !!! During custom validation and enrichment of CDR records.' + ERROR_MESSAGE()
  
			set @ErrorDescription = 'SP_BSMedFormatterCustomValidation : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + @ErrorDescription
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			set @ResultFlag = 1

			CLOSE db_get_distinct_calldate   
			DEALLOCATE db_get_distinct_calldate

			GOTO ENDPROCESS

	END CATCH

	FETCH NEXT FROM db_get_distinct_calldate
	INTO @VarCallDate 

     
END

CLOSE db_get_distinct_calldate   
DEALLOCATE db_get_distinct_calldate


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_TrunkInfo') )
		Drop table #temp_TrunkInfo

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CustomValidation') )
	    Drop table #temp_CustomValidation

GO
