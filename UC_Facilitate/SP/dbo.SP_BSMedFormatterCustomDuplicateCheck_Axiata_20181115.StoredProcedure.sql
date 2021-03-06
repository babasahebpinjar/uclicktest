USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCustomDuplicateCheck_Axiata_20181115]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCustomDuplicateCheck_Axiata_20181115]
(
    @CDRFileName varchar(1000),
	@LogFilename varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@Resultflag int Output
)
As

-----------------------------------------------------------------------------
-- Duplicacy of CDR records has to be checked within the CDR file, as well
-- across the last N days worth of CDR records
----------------------------------------------------------------------------

-----------------------------------------------------------
-- The fields to be used for duplicate check are:
-- INtrunk
-- OUTTrunk
-- CalledNumber
-- CallDate
-- CallDuration
-- Callhour
-- CallMinute
-- CallSecond
-------------------------------------------------------------
-----------------------------------------------------
-- Check for duplicate records within the CDR file
-----------------------------------------------------

--Select 'Debug: Publish records in CDR file, which exist multiple times.' as status
--Select count(*) as TotalRecords , min(RecordID) as MinRecordID, max(RecordID) as MaxRecordID,
--		INtrunk , OUTTrunk ,CalledNumber, CallDate, CallDuration,
--		CallHour, CallMinute, CallSecond
--from ##temp_MedFormatterOutputRecords
--where RecordStatus is NULL
--group by INtrunk , OUTTrunk , CalledNumber, CallDate, CallDuration,
--			CallHour, CallMinute, CallSecond
--having count(1) > 1

update tbl1
set tbl1.RecordStatus = 'DUPLICATE'
from ##temp_MedFormatterOutputRecords tbl1
inner join
(
	Select count(*) as TotalRecords , min(RecordID) as RecordID,
		   INtrunk , OUTTrunk ,CalledNumber, CallDate, CallDuration,
		   CallHour, CallMinute, CallSecond
	from ##temp_MedFormatterOutputRecords
	where RecordStatus is NULL
	group by INtrunk , OUTTrunk , CalledNumber, CallDate, CallDuration,
			 CallHour, CallMinute, CallSecond
	having count(1) > 1
) tbl2 on tbl1.INtrunk = tbl2.INtrunk
	 and tbl1.OUTTrunk = tbl2.OUTTrunk
	 and tbl1.CalledNumber = tbl2.CalledNumber
	 and tbl1.CallDate = tbl2.CallDate
	 and tbl1.CallDuration = tbl2.CallDuration
	 and tbl1.CallHour = tbl2.CallHour
	 and tbl1.CallMinute = tbl2.CallMinute
	 and tbl1.CallSecond = tbl2.CallSecond
	 and tbl1.RecordID != tbl2.RecordID
where tbl1.RecordStatus is NULL

--select 'Debug: Publish duplicate records after dup check within file.' as status
--select * from ##temp_MedFormatterOutputRecords
--where RecordStatus = 'DUPLICATE'

-------------------------------------------------------------
-- Check for Duplicate CDR records across all the other CDRs
-- already processed in the system
--------------------------------------------------------------

-- Loop through the duplicate check table for each Call Date and classify the
-- records as unique or duplicate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRByCallDate') )
	Drop table #tempCDRByCallDate

create table #tempCDRByCallDate (CDRFileName varchar(1000) , RecordID int ,TransactionStr varchar(1000) , RecordStatus varchar(100))

Declare @VarTransactionStr varchar(2000),
        @VarCallDate datetime,
		@DupChckTableName varchar(100),
		@SQLStr varchar(2000)

DECLARE db_cur_DupCheck_By_Date CURSOR FOR
select distinct CallDate 
from ##temp_MedFormatterOutputRecords
where RecordStatus is NULL

OPEN db_cur_DupCheck_By_Date
FETCH NEXT FROM db_cur_DupCheck_By_Date
INTO @VarCallDate

While @@FETCH_STATUS = 0
BEGIN

	Begin Try
        
		set @DupChckTableName = 'Tb_DupCheck_' + replace(convert(varchar(10), @VarCallDate , 120),'-', '')

		Delete from #tempCDRByCallDate

		insert into #tempCDRByCallDate
		select @CDRFileName, RecordID,
				INTrunk+'|'+OUTTrunk+'|'+CalledNumber+'|'+
				replace(convert(varchar(10), CallDate , 120),'-', '') + '|'+
				convert(varchar(10), CallDuration) + '|' +
				convert(varchar(10), CallHour) + '|'+
				convert(varchar(10) , CallMinute) + '|' +
				convert(varchar(10) , CallSecond) ,
				RecordStatus
		from ##temp_MedFormatterOutputRecords
		where RecordStatus is NULL
		and CallDate = @VarCallDate
		
		if not exists (select 1 from sysobjects where name = @DupChckTableName and xtype = 'u' )
		Begin

			-- Create the temporary table to hold the uique transaction string
			
			Exec('Create table ' + @DupChckTableName + ' ( CDRFileName varchar(1000) , TransactionStr varchar(1000))')

			-- Insert all the records for the specific CallDate into the Duplicate check table

			Exec('insert into ' + @DupChckTableName + ' select CDRFileName ,  TransactionStr from #tempCDRByCallDate')

		End

		Else
		Begin

			-- Compare the transaction str for the CDR file records against the Dup Check table
			-- transaction str

			set @SQLStr = 'Update tbl1' + char(10)+
						  'set tbl1.RecordStatus = ''DUPLICATE''' + char(10)+
						  'from #tempCDRByCallDate tbl1 ' + char(10) +
						  'inner join ' + @DupChckTableName + ' tbl2 ' + char(10)+
						  ' on tbl1.TransactionStr = tbl2.TransactionStr'

			--print @SQLStr

			Exec(@SQLStr)

			-- Insert all the unique CDR records transaction str into the Dup Check table

			Exec('insert into ' + @DupChckTableName + ' select CDRFileName ,  TransactionStr from #tempCDRByCallDate where RecordStatus is NULL')

			-- Update the main CDR table with information regarding Duplicate CDR records

			update tbl1
			set tbl1.RecordStatus = 'DUPLICATE'
			from ##temp_MedFormatterOutputRecords tbl1
			inner join #tempCDRByCallDate tbl2 on tbl1.RecordID = tbl2.RecordID
			where tbl2.RecordStatus = 'DUPLICATE'


		End
		
		FETCH NEXT FROM db_cur_DupCheck_By_Date
		INTO @VarCallDate 
		  
	End Try		
	
	Begin Catch

		set @ErrorDescription = 'ERROR !!! Perfroming duplicate check of CDR records.' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterCustomDuplicateCheck : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		CLOSE db_cur_DupCheck_By_Date
		DEALLOCATE db_cur_DupCheck_By_Date
	
	End Catch 

END

CLOSE db_cur_DupCheck_By_Date
DEALLOCATE db_cur_DupCheck_By_Date

--select 'Debug: Publish duplicate records after dup check across CDRs.' as status
--select * from ##temp_MedFormatterOutputRecords
--where RecordStatus = 'DUPLICATE'

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRByCallDate') )
	Drop table #tempCDRByCallDate

GO
