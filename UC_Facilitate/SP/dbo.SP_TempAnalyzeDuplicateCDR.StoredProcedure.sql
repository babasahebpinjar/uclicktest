USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_TempAnalyzeDuplicateCDR]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[SP_TempAnalyzeDuplicateCDR] As

Declare @InputFileFolder varchar(1000) = 'G:\Uclick_Product_Suite\uClickFacilitate\MedFormatter\Duplicate',
		@CDRFileExtension varchar(10) = '.DUP',
		@CDRFileNameTag varchar(20) = 'avh01',
		@AbsoluteLogFilePath varchar(1000) = 'F:\Uclick_Product_Suite\uClickFacilitate\Logs\CDRUploadDuplicate.Log'

Declare @SQLStr varchar(2000),
		@ErrorDescription varchar(2000)

if ( right(@InputFileFolder,1) <>'\')
	set @InputFileFolder = @InputFileFolder + '\'
			
----------------------------------------------------
-- Get the list of all files in the Input Folder
----------------------------------------------------

-- Create a temp table to hold the list of files

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToUpload') )
		Drop table #tmpGetListOfCDRFilesToUpload

Create table #tmpGetListOfCDRFilesToUpload (CDRFileName varchar(1000))

Begin Try

		-- Build the command to explore the input folder for files

		set @SQLStr = 'dir /b ' + '"' + @InputFileFolder + @CDRFileNameTag + '*' + @CDRFileExtension + '"'

		--print @SQLStr

		Insert	#tmpGetListOfCDRFilesToUpload
		EXEC 	master..xp_cmdshell @SQLStr

		-- Delete NULL records and record for "File Not Found"

		Delete from #tmpGetListOfCDRFilesToUpload
		where CDRfilename is NULL or CDRFileName = 'File Not Found'

		--Select 'Debug: Check the temporary table after running DIR command' as status
		--select * from #tmpGetListOfCDRFilesToUpload

End Try

Begin Catch

	set @ErrorDescription = 'SP_BSCDRUpload: '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR!!! While getting list of CDR files from input folder'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	--GOTO ENDPROCESS

End Catch


--select * from #tmpGetListOfCDRFilesToUpload

----------------------------------------------------------------------------------
-- Limit the list of files to export to only the files whose duplicate data
-- we need to upload and explore
-----------------------------------------------------------------------------------

delete from tbl1
from #tmpGetListOfCDRFilesToUpload tbl1
left join 
(
		select tbl2.CDRFilename + '.Dup' as CDRFileName
		from ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl1
		inner join tb_MedFormatterStatistics tbl2 on replace(tbl1.ObjectInstance , '.CDR' , '') = tbl2.CDRFileName
		where tbl1.statusid = 10012
		and 
		(
			convert(date , tbl1.Startdate) between '2018-07-01' and '2018-07-31'
			or
			convert(date , tbl1.EndDate) between '2018-07-01' and '2018-07-31'
		)
		and tbl2.TotalDuplicateMinutes > 0
) tbl2 on tbl1.CDRFileName = tbl2.CDRFileName
where tbl2.CDRFilename is NULL

--Delete from #tmpGetListOfCDRFilesToUpload
--where CDRFileName not in 
--(
--		select tbl2.CDRFilename + '.Dup'
--		from ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl1
--		inner join tb_MedFormatterStatistics tbl2 on replace(tbl1.ObjectInstance , '.CDR' , '') = tbl2.CDRFileName
--		where tbl1.statusid = 10012
--		and 
--		(
--			convert(date , tbl1.Startdate) between '2018-07-01' and '2018-07-31'
--			or
--			convert(date , tbl1.EndDate) between '2018-07-01' and '2018-07-31'
--		)
--		and tbl2.TotalDuplicateMinutes > 0
--)

--select * from #tmpGetListOfCDRFilesToUpload

------------------------------------------------------------------
-- Loop through the list of CDR files to upload them one by one
-------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadCDRFile') )	
	Drop table #TempUploadCDRFile

Create table #TempUploadCDRFile
(

	RecordNo int,
	RecordType int,
	CallingPartyAddress varchar(500),
	CalledPartyAddress varchar(500),
	ServiceRequestTimestamp varchar(100),
	ServiceDeliveryStartTimeStamp varchar(100),
	ServiceDeliveryEndTimeStamp varchar(100),
	ReleaseCause int,
	RequestedPartyAddress varchar(100) 
)

--select * from #TempUploadCDRFile

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadCDRFileAll') )	
	Drop table #TempUploadCDRFileAll

Create table #TempUploadCDRFileAll
(
    CDRFileName varchar(500),
	RecordNo int,
	RecordType int,
	CallingPartyAddress varchar(500),
	CalledPartyAddress varchar(500),
	ServiceRequestTimestamp varchar(100),
	ServiceDeliveryStartTimeStamp varchar(100),
	ServiceDeliveryEndTimeStamp varchar(100),
	ReleaseCause int,
	RequestedPartyAddress varchar(100) 
)

Declare @VarCDRFileName varchar(500),
		@FieldDelimiter varchar(100),
		@RowDelimiter varchar(100),
		@TotalRecordCount int,
		@CDRFileNameWithoutExtension varchar(100)

set @RowDelimiter = '\n'
set @FieldDelimiter = '|'

DECLARE db_cur_get_Upload_CDR_Files CURSOR FOR
select CDRFileName 
from #tmpGetListOfCDRFilesToUpload 

OPEN db_cur_get_Upload_CDR_Files
FETCH NEXT FROM db_cur_get_Upload_CDR_Files
INTO @VarCDRFileName 

While @@FETCH_STATUS = 0
BEGIN

		set @CDRFileNameWithoutExtension =  substring(@VarCDRFileName , 1 , len(@VarCDRFileName) - len(@CDRFileExtension))
		set @VarCDRFileName = @InputFileFolder + @VarCDRFileName

		delete from #TempUploadCDRFile

		Begin Try

			Select	@SQLStr = 'Bulk Insert #TempUploadCDRFile From ' 
						  + '''' + @VarCDRFileName +'''' + ' WITH (
						  FIELDTERMINATOR  = ''' + @FieldDelimiter + ''','+
						  'ROWTERMINATOR    = ''' + @RowDelimiter + ''''+')'

			--print @SQLStr
			Exec (@SQLStr)

			--select * from #TempUploadCDRFile


		End Try

		Begin Catch

			set @ErrorDescription = 'SP_BSCDRUpload : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + 'ERROR !!!Uploading the key fields file (' + @VarCDRFileName +').' + ERROR_MESSAGE()

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			CLOSE db_cur_get_Upload_CDR_Files
			DEALLOCATE db_cur_get_Upload_CDR_Files

			GOTO ENDPROCESS


		End Catch

	
		-- Get the count of records in the temp table in which file is uploaded
		select @TotalRecordCount = count(*)
		from #TempUploadCDRFile
		
		-- Move the File from the Temp table to the Final table
		insert into #TempUploadCDRFileAll
		Select @CDRFileNameWithoutExtension ,* from #TempUploadCDRFile
		
	
		FETCH NEXT FROM db_cur_get_Upload_CDR_Files
		INTO @VarCDRFileName   		 

END

CLOSE db_cur_get_Upload_CDR_Files
DEALLOCATE db_cur_get_Upload_CDR_Files


---------------------------------------------------------------------
-- Delete all the records where the ServiceDeliveryEndTime is NULL
---------------------------------------------------------------------

delete from #TempUploadCDRFileAll
where ServiceDeliveryEndTimeStamp is NULL

--select *
--from #TempUploadCDRFileAll


---------------------------------------------------------------------------
-- Extract all the important information from the CDR records related to
-- INTrunk
-- OUTTrunk
-- CallingNumber
-- CalledNumber
-- Call Date
-- Call Time
-- Call Duration
-- Circuit Duration
-----------------------------------------------------------------------------

update #TempUploadCDRFileAll
	set CallingPartyAddress = replace(replace(CallingPartyAddress , 'sip:' , '') , ':' , '|'),
		CalledPartyAddress = replace(replace(CalledPartyAddress , 'sip:' , '') , ':' , '|'),
		RequestedPartyAddress = 
								Case
									When charindex('@' , RequestedPartyAddress) <> 0 Then
										substring(RequestedPartyAddress , 5 , charindex('@' , RequestedPartyAddress) - 5)
								End

update #TempUploadCDRFileAll
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


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempEnrichedCDRData') )
		Drop table #TempEnrichedCDRData

create table #TempEnrichedCDRData
(
    CDRFileName varchar(500),
	RecordNo int,
	RecordType int,
	INTrunk varchar(50),
	OUTTrunk varchar(50),
	CallingNumber varchar(50),
	CalledNumber varchar(50),
	CallDate datetime,
	CircuitDuration int,
	CallDuration int,
	ReleaseCause int
)

insert into #TempEnrichedCDRData
(
    CDRFileName,
	RecordNo,
	RecordType,
	INTrunk,
	OUTTrunk,
	CallingNumber,
	CalledNumber,
	CallDate,
	CircuitDuration,
	CallDuration,
	ReleaseCause
)
select
    CDRFileName,
	-- RecordNo
	RecordNo,
	-- Record Type
	RecordType,
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
	substring(ServiceDeliveryStartTimeStamp, 5,2) +  ' ' +
	-- CallHour
	convert(varchar(2) ,substring(ServiceDeliveryStartTimeStamp, 7,2)) + ':' + 
	-- CallMinute
	convert(varchar(2) ,substring(ServiceDeliveryStartTimeStamp, 9,2)) + ':' +
	-- CallSecond
	convert(varchar(2) ,substring(ServiceDeliveryStartTimeStamp, 11,2))),
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
	ReleaseCause
from #TempUploadCDRFileAll

-- Add unique RecordID for each of the records

Alter table #TempEnrichedCDRData Add RecordID int identity(1,1)

------------------------------------------------------------
-- Remove the '+' sign from the calling and called number
------------------------------------------------------------

update #TempEnrichedCDRData
set Callingnumber = replace(Callingnumber , '+' , ''),
	CalledNumber = replace(CalledNumber , '+' , '')

update #TempEnrichedCDRData
set Callingnumber = 
		Case
				When substring(Callingnumber , 1,2) = '00' then substring(Callingnumber , 3 , len(CallingNumber))
				Else Callingnumber
		End



-------------------------------------------------------------------
-- Populate the account on the basis of the IN and OUT trunks
-------------------------------------------------------------------

Alter table #TempEnrichedCDRData Add INAccountID varchar(100)
Alter table #TempEnrichedCDRData Add OUTAccountID varchar(100)

update tbl1
set INAccountID = tbl2.AccountID
from #TempEnrichedCDRData tbl1
inner join Referenceserver.UC_Reference.dbo.tb_Trunk tbl2 on tbl1.INTrunk = tbl2.Trunk
where  tbl2.TrunkTypeID <> 9

update tbl1
set OUTAccountID = tbl2.AccountID
from #TempEnrichedCDRData tbl1
inner join Referenceserver.UC_Reference.dbo.tb_Trunk tbl2 on tbl1.OUtTrunk = tbl2.Trunk
where  tbl2.TrunkTypeID <> 9


-----------------------------------------------------------
-- Populate the IN and OUT Commercial trunk informartion
-----------------------------------------------------------

Alter table #TempEnrichedCDRData Add INCommercialTrunkID int
Alter table #TempEnrichedCDRData Add OUTCommercialTrunkID int

Declare @VarCallDate date

DECLARE DB_CDR_Populate_Commercial_Trunk CURSOR FOR  
select Distinct convert(date ,CallDate)
from #TempEnrichedCDRData


OPEN DB_CDR_Populate_Commercial_Trunk  
FETCH NEXT FROM DB_CDR_Populate_Commercial_Trunk
INTO @VarCallDate

WHILE @@FETCH_STATUS = 0   
BEGIN 

       Begin Try

			------------------------------------------------------------------
			-- Get the list of all the Technical Trunks which are active
			-- on the particular call date
			-------------------------------------------------------------------

			--select @VarCallDate as CallDate

			if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_TechnicalTrunkDetails') )
					Drop table #temp_TechnicalTrunkDetails

			select tbl1.Trunk , tbl1.TrunkID , tbl3.CommercialTrunkID , tbl3.EffectiveDate , tbl3.DirectionID
			into #temp_TechnicalTrunkDetails
			from REFERENCESERVER.UC_Reference.dbo.tb_Trunk tbl1
			inner join 
			(
				Select TrunkID , max(Effectivedate) as EffectiveDate
				from REFERENCESERVER.UC_Reference.dbo.tb_TrunkDetail 
				where ActiveStatusID = 1
				and Effectivedate <= @VarCallDate
				Group by TrunkID
			)tbl2 on tbl1.TrunkID = tbl2.TrunkID
			inner join REFERENCESERVER.UC_Reference.dbo.tb_TrunkDetail tbl3 on
								 tbl2.TrunkID = tbl3.TrunkID
								 and
								 tbl2.EffectiveDate = tbl3.EffectiveDate
			where tbl1.trunktypeID <> 9

			--select * from #temp_TechnicalTrunkDetails

			------------------------------------------------------------------
			-- Update the records in tb_BERTemp with Commercial Trunk Details
			------------------------------------------------------------------

			update tbl1
			set tbl1.InCommercialTrunkID = tbl2.CommercialTrunkID
			from #TempEnrichedCDRData tbl1
			inner join #temp_TechnicalTrunkDetails tbl2 on
			         tbl1.INTrunk = tbl2.Trunk
					 and
					 tbl2.DirectionID in (1,3) -- INBOUND or BI-DIRECTIONAL
			where convert(date ,tbl1.CallDate) = @VarCallDate

			update tbl1
			set tbl1.OutCommercialTrunkID = tbl2.CommercialTrunkID
			from #TempEnrichedCDRData tbl1
			inner join #temp_TechnicalTrunkDetails tbl2 on
			         tbl1.OutTrunk = tbl2.Trunk
					 and
					 tbl2.DirectionID in (2,3) -- OUTBOUND or BI-DIRECTIONAL
			where convert(date ,tbl1.CallDate) = @VarCallDate
			
	   End Try

	   Begin Catch

			set @ErrorDescription = 'ERROR !!!! While resolving Commercial Trunk for Call date : ' + convert(varchar(10) , @VarCallDate , 120) + '. ' + ERROR_MESSAGE()

			CLOSE DB_CDR_Populate_Commercial_Trunk 
			DEALLOCATE DB_CDR_Populate_Commercial_Trunk

			GOTO ENDPROCESS


	   End Catch

	   FETCH NEXT FROM DB_CDR_Populate_Commercial_Trunk
	   INTO @VarCallDate
 
END   

CLOSE DB_CDR_Populate_Commercial_Trunk 
DEALLOCATE DB_CDR_Populate_Commercial_Trunk


-----------------------------------------------------------------------
-- Populate the Country Code and routing Destination for all the records 
------------------------------------------------------------------------

Alter table #TempEnrichedCDRData Add Destination varchar(100)
Alter table #TempEnrichedCDRData Add Country varchar(100)

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_RoutingBreakout') )
		Drop table #temp_RoutingBreakout

select *
into #temp_RoutingBreakout
from
(
	Select tbl1.DestinationID , tbl1.Destination , tbl1.CountryID, tbl3.Country,
		   tbl1.DestinationTypeID , tbl1.NumberPlanID, tbl1.BeginDate as DestBeginDate,
		   tbl1.EndDate as DestEndDate , tbl2.DialedDigitsID , tbl2.DialedDigits as DialedDigit ,
		   tbl2.BeginDate as DDBeginDate , tbl2.EndDate as DDEndDate
	from REFERENCESERVER.UC_Reference.dbo.tb_Destination tbl1
	inner join REFERENCESERVER.UC_Reference.dbo.tb_DialedDigits tbl2
		   on tbl1.DestinationID = tbl2.DestinationID
	inner join REFERENCESERVER.UC_Reference.dbo.tb_country tbl3 on tbl1.CountryID = tbl3.CountryID
	where tbl1.Flag & 1 <> 1
	and tbl2.Flag & 1 <> 1
) as TBL1
where TBL1.numberplanid = -1


Declare @MaxLength int,
        @MaxLengthRef int,
        @Counter int = 1


select @MaxLength = Max(Len(CalledNumber))
from #TempEnrichedCDRData

select @MaxLengthRef = Max(Len(DialedDigit))
from #temp_RoutingBreakout

set @MaxLength = 
    Case
			when @MaxLength <= @MaxLengthRef then @MaxLength
			when @MaxLength > @MaxLengthRef then @MaxLengthRef
	End

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRCalledNumberBreakout') )
		Drop table #temp_CDRCalledNumberBreakout

Begin Try

		Create table #temp_CDRCalledNumberBreakout
		(
			RecordID int,
			CalledNumber varchar(100),
			CallDate datetime,
			Destination varchar(100),
			Country varchar(100)
		)

		while ( @Counter <= @MaxLength )
		Begin

				set @SQLStr = 'Alter table #temp_CDRCalledNumberBreakout add CalledNumber_'+convert(varchar(10) ,@Counter) + ' varchar(100)'
		
				Exec (@SQLStr)

				set @Counter = @Counter + 1

		End

		---------------------------------------------------------------------
		-- Insert records into the temp table for each of the CDR records
		---------------------------------------------------------------------

		insert into #temp_CDRCalledNumberBreakout
		(RecordID , CalledNumber , CallDate)
		Select RecordID , CalledNumber , CallDate
		from #TempEnrichedCDRData
		where CalledNumber is not NULL 

		--select *
		--from #temp_CDRCalledNumberBreakout

		set @Counter = 1
		set @SQLStr = 'Update #temp_CDRCalledNumberBreakout set ' + char(10)

		While ( @Counter <= @MaxLength )
		Begin

				set @SQLStr = @SQLStr + ' Callednumber_'+ convert(varchar(100) , @Counter) + 
							  ' = Case ' +
							  ' When len(Callednumber) >= '+ convert(varchar(100) , @Counter) + ' then substring(Callednumber , 1 , ' + convert(varchar(100) , @Counter) + ')' +
							  ' Else NULL' +
							  ' End,' + char(10)				  
					  
				set @Counter = @Counter + 1			  		

		End

		set @SQLStr = substring(@SQLStr , 1 ,  len(@SQLStr) -2 )

		--print @SQLStr

		Exec (@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! During populating break out table. ' + ERROR_MESSAGE()
		RaisError( '%s' , 16,1 , @ErrorDescription)
		GOTO ENDPROCESS

End Catch

-----------------------------------------------------------------------
-- Update the routing DestinationID and routing Country ID in the
-- temporary table
------------------------------------------------------------------------
Begin Try

		set @Counter = @MaxLength

		While ( @Counter > 0 )
		Begin

				set @SQLStr = 'update tbl1 ' + char(10) +
				              ' set tbl1.Destination  = tbl2.Destination ,' + char(10) +
							  ' tbl1.Country = tbl2.Country ' + char(10) +
							  ' from #temp_CDRCalledNumberBreakout tbl1 ' + char(10) +
							  ' inner join #temp_RoutingBreakout tbl2 on ' + char(10) +
							  ' tbl1.CalledNumber_'+ convert(varchar(30) , @Counter) + ' = tbl2.DialedDigit '+ char(10) +
							  ' where tbl1.Destination is NULL'  + char(10) +
							  ' and tbl1.CallDate between tbl2.DDBeginDate and isnull(tbl2.DDEndDate , tbl1.CallDate)'+ char(10) +
							  ' and tbl1.CallDate between tbl2.DestBeginDate and isnull(tbl2.DestEndDate , tbl1.CallDate)'


				--print @SQLStr
							  
				Exec (@SQLStr)			   
					  
				set @Counter = @Counter - 1			  		

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! When updating the Destination and country details in Temporary table. ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 ,@ErrorDescription)
		GOTO ENDPROCESS

End Catch

--select *
--from #temp_CDRCalledNumberBreakout

update tbl1
set tbl1.Destination = tbl2.Destination,
    tbl1.Country = tbl2.Country
from #TempEnrichedCDRData tbl1
inner join #temp_CDRCalledNumberBreakout tbl2
     on tbl1.RecordID = tbl2.RecordID

update #TempEnrichedCDRData
set Destination = 'Not Resolved',
    Country = 'Not Resolved'
where Destination is NULL


select isnull(tbl2.AccountAbbrv,'****') as INAccount , isnull(tbl3.AccountAbbrv, '****') as OUTAccount,
       --tbl4.Trunk as INCommercialTrunk , tbl5.Trunk as OUTCommercialTrunk,
	   Country, convert(varchar(3) , calldate , 100) as CallMonth,
	   count(*) as TotalRecords , convert(Decimal(19,2) ,sum(CallDuration)/60.0) as Minutes
from #TempEnrichedCDRData tbl1
left join ReferenceServer.UC_Reference.dbo.tb_account as tbl2 on tbl1.INAccountID = tbl2.AccountID
left join ReferenceServer.UC_Reference.dbo.tb_account as tbl3 on tbl1.OUTAccountID = tbl3.AccountID
left join ReferenceServer.UC_Reference.dbo.tb_Trunk as tbl4 on tbl1.INCommercialTrunkID = tbl4.TrunkID
left join ReferenceServer.UC_Reference.dbo.tb_Trunk as tbl5 on tbl1.OUTCommercialTrunkID = tbl5.TrunkID
where month(CallDate) in (7)
and callduration > 0
group by isnull(tbl2.AccountAbbrv,'****') ,  isnull(tbl3.AccountAbbrv, '****') ,
         --tbl4.Trunk, tbl5.Trunk,
		 Country, convert(varchar(3) , calldate , 100)
order by 4,6 Desc


select tbl2.AccountAbbrv as INAccount , tbl3.AccountAbbrv as OUTAccount,
       --tbl4.Trunk as INCommercialTrunk , tbl5.Trunk as OUTCommercialTrunk,
	   Country, Destination ,convert(varchar(3) , calldate , 100) as CallMonth,
	   count(*) as TotalRecords , convert(Decimal(19,2) ,sum(CallDuration)/60.0) as Minutes
from #TempEnrichedCDRData tbl1
inner join ReferenceServer.UC_Reference.dbo.tb_account as tbl2 on tbl1.INAccountID = tbl2.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_account as tbl3 on tbl1.OUTAccountID = tbl3.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_Trunk as tbl4 on tbl1.INCommercialTrunkID = tbl4.TrunkID
inner join ReferenceServer.UC_Reference.dbo.tb_Trunk as tbl5 on tbl1.OUTCommercialTrunkID = tbl5.TrunkID
where month(CallDate) in (7)
and callduration > 0
group by tbl2.AccountAbbrv , tbl3.AccountAbbrv ,
         --tbl4.Trunk, tbl5.Trunk,
		 Country, Destination ,convert(varchar(3) , calldate , 100)
order by 5,7 Desc


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempEnrichedCDRDataOutput') )
		Drop table #TempEnrichedCDRDataOutput

select INTRUNK , OUTTRUNK , CALLINGNUMBER , CALLEDNUMBER ,
       convert(date ,CALLDATE) as CALLDATE,
	   convert(int ,substring(convert(varchar(20) , CallDate ,120) , 12,2)) as CallHour,
	   convert(int ,substring(convert(varchar(20) , CallDate ,120) , 15,2)) as CallMinute,
	   convert(int,substring(convert(varchar(20) , CallDate ,120) , 18,2)) as CallSecond,
	   CircuitDuration,
	   CallDuration,
	   ReleaseCause,
	   CDRFileName
into #TempEnrichedCDRDataOutput
from #TempEnrichedCDRData
where callduration > 0
and Month(CallDate) = 7

--GOTO ENDPROCESS

---------------------------------------------------------
-- Publish the output file containing all the duplicate
-- CDR records with call duration > 0
----------------------------------------------------------

if exists(select 1 from #TempEnrichedCDRDataOutput where callduration > 0)
Begin

        Declare @HeaderFile varchar(500),
				@RecordFile varchar(500),
				@datestring varchar(100),
			    @bcpCommand varchar(5000),
			    @FileExists int,
			    @res int,
			    @QualifiedTableName varchar(500)

         select @datestring = CONVERT(varchar(50), getdate(), 20)
         select @datestring = REPLACE(@datestring, ':', '')
         select @datestring = REPLACE(@datestring, '-', '')
         select @datestring = ltrim(rtrim(REPLACE(@datestring, ' ', '_')))	

		 set @RecordFile = @InputFileFolder + 'avh01-5_-_DUP.'+ substring(@datestring,1, len(@datestring)-2) + '+0800.CDR'

		 --select @RecordFile

		 set @QualifiedTableName = 'TempDupRecordCDRFile_'+@datestring

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
			Exec('Drop table ' + @QualifiedTableName)

         -- Move the data from the temporary table to the qualified table
		 Exec('select * into '+ @QualifiedTableName + ' from #TempEnrichedCDRDataOutput')

         Set @QualifiedTableName = db_name() + '.dbo.' + @QualifiedTableName

		  SET @bcpCommand = 'bcp "SELECT * from ' + @QualifiedTableName + '" queryout ' + '"' + ltrim(rtrim(@RecordFile )) + '"' + ' -c -t"," -r"\n" -T -S '+ @@servername
         --print @bcpCommand 

         EXEC master..xp_cmdshell @bcpCommand

End


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToUpload') )
		Drop table #tmpGetListOfCDRFilesToUpload

--if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempEnrichedCDRData') )
--		Drop table #TempEnrichedCDRData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempEnrichedCDRDataOutput') )
		Drop table #TempEnrichedCDRDataOutput

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadCDRFile') )	
	Drop table #TempUploadCDRFile

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadCDRFileAll') )	
	Drop table #TempUploadCDRFileAll

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_RoutingBreakout') )
		Drop table #temp_RoutingBreakout

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRCalledNumberBreakout') )
		Drop table #temp_CDRCalledNumberBreakout

if exists ( select 1 from sysobjects where name = 'TempDupRecordCDRFile_'+@datestring and xtype = 'U')
		Exec('Drop table ' + 'TempDupRecordCDRFile_'+@datestring)
GO
