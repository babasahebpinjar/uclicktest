USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCustomOutputEnrichment]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCustomOutputEnrichment]
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
	--select 'DEBUG: Printing the Input File Upload schema'
	--select * from ##temp_MedFormatterRecords

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

	 --Select 'DEBUG 1 ....... #tempFormatterInputRecords after updating Calling and callerd part address'								   
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
		SessionID,
		RecordStatus
	)
	select
	  -- RecordID
	  RecordID,
	  -- INTrunk
	    Case
			When IncomingTrunkGroupID is NOT NULL Then IncomingTrunkGroupID
			Else
				Case
					When CallingPartyAddress is NULL Then NULL
					Else
						Case
								When charindex('@' , CallingPartyAddress) <> 0 Then
									substring(CallingPartyAddress ,charindex('@' , CallingPArtyAddress) + 1 , charindex('|' , CallingPArtyAddress) - charindex('@' , CallingPArtyAddress)-1)
								Else
									substring(CallingPartyAddress , 1 , charindex('|' , CallingPArtyAddress) -1)
						End
				End

		End,
		-- OUTTrunk
		Case
			When OutgoingTrunkGroupID is NOT NULL Then OutgoingTrunkGroupID
			Else
				Case
					When CalledPartyAddress is NULL then NULL
					Else
						Case
								When charindex('@' , CalledPartyAddress) <> 0 Then
									substring(CalledPartyAddress ,charindex('@' , CalledPartyAddress) + 1 , charindex('|' , CalledPartyAddress) - charindex('@' , CalledPartyAddress)-1)
								Else
									substring(CalledPartyAddress , 1 , charindex('|' , CalledPartyAddress) -1)
						End
				End
			
		End,
		-- CallingNumber
		Case
		    When CallingPartyAddress is NULL then NULL
			Else
			    substring(
				Case
						When charindex('@' , CallingPartyAddress) <> 0 Then
							substring(CallingPartyAddress , 1 , charindex('@' , CallingPartyAddress) -1)
                        -- Added change to support some exception formats in CallingParty Address Field (Added 18th Nov 2018) 
						Else 
						    Case
							    When charindex('|' , CallingPartyAddress) <> 0 Then
										substring(CallingPartyAddress ,charindex('|' , CallingPArtyAddress) + 1 ,  len(CallingPartyAddress))
								Else NULL
							End
				End , 1 , 50)
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
					Case
							When Datediff(ss ,
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
										) = 0 Then 1
							Else Datediff(ss ,
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
					End

		End,
		--ReleaseCause
		ServiceReasonReturnCode,
		--SessionID
		SessionID, 
		--RecordStatus
		NULL
	from #tempFormatterInputRecords


 --   select 'DEBUG3 ....... Printing the Output File schema after enrichment'
	--select * from ##temp_MedFormatterOutputRecords

	-----------------------------------------------------------------
	-- Change Added on 15th Dec 2018
	-- Raw CDR records have a change in the format of the CALLED
	-- PART ADDRESS, which is causing the Called number to have
	-- B# as well as other information. This is causing the B# to
	-- be more than 50 characters in length and failing the formatter

	-- NOTE : Also updated the CalledNumber Field size to 100 from 50
	-- in the Output FileDefinition

	-- ACTUAL FORMAT   : Called Party Address:sip:9779816952235@185.32.77.42:5060;transport=udp;user=phone
	-- EXCEPTION FORMAT: Called Party Address:sip:2917200420;tgrp=Worldhub_Premium_178;trunk-context=peer@103.244.191.178:5060;transport=udp;user=phone
	------------------------------------------------------------------

	update ##temp_MedFormatterOutputRecords
	set CalledNumber = 
			Case
					When charindex(';' , CalledNumber) <> 0 Then substring(CalledNumber , 1 , charindex(';' , CalledNumber) -1)
					Else CalledNumber
			End
	Where CalledNumber is Not NULL

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

	----------------------------------------------------------------------------
	-- Reject all the long call duration partial CDR records as they dont contain
	-- information regarding call duration and can be mistaken for unsuccessful
	-- CDR Records
	-- RECORD SEQUENCE NUMBER not NULL and Call Duration  = 0
	----------------------------------------------------------------------------

	update tbl1
	set RecordStatus = 'REJECT'
	from ##temp_MedFormatterOutputRecords tbl1
	inner join ##temp_MedFormatterRecords tbl2 on tbl1.RecordID = tbl2.RecordID
	where tbl2.RecordSequenceNumber is not null
	and tbl1.CallDuration = 0
	and tbl1.RecordStatus is NULL

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
