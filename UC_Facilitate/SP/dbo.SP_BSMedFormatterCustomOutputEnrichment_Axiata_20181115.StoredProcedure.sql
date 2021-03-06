USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCustomOutputEnrichment_Axiata_20181115]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCustomOutputEnrichment_Axiata_20181115]
(
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Begin Try

	----------------------------------------------------------------------
	-- Move original input data from the temp table to another temp
	-- table for manipulation and enrichment
	----------------------------------------------------------------------

	if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFormatterInputRecords') )
	Drop table #tempFormatterInputRecords

	select * into #tempFormatterInputRecords
	from ##temp_MedFormatterRecords

	--select count(*) from #tempFormatterInputRecords

	-- Update the CallingPartyAddress and CalledPArtyAddress to enable 
	-- segregation of Trunks and numbers

	update #tempFormatterInputRecords
		set CallingPartyAddress = replace(replace(CallingPartyAddress , 'sip:' , '') , ':' , '|'),
			CalledPartyAddress = replace(replace(CalledPartyAddress , 'sip:' , '') , ':' , '|'),
			RequestedPartyAddress = 
									Case
										When charindex('@' , RequestedPartyAddress) <> 0 Then
											substring(RequestedPartyAddress , 5 , charindex('@' , RequestedPartyAddress) - 5)
									End

    update #tempFormatterInputRecords
		set CallingPartyAddress = 
									Case
											When charindex('|' , CallingPartyAddress) = 0 Then CallingPartyAddress + '|'
											Else CallingPartyAddress
									End,
			CalledPartyAddress = 
									Case
											When charindex('|' , CalledPartyAddress) = 0 Then CalledPartyAddress + '|'
											Else CalledPartyAddress
									End

	--select * from #tempFormatterInputRecords
									
    ---------------------------------------------------------
	-- Populate the output temp schema with enriched data
	-- from the temp input schema
	---------------------------------------------------------

	insert into ##temp_MedFormatterOutputRecords
	(
	  RecordID,
		INTrunk,
		OUTTrunk,
		CallingNumber,
		CalledNumber,
		CallDate,
		CallHour,
		CallMinute,
		CallSecond,
		CircuitDuration,
	    CallDuration,
		ReleaseCause,
		RecordStatus
	)
	select
	  -- RecordID
	  RecordID,
	  -- INTrunk
		Case
		    When CallingPartyAddress is NULL then NULL
			Else
				Case
						When charindex('@' , CallingPartyAddress) <> 0 Then
							substring(CallingPartyAddress ,charindex('@' , CallingPArtyAddress) + 1 , charindex('|' , CallingPArtyAddress) - charindex('@' , CallingPArtyAddress)-1)
						Else
							substring(CallingPartyAddress , 1 , charindex('|' , CallingPArtyAddress) -1)
				End
		End,
		-- OUTTrunk
		Case
		    When CalledPartyAddress is NULL then NULL
			Else
				Case
						When charindex('@' , CalledPartyAddress) <> 0 Then
							substring(CalledPartyAddress ,charindex('@' , CalledPartyAddress) + 1 , charindex('|' , CalledPartyAddress) - charindex('@' , CalledPartyAddress)-1)
						Else
							substring(CalledPartyAddress , 1 , charindex('|' , CalledPartyAddress) -1)
				End
		End,
		-- CallingNumber
		Case
		    When CallingPartyAddress is NULL then NULL
			Else
				Case
						When charindex('@' , CallingPartyAddress) <> 0 Then
							substring(CallingPartyAddress , 1 , charindex('@' , CallingPArtyAddress) -1)
						Else NULL
				End
		End,
		-- CalledNumber
		Case
		    When CalledPartyAddress is NULL then RequestedPartyAddress
			Else
				Case
						When charindex('@' , CalledPartyAddress) <> 0 Then
							substring(CalledPartyAddress , 1 , charindex('@' , CalledPartyAddress) -1)
						Else RequestedPartyAddress
				End
		End,
		-- CallDate
		convert(datetime ,'20'+ substring(ServiceDeliveryStartTimeStamp, 1,2) + '-'+
		substring(ServiceDeliveryStartTimeStamp, 3,2) + '-' +
		substring(ServiceDeliveryStartTimeStamp, 5,2)),
		-- CallHour
		convert(int ,substring(ServiceDeliveryStartTimeStamp, 7,2)),
		-- CallMinute
		convert(int ,substring(ServiceDeliveryStartTimeStamp, 9,2)),
		-- CallSecond
		convert(int ,substring(ServiceDeliveryStartTimeStamp, 11,2)),
		-- CircuitDuration
		Datediff(ss ,
					convert(datetime ,'20'+ substring(ServiceRequestTimeStamp, 1,2) + '-'+
					substring(ServiceRequestTimeStamp, 3,2) + '-' +
					substring(ServiceRequestTimeStamp, 5,2) + ' ' +
					substring(ServiceRequestTimeStamp, 7,2) + ':'+
					substring(ServiceRequestTimeStamp, 9,2) + ':' +
					substring(ServiceRequestTimeStamp, 11,2)),
					convert(datetime ,'20'+ substring(ServiceDeliveryStartTimeStamp, 1,2) + '-'+
					substring(ServiceDeliveryStartTimeStamp, 3,2) + '-' +
					substring(ServiceDeliveryStartTimeStamp, 5,2) + ' ' +
					substring(ServiceDeliveryStartTimeStamp, 7,2) + ':'+
					substring(ServiceDeliveryStartTimeStamp, 9,2) + ':' +
					substring(ServiceDeliveryStartTimeStamp, 11,2))
				),
		-- CallDuration
		Case
				When ServiceDeliveryEndTimeStamp is NULL Then 0
				Else
					Datediff(ss ,
								convert(datetime ,'20'+ substring(ServiceDeliveryStartTimeStamp, 1,2) + '-'+
								substring(ServiceDeliveryStartTimeStamp, 3,2) + '-' +
								substring(ServiceDeliveryStartTimeStamp, 5,2) + ' ' +
								substring(ServiceDeliveryStartTimeStamp, 7,2) + ':'+
								substring(ServiceDeliveryStartTimeStamp, 9,2) + ':' +
								substring(ServiceDeliveryStartTimeStamp, 11,2)),
								convert(datetime ,'20'+ substring(ServiceDeliveryEndTimeStamp, 1,2) + '-'+
								substring(ServiceDeliveryEndTimeStamp, 3,2) + '-' +
								substring(ServiceDeliveryEndTimeStamp, 5,2) + ' ' +
								substring(ServiceDeliveryEndTimeStamp, 7,2) + ':'+
								substring(ServiceDeliveryEndTimeStamp, 9,2) + ':' +
								substring(ServiceDeliveryEndTimeStamp, 11,2))
							)
		End,
		--ReleaseCause
		ServiceReasonReturnCode,
		-- RecordStatus
		NULL
	from #tempFormatterInputRecords


	------------------------------------------------------------
	-- Remove the '+' sign from the calling and called number
	------------------------------------------------------------

	update ##temp_MedFormatterOutputRecords
	set Callingnumber = replace(Callingnumber , '+' , ''),
		CalledNumber = replace(CalledNumber , '+' , '')


    -----------------------------------------------------------------
	-- Change Added on 6th Sept 2018
	-- Populate the OUTTRUNK as 'Missing Trunk' to capture all
	-- CDR records in the system, where the OUTTrunk is not provided
	------------------------------------------------------------------

	update ##temp_MedFormatterOutputRecords
	set OUTTrunk = 'Missing Trunk'
	where OUTTrunk is NULL

	----------------------------------------------------------------------------
	-- Update all the records as REJECTED, for which one or more of the essential
	-- fields are NULL:
	-- INTRUNK
	-- CALLEDNUMBER
	-- CALLDATE
	-- CALLHOUR
	-- CALLMINUTE
	-- CALLSECOND
	----------------------------------------------------------------------------

	update ##temp_MedFormatterOutputRecords
	set RecordStatus = 'REJECT'
	where INTrunk is NULL
		or CalledNumber is NULL
		or CallDate is NULL
		or CallHour is NULL
		or CallMinute is NULL
		or CallSecond is NULL


End Try

Begin Catch

    set @ErrorDescription = 'ERROR !!! During creation of output CDR records from input records.' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSMedFormatterCustomOutputEnrichment : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	set @ResultFlag = 1

End Catch


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFormatterInputRecords') )
	Drop table #tempFormatterInputRecords

Return 0





GO
