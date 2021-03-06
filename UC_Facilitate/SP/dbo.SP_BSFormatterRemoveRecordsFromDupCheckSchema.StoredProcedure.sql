USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSFormatterRemoveRecordsFromDupCheckSchema]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSFormatterRemoveRecordsFromDupCheckSchema]
(
	@CDRFileName varchar(1000),
	@LogFileName varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@REsultFlag int Output
)
As

Begin Try

		----------------------------------------------------------------------
		-- Get the list of all the Dup Check tables and store in a temp table
		----------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempDupCheckTableList') )
			Drop table #tempDupCheckTableList

		select name as TableName
		into #tempDupCheckTableList
		from sysobjects
		where name like 'Tb_DupCheck_%'
		and xtype = 'U'

		---------------------------------------------------------------------
		-- Loop through each of the Dup Check tables and delete the records 
		-- for the CDR file
		---------------------------------------------------------------------

		Alter table #tempDupCheckTableList add RecordID int identity(1,1)

		Declare @CurrentRecordID int,
				@MaxRecordID int,
				@TableName varchar(100)

		select @CurrentRecordID = min(RecordID),
			   @MaxRecordID= max(RecordID)
		from #tempDupCheckTableList

		While (@CurrentRecordID <= @MaxRecordID)
		Begin

			 select @TableName = TableName
			 from #tempDupCheckTableList
			 where RecordID = @CurrentRecordID

			 Exec('Delete from ' + @TableName + ' where CDRFileName = ''' + @CDRFileName + '''')

			 set @CurrentRecordID = @CurrentRecordID + 1

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Deleting records from Dup Check tables for CDR File : ' + @CDRFileName
  
		set @ErrorDescription = 'SP_BSFormatterRemoveRecordsFromDupCheckSchema : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempDupCheckTableList') )
	Drop table #tempDupCheckTableList
GO
