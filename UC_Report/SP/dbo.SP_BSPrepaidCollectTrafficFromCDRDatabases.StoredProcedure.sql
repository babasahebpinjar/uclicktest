USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepaidCollectTrafficFromCDRDatabases]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSPrepaidCollectTrafficFromCDRDatabases]
(
	@CallDate datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


DECLARE @CDR_Table_Name varchar(100),
        @Sys_Table_Name varchar(100), 
        @Data_Table_Name varchar(100), 
        @CDR_Partition varchar(100),
        @SQLStr varchar(max),
        @WhereClause varchar(max),
        @SelectClause varchar(max),
        @ExtractTableName varchar(100),
        @ErrorMsgStr varchar(2000),
        @TotalRecCount int,
        @ExtractClause varchar(max),
	    @JoinClause varchar(max),
        @InsertClause varchar(max),
        @InsertSelectClause varchar(max),
        @SchemaCallDate date,
		@ObjectInstanceTaskLogID varchar(100)

-----------------------------------------------------------------
-- Create a table to get the list of prepaid account durig period
-- of the call Date
-----------------------------------------------------------------

Declare @PrepaidPeriod int
set @PrepaidPeriod = convert(int ,replace(convert(varchar(7) , @CallDate , 120),'-' , ''))

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempPrepaidAccount') )
		Drop table #tempPrepaidAccount

Select AccountID
into #tempPrepaidAccount
from Referenceserver.UC_Reference.dbo.tb_AccountMode
where Period = @PrepaidPeriod
and AccountModeTypeID = -2 -- Prepaid Account

--------------------------------------------------------------
-- Initialize the parameters essential for running the extract.
---------------------------------------------------------------

set @InsertClause = 'Select CallDate, INAccountID, INAmount , INCurrencyID' 
set @InsertSelectClause = ' CallDate, AccountID, Amount , CurrencyID' 

----------------------------------------------------------------
-- Open cursor to start the process of extracting summary records
-- from each CDR Database for select dates
-----------------------------------------------------------------

Declare  @SQLString nvarchar(2000),
	     @ParamDefinition nvarchar(2000),
         @TableExists int
        
DECLARE db_populate_FTRSummary_Data CURSOR FOR  
select tbl2.ServerAlias + '.' + tbl3.DatabaseName + '.dbo.tb_ftrSummary_' +
       right(convert(varchar(4) ,year(@CallDate)), 2) + 
	   right(('0' + convert(varchar(2) ,Month(@CallDate))),2) + 
	   right(('0' + convert(varchar(2) ,DatePart(dd ,@CallDate))),2) ,
	   tbl2.ServerAlias + '.' + tbl3.DatabaseName + '.dbo.sysobjects',
      'tb_ftrSummary_' +
       right(convert(varchar(4) ,year(@CallDate)), 2) + 
	   right(('0' + convert(varchar(2) ,Month(@CallDate))),2) + 
	   right(('0' + convert(varchar(2) ,DatePart(dd ,@CallDate))),2)
from REFERENCESERVER.UC_Operations.dbo.tb_ServerDatabase tbl1
inner join  REFERENCESERVER.UC_Operations.dbo.tb_Server tbl2 on tbl1.ServerID = tbl2.ServerID
inner join REFERENCESERVER.UC_Operations.dbo.tb_Database tbl3 on tbl1.DatabaseID = tbl3.DatabaseID

OPEN db_populate_FTRSummary_Data   
FETCH NEXT FROM db_populate_FTRSummary_Data
INTO @CDR_Table_Name  , @Sys_Table_Name , @Data_Table_Name 

WHILE @@FETCH_STATUS = 0   
BEGIN   
       
		BEGIN Try

			---------------------------------------------------------------------------------
			-- Build the SQL command for calling to check if the summary table exists or not
			---------------------------------------------------------------------------------
		
			Set @SQLString=N'Select @param = count(*) from ' + @Sys_Table_Name + ' where name = ''' + @Data_Table_Name  + ''' and xtype = ''u'''

			SET @ParamDefinition=N'@param int OUTPUT'

			----------------------------------------------
			-- Execute the stored procedure dynamically
			----------------------------------------------

			EXECUTE sp_executesql
				@SQLString,
				@ParamDefinition,
				@param=@TableExists  OUTPUT

			--select @CDR_Table_Name , @Data_Table_Name , @Sys_Table_Name , @TableExists

            if ( @TableExists  = 0 )
                      GOTO NEXTREC	
	    
          
			set @SQLStr = 'insert into #tempPrepaidFTRSummary ( '+ char(10) +
			@InsertSelectClause + ' )' + char(10) + ' ' +
			@InsertClause +
			' from  '+ @CDR_Table_Name + ' tbl1' + char(10)+
			' inner join #tempPrepaidAccount tbl2' + char(10) +
			' on tbl1.INAccountID = tbl2.AccountID ' + char(10) +
			' where isnull(tbl1.INErrorFlag,0) = 0' + char(10) + -- Only successfully rated inbound traffic
			' and tbl1.Answered > 0'
			  
			  
			  --print @SQLStr
			  
			  Exec (@SQLStr)       
	      				
		   
		 END Try  
	     
		 BEGIN Catch
	     
				set @ErrorDescription = 'Error !!! Extracting data from table ' + @CDR_Table_Name + ' for summarization.'+ERROR_MESSAGE()
	     
				set @ResultFlag = 1
	            
				CLOSE db_populate_FTRSummary_Data  
				DEALLOCATE db_populate_FTRSummary_Data 
				
				GOTO ENDPROCESS
	     
		 End Catch
	     
		 --print @SQLStr

       NEXTREC:
	 
	   FETCH NEXT FROM db_populate_FTRSummary_Data
	   INTO @CDR_Table_Name  , @Sys_Table_Name , @Data_Table_Name 
 
END  

CLOSE db_populate_FTRSummary_Data  
DEALLOCATE db_populate_FTRSummary_Data


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempPrepaidAccount') )
		Drop table #tempPrepaidAccount

Return 0
GO
