USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCustomDuplicateCheck]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCustomDuplicateCheck]
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
-- Duplicate check needs to be based on the SESSION-ID field.
-- Every unique Session ID is considered as a unique CDR
-------------------------------------------------------------
-----------------------------------------------------
-- Check for duplicate records within the CDR file
-----------------------------------------------------

--------------------------------------------------------------------
-- The Session ID values are case sensitive, hence its important
-- that the comparison is done accordingly.
-- Convert the sessionID to Binary value and then compare to handle
-- case senstivity
---------------------------------------------------------------------

--Select 'Debug: Publish records in CDR file, which exist multiple times.' as status
--Select count(*) as TotalRecords , min(RecordID) as MinRecordID, max(RecordID) as MaxRecordID,
--		convert(varbinary(250) ,SessionID) as SessionID
--from ##temp_MedFormatterOutputRecords
--where RecordStatus is NULL
--group by convert(varbinary(250) ,SessionID)
--having count(1) > 1

update tbl1
set tbl1.RecordStatus = 'DUPLICATE'
from ##temp_MedFormatterOutputRecords tbl1
inner join
(
	Select count(*) as TotalRecords , min(RecordID) as RecordID,
		   convert(varbinary(250) ,SessionID) as SessionID
	from ##temp_MedFormatterOutputRecords
	where RecordStatus is null
	group by convert(varbinary(250) ,SessionID)
	having count(1) > 1
) tbl2 on convert(varbinary(250) ,tbl1.SessionID) = tbl2.SessionID
	 and tbl1.RecordID != tbl2.RecordID
where tbl1.RecordStatus is null

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
		select @CDRFileName, RecordID, SessionID ,RecordStatus
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
						  ' on convert(varbinary(250) ,tbl1.TransactionStr) = convert(varbinary(250) ,tbl2.TransactionStr)'

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

		set @ErrorDescription = 'ERROR !!! Performing duplicate check of CDR records.' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterCustomDuplicateCheck : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		CLOSE db_cur_DupCheck_By_Date
		DEALLOCATE db_cur_DupCheck_By_Date

		GOTO ENDPROCESS
	
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
