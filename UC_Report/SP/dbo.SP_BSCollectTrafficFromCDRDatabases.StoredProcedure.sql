USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCollectTrafficFromCDRDatabases]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCollectTrafficFromCDRDatabases]
(
    @InstanceID int,
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
-- Create an entry in the Object Instance Task Log for this task
-----------------------------------------------------------------

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSObjectInstanceTaskLogInsert @InstanceID , 'Collect Traffic From CDR Databases' , @ObjectInstanceTaskLogID Output

--------------------------------------------------------------
-- Initialize the parameters essential for running the extract.
---------------------------------------------------------------

set @InsertClause = 'Select ObjectInstanceID,CallDate,CallHour,CallDuration,CircuitDuration,Answered,Seized,CallTypeID,INAccountID,OutAccountID,' + char(10) +
                    'INTrunkID,OutTrunkID,INCommercialTrunkID,OUTCOmmercialTrunkID,INDestinationID,' + char(10) +
                    'OUTDestinationID,RoutingDestinationID,INServiceLevelID,OUTServiceLEvelID,' + char(10) +
                    'INRatePlanID,OUTRatePlanID,INRatingMethodID,OUTRatingMethodID,INRoundedCallDuration,' + char(10) +
                    'OutRoundedCallDuration,INChargeDuration,OUTChargeDuration,INAmount,OUTAmount,INRate,OUTRate,' + char(10) +
					'INRateTypeID,OUTRateTypeID,INCurrencyID,OUTCurrencyID,INErrorFlag,OUTErrorFlag'


set @InsertSelectClause = ' ObjectInstanceID,CallDate,CallHour,CallDuration,CircuitDuration,Answered,Seized,CallTypeID,INAccountID,OutAccountID,' + char(10) +
                    'INTrunkID,OutTrunkID,INCommercialTrunkID,OUTCOmmercialTrunkID,INDestinationID,' + char(10) +
                    'OUTDestinationID,RoutingDestinationID,INServiceLevelID,OUTServiceLEvelID,' + char(10) +
                    'INRatePlanID,OUTRatePlanID,INRatingMethodID,OUTRatingMethodID,INRoundedCallDuration,' + char(10) +
                    'OutRoundedCallDuration,INChargeDuration,OUTChargeDuration,INAmount,OUTAmount,INRate,OUTRate,'+ char(10) +
					'INRateTypeID,OUTRateTypeID,INCurrencyID,OUTCurrencyID,INErrorFlag,OUTErrorFlag'

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
	    
          
			set @SQLStr = 'insert into #tempFTRSummary ( '+ char(10) +
			@InsertSelectClause + ' )' + char(10) + ' ' +
			@InsertClause +
			' from  '+ @CDR_Table_Name
			  
			  
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

Declare @TaskEndDate datetime

set @TaskEndDate = getdate()

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSObjectInstanceTaskLogUpdate @ObjectInstanceTaskLogID,
                                                                        @TaskEndDate,
																	    NULL,NULL,
																	    NULL, NULL,
																	    NULL, NULL


ENDPROCESS:

Return 0
GO
