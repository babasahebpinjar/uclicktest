USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSSummarizeCDRErrorTraffic_Nexwave]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSSummarizeCDRErrorTraffic_Nexwave]
(
	@BeginDate datetime,
	@EndDate datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


DECLARE @CDR_Table_Name varchar(100),
        @FTR_Table_Name varchar(100),
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
        @InsertClauseInbound varchar(max),
        @InsertClauseOutbound varchar(max),
        @InsertSelectClause varchar(max),
		@InsertSelectSummaryClause varchar(max),
		@GroupByClause varchar(max),
        @SchemaCallDate date

----------------------------------------------------------
-- Check if Start date is less than equal to End Date
----------------------------------------------------------

if (@BeginDate > @EndDate)
Begin

		set @ErrorDescription = 'ERROR !!! Begin Date should less than equal to End Date'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

------------------------------------------------------------------------
-- Create Date Range master table for running the summarization extract
------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDateRange ') )
		Drop table #TempAllDateRange 

Create table #TempAllDateRange (CallDate datetime)

While ( @BeginDate <= @EndDate )
Begin

		insert into #TempAllDateRange values (@BeginDate)
		set @BeginDate = DateAdd(dd , 1 , @BeginDate)

End

---------------------------------------------------------------
-- Initialize the parameters essential for running the extract.
---------------------------------------------------------------

set @InsertClauseInbound = 'Select 1, tbl1.CallDate,tbl1.CallDuration, ' + char(10) +
                    ' case ' +  char(10) +
					'    when len(isNULL(tbl1.CalledNumber , '''')) = 0 then ''******'' ' + char(10) +
					'    when len(tbl1.CalledNumber) <= 6 then tbl1.CalledNumber ' + char(10) +
					'    else substring(tbl1.CalledNumber, 1, 6) ' + char(10) +
					' end ,' + char(10) +
                    ' case ' +  char(10) +
					'    when len(isNULL(tbl1.CustomField4 , '''')) = 0 then ''******'' ' + char(10) +
					'    when len(tbl1.CustomField4) <= 6 then tbl1.CustomField4 ' + char(10) +
					'    else substring(tbl1.CustomField4, 1, 6) ' + char(10) +
					' end ,' + char(10) +
                    'tbl1.Answered, 1, tbl1.CallTypeID, tbl1.INAccountID,' + char(10) +
                    'tbl1.INTrunkID,tbl1.INCommercialTrunkID,tbl1.INDestinationID,' + char(10) +
                    'tbl1.RoutingDestinationID,tbl1.INServiceLevelID,' + char(10) +
                    'tbl2.RatePlanID, tbl2.NumberPlanID , isnull(tbl1.INErrorFlag,0)'



set @InsertClauseOutbound = 'Select 2, tbl1.CallDate, tbl1.CallDuration, ' + char(10) +
                    ' case ' +  char(10) +
					'    when len(isNULL(tbl1.CalledNumber , '''')) = 0 then ''******'' ' + char(10) +
					'    when len(tbl1.CalledNumber) <= 6 then tbl1.CalledNumber ' + char(10) +
					'    else substring(tbl1.CalledNumber, 1, 6) ' + char(10) +
					' end ,' + char(10) +
                    ' case ' +  char(10) +
					'    when len(isNULL(tbl1.CustomField5 , '''')) = 0 then ''******'' ' + char(10) +
					'    when len(tbl1.CustomField5) <= 6 then tbl1.CustomField5 ' + char(10) +
					'    else substring(tbl1.CustomField5, 1, 6) ' + char(10) +
					' end ,' + char(10) +
                    'tbl1.Answered, 1, tbl1.CallTypeID, tbl1.OUTAccountID,' + char(10) +
                    'tbl1.OUTTrunkID, tbl1.OUTCommercialTrunkID, tbl1.OUTDestinationID,' + char(10) +
                    'tbl1.RoutingDestinationID, tbl1.OUTServiceLevelID,' + char(10) +
                    'tbl2.RatePlanID, tbl2.NumberPlanID , isNUll(tbl1.OutErrorFlag,0)'


set @InsertSelectClause = ' DirectionID,CallDate,CallDuration, CalledNumber , OriginalCalledNumber, Answered,Seized,CallTypeID,AccountID,' + char(10) +
                    'TrunkID,CommercialTrunkID,DestinationID,' + char(10) +
                    'RoutingDestinationID,ServiceLevelID,' + char(10) +
                    'RatePlanID, NumberPlanID , ErrorType' 

set @InsertSelectSummaryClause = ' isnull(DirectionID, -1), CallDate, convert(Decimal(19,4) ,sum(CallDuration)/60.0), CalledNumber , ' + char(10) +
                                 ' OriginalCalledNumber, sum(Answered),sum(Seized), isnull(CallTypeID, -1), isnull(AccountID, -1),' + char(10) +
                                 ' isnull(TrunkID,-1), isnull(CommercialTrunkID, -1), isnull(DestinationID, -1),' + char(10) +
                                 ' isnull(RoutingDestinationID, -1) , isnull(ServiceLevelID, -1),' + char(10) +
                                 ' isnull(RatePlanID, -1), isNUll(NumberPlanID , -1) , Errortype'
								 
set @GroupByClause = ' isnull(DirectionID, -1), CallDate, CalledNumber , ' + char(10) +
                     ' OriginalCalledNumber, isnull(CallTypeID, -1), isnull(AccountID, -1),' + char(10) +
                     ' isnull(TrunkID,-1), isnull(CommercialTrunkID, -1), isnull(DestinationID, -1),' + char(10) +
                     ' isnull(RoutingDestinationID, -1) , isnull(ServiceLevelID, -1),' + char(10) +
                     ' isnull(RatePlanID, -1), isNUll(NumberPlanID , -1) ,ErrorType'								  

-----------------------------------------------------------------
-- Create a temporary table to store the summarization results
-----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRErrorSummary') )
		Drop table #tempCDRErrorSummary

Create Table #tempCDRErrorSummary
(
   DirectionID int,
   CallDate datetime,
   CallDuration int,
   CalledNumber varchar(10),
   OriginalCalledNumber varchar(10),
   Answered int,
   Seized int,
   CallTypeID int,
   AccountID int,
   TrunkID int,
   CommercialTrunkID int,
   DestinationID int,
   RoutingDestinationID int,
   ServiceLevelID int,
   RatePlanID int,
   NumberPlanID int,
   ErrorType int
)

----------------------------------------------------------------
-- Open cursor to start the process of extracting summary records
-- from each CDR Database for select dates
-----------------------------------------------------------------

Declare  @SQLString nvarchar(2000),
	    @ParamDefinition nvarchar(2000),
         @TableExists int
        
DECLARE db_populate_CDRErrorSummary_Data CURSOR FOR  
select tbl2.ServerAlias + '.' + tbl3.DatabaseName + '.dbo.tb_EER_' +
       right(convert(varchar(4) ,year(CallDate)), 2) + 
	   right(('0' + convert(varchar(2) ,Month(CallDate))),2) + 
	   right(('0' + convert(varchar(2) ,DatePart(dd ,CallDate))),2) ,
	   tbl2.ServerAlias + '.' + tbl3.DatabaseName + '.dbo.sysobjects',
      'tb_EER_' +
       right(convert(varchar(4) ,year(CallDate)), 2) + 
	   right(('0' + convert(varchar(2) ,Month(CallDate))),2) + 
	   right(('0' + convert(varchar(2) ,DatePart(dd ,CallDate))),2)
from REFERENCESERVER.UC_Operations.dbo.tb_ServerDatabase tbl1
inner join  REFERENCESERVER.UC_Operations.dbo.tb_Server tbl2 on tbl1.ServerID = tbl2.ServerID
inner join REFERENCESERVER.UC_Operations.dbo.tb_Database tbl3 on tbl1.DatabaseID = tbl3.DatabaseID
cross join #TempAllDateRange tbl4

OPEN db_populate_CDRErrorSummary_Data   
FETCH NEXT FROM db_populate_CDRErrorSummary_Data
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

            set @FTR_Table_Name = Replace(@CDR_Table_Name , 'TB_EER' , 'TB_FTR')
	    
		    ------------------------------------
			-- INBOUND Direction Error Records
			------------------------------------
          
			set @SQLStr = 'insert into #tempCDRErrorSummary ( '+ char(10) +
			@InsertSelectClause + ' )' + char(10) + ' ' +
			@InsertClauseInbound +
			' from  '+ @CDR_Table_Name + ' tbl1 ' + char(10) +
			' left Join ' + @FTR_Table_Name + ' tbl2 ' + char(10) +
			    ' on tbl1.ObjectInstanceID = tbl2. ObjectInstanceID and tbl1.BERID = tbl2.BERID and tbl2.DirectionID = 1 ' + char(10) +
			' where isnull(tbl1.INErrorFlag, 0) <> 0'
			  
			  
			  --print @SQLStr
			  
			  Exec (@SQLStr)     
			  
		    ------------------------------------
			-- OUTBOUND Direction Error Records
			------------------------------------	
			
			set @SQLStr = 'insert into #tempCDRErrorSummary ( '+ char(10) +
			@InsertSelectClause + ' )' + char(10) + ' ' +
			@InsertClauseOutbound +
			' from  '+ @CDR_Table_Name + ' tbl1 ' + char(10) +
			' left Join ' + @FTR_Table_Name + ' tbl2 ' + char(10) +
			    ' on tbl1.ObjectInstanceID = tbl2. ObjectInstanceID and tbl1.BERID = tbl2.BERID and tbl2.DirectionID = 2 ' + char(10) +
			' where isnull(tbl1.OUTErrorFlag, 0) <> 0'
			  
			  
			  --print @SQLStr
			  
			  Exec (@SQLStr)  					    
	      				
		   
		 END Try  
	     
		 BEGIN Catch
	     
				set @ErrorDescription = 'Error !! Extracting Error Records from table ' + @CDR_Table_Name + '. '+ERROR_MESSAGE()
	     
				set @ResultFlag = 1
	            
				CLOSE db_populate_CDRErrorSummary_Data  
				DEALLOCATE db_populate_CDRErrorSummary_Data 				
				GOTO ENDPROCESS
	     
		 End Catch
	     
		 --print @SQLStr

       NEXTREC:
	 
	   FETCH NEXT FROM db_populate_CDRErrorSummary_Data
	   INTO @CDR_Table_Name  , @Sys_Table_Name , @Data_Table_Name 
 
END  

CLOSE db_populate_CDRErrorSummary_Data  
DEALLOCATE db_populate_CDRErrorSummary_Data

----------------------------------------------------------------------------------------
-- Delete data for all the selected dates from the main summary table and insert new
-- summarized information
-----------------------------------------------------------------------------------------

Delete tbl1
from tb_CDRErrorSummary tbl1
inner join #TempAllDateRange tbl2 on tbl1.CallDate = tbl2.CallDate

----------------------------------------------------------------
--  Update the ErrorType for each record from Error Flag value
----------------------------------------------------------------

update #tempCDRErrorSummary
set Errortype =	Case  
						When  isnull(Errortype,0) & 1 = 1 then 1 --'Trunk UnResolved' 
						when  isnull(Errortype,0) & 2 = 2 then 2 --'Commercial Trunk UnResolved'
						when  isnull(Errortype,0) & 4 = 4 then 3 --'Agreement UnResolved' 
						when  isnull(Errortype,0) & 8 = 8 then 4 --'Service Level UnResolved' 
						when  isnull(Errortype,0) & 16 = 16 then 5 --'Routing Destination UnResolved' 
						when  isnull(Errortype,0) & 32 = 32 then 6 --'Rating Scenario UnResolved' 
						when  isnull(Errortype,0) & 64 = 64 then 7 --'Settlement Destination UnResolved '
						when  isnull(Errortype,0) & 128 = 128 then  8 --'Rate UnResolved' 
						Else  9 -- 'Not Defined'
				End 

-------------------------------------------------
-- Insert data into master summary table from
-- temp table
-------------------------------------------------

Begin Try

			set @SQLStr = 'insert into tb_CDRErrorSummary ( '+ char(10) +
			@InsertSelectClause + ' )' + char(10) + ' ' +
			' Select ' + @InsertSelectSummaryClause +
			' from  #tempCDRErrorSummary ' + char(10) +
			' Group by ' + char(10) +
			@GroupByClause

			Exec (@SQLStr)

			--print @SQLStr

End Try

Begin Catch

			set @ErrorDescription = 'Error !! Inserting data into Master CDR Error Summary table. '+ERROR_MESSAGE()	     
			set @ResultFlag = 1				
			GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDateRange ') )
		Drop table #TempAllDateRange 

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRErrorSummary') )
		Drop table #tempCDRErrorSummary
GO
