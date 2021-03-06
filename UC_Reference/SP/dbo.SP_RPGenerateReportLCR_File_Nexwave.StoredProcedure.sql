USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPGenerateReportLCR_File_Nexwave]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPGenerateReportLCR_File_Nexwave]
(
	@ReportRunDate Datetime ,
	@MaxReportCount int,
	@RateEntityGroupID int,
	@CallTypeID int,
	@CountryIDList nvarchar(max),
	@DestinationIDList nvarchar(max),
	@AccountIDList nvarchar(max),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output,
	@ExecutionStr nvarchar(max) Output
)

As

--Declare @ReportStartTime DateTime  = getdate()
--Select 'Report Run Date : ' + convert(varchar(30) , @ReportStartTime  , 120)

set @ErrorDescription = NULL
set @ResultFlag = 0
set @ExecutionStr = NULL

--------------------------------------------------------------
-- In case the Rate Plan Group is 0 then set it to NULL to
-- indicate all Rate Plan Groups
--------------------------------------------------------------

if ( @RateEntityGroupID = 0 )
	set @RateEntityGroupID = NULL

--------------------------------------------------------------
-- In case the Call Type is 0 then set it to NULL to
-- indicate all Call types
--------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL


-----------------------------------------------------------------
-- Create table for list of all selected destinations from the 
-- parameter passed
-----------------------------------------------------------------

Begin Try

		Declare @CountryIDTable table (CountryID varchar(100) )


		insert into @CountryIDTable
		select * from FN_ParseValueList ( @CountryIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from @CountryIDTable where ISNUMERIC(CountryID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End

		------------------------------------------------------
		-- Check if the All the countries have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from @CountryIDTable 
						where CountryID = 0
				  )
		Begin

				  Delete from @CountryIDTable -- Remove all records

				  insert into @CountryIDTable (  CountryID )
				  Select countryID
				  from tb_country
				  where flag & 1  <> 1 -- Insert all the countries into the temp table

				  GOTO PROCESSDESTINATIONLIST
				  
		End
		
        -------------------------------------------------------------------
		-- Check to ensure that all the Country IDs passed are valid values
		-------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from @CountryIDTable 
						where CountryID not in
						(
							Select CountryID
							from tb_Country
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

		End

PROCESSDESTINATIONLIST:

		Declare @DestinationIDTable table (DestinationID varchar(100) )

		insert into @DestinationIDTable
		select * from FN_ParseValueList ( @DestinationIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from @DestinationIDTable where ISNUMERIC(DestinationID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End

		------------------------------------------------------
		-- Check if the All the Destinations have been selected 
		------------------------------------------------------

		if (
				   exists (
								select 1 
								from @DestinationIDTable 
								where DestinationID = 0
						  )
						  or
						  (
							(select count(*) from @DestinationIDTable ) = 0
						  )
			)
		Begin

				  Delete from @DestinationIDTable -- Remove all records

				  insert into @DestinationIDTable (  DestinationID )
				  Select DestinationID
				  from tb_Destination
				  where flag & 1  <> 1 -- Insert all the Destinations into the temp table
				  and NumberPlanID = -1 -- Routing Number Plan

				  GOTO PROCESSACCOUNTLIST
				  
		End
		
        -----------------------------------------------------------------------
		-- Check to ensure that all the Destination IDs passed are valid values
		-----------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from @DestinationIDTable 
						where DestinationID not in
						(
							Select DestinationID
							from tb_Destination
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

		End




PROCESSACCOUNTLIST:

		Declare @AccountIDTable table (AccountID varchar(100) )

		insert into @AccountIDTable
		select * from FN_ParseValueList ( @AccountIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from @AccountIDTable where ISNUMERIC(AccountID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End

		------------------------------------------------------
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if (
				   exists (
								select 1 
								from @AccountIDTable 
								where AccountID = 0
						  )
						  or
						  (
							(select count(*) from @AccountIDTable ) = 0
						  )
			)
		Begin

				  Delete from @AccountIDTable -- Remove all records

				  insert into @AccountIDTable (  AccountID )
				  Select AccountID
				  from tb_Account
				  where flag & 32  <> 32 -- Insert all the Accounts into the temp table
				  
				  GOTO PROCESSREPORT
				  
		End
		
        -----------------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from @AccountIDTable 
						where AccountID not in
						(
							Select AccountID
							from tb_Account
							where flag & 32 <> 32
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

		End


--Select 'Time Elapsed After Parsing Destination , Account List : ' + convert(varchar(20) ,DateDiff(ss ,@ReportStartTime , Getdate()) ) + ' secs'

PROCESSREPORT:

		Declare @VarDestinationID int,
				@VarCallTypeID int,
				@VarDestination varchar(60),
				@VarCallType Varchar(60),
				@VarRateEntity varchar(100) , 
				@VarRate Decimal(19,6),
				@Counter int,
				@SQLStr nvarchar(max)


		Select Dest.Destination , Dest.DestinationID ,cp.CallType ,cp.CallTypeID ,  rtd.rate, Replace(rp.RatePlan , 'Hubbing Outbound' , '') as RatePlan , rp.RatePlanID
		into #TempMasterData  
		from tb_Rate rt
		inner join tb_rateDetail rtd on rt.rateid = rtd.rateid
		inner join tb_Destination dest on rt.DestinationId = dest.DestinationID
		inner join tb_CallType cp on rt.CallTypeID =  cp.CallTypeID
		inner join tb_Rateplan rp on rt.RatePlanID = rp.RatePlanID
		inner join tb_Agreement agr on rp.AgreementID = agr.AgreementID
		inner join tb_Account acc on agr.AccountID = acc.AccountID
		inner join @DestinationIDTable dest2 on dest.DestinationID = dest2.destinationID
		inner join @AccountIDTable acc2 on acc.AccountID = acc2.AccountID
		inner join @CountryIDTable cou on dest.CountryID = cou.CountryID
		where Dest.NumberPlanID = -1 -- Routing Numberplan
		and rtd.RatetypeID = 101 -- Tier 1 rate
		and rp.DirectionID = 2 -- Outbound
		and rp.ProductCataLogID in (-2 ,-4)
		and rp.RatePlanGroupID = isnull(@RateEntityGroupID , rp.RatePlanGroupID)
		and cp.CallTypeID = isnull(@CallTypeID , cp.CallTypeID)
		and @ReportRunDate between rt.BeginDate and isnull(rt.EndDate , @ReportRunDate)
		and acc.Flag & 32 <> 32 -- Only Active Accounts to be selected

		------------------------------------------------------------
		-- Get the list of all the different Routing Destinations
		------------------------------------------------------------

		Select Distinct Destination , DestinationID , CallType ,CallTypeID
		into #TempDistinctRoutingEntity
		from #TempMasterData


		--------------------------------------------------------------------------
		-- Get the Maximum report count for which the report needs to be run
		-------------------------------------------------------------------------- 


		if ( ( isnull(@MaxReportCount, 0 ) = 0 ) )
		Begin
	
				Select @MaxReportCount = Max(RecordCount)
				from
				(
					select DestinationID , CallTypeID ,  Count(*) as RecordCount
					from #TempMasterData
					group by DestinationID , CallTypeID
				) tbl1


		End

		-----------------------------------------------------------------
		-- Create the Temporary Report data table for storing the results
		-----------------------------------------------------------------

		Declare @TableName Varchar(200)  = 'tbl_TempLCRReport_' + Replace(Replace(Replace(Replace(convert(varchar(30) , getdate() , 121) , '-' , '') , ':' , '') , '.' , ''), ' ', '')

		set @SQLStr = 'Create table ' + @TableName + ' ( ' + Char(10) +
					  'DestinationID int,' + Char(10) +
					  'Destination varchar(100),' + char(10) +
					  'CallTypeID int,' + Char(10) +
					  'CallType varchar(100),' + Char(10)

		set @Counter = 1

		While ( @Counter <= @MaxReportCount )
		Begin

				set @SQLStr = @SQLStr + 'RateEntity_'+ convert(varchar(100) , @Counter) + ' varchar(100),'+	Char(10)		
				set @SQLStr = @SQLStr + 'LCR_'+ convert(varchar(100) , @Counter) + ' Decimal(19,6),'+	Char(10)

				set @Counter =  @Counter + 1

		End

		set @SQLStr = substring(@SQLStr , 1 , len(@SQLStr) -2) + ')'

		print @SQLStr

		Exec(@SQLStr)
 

		---------------------------------------------------------
		-- Insert the distinct Destination and Call Type into the
		-- Report table
		----------------------------------------------------------

		set @SQLStr = 'Insert into ' + @TableName + char(10) +
					  '(DestinationID , Destination ,CallTypeID , CallType)'+ char(10) +
					  'Select DestinationID , Destination ,CallTypeID , CallType ' + char(10) +
					  'from #TempDistinctRoutingEntity'

		print @SQLStr

		Exec (@SQLStr)

--Select 'Time Elapsed After Creating Temporary Table : ' + convert(varchar(20) ,DateDiff(ss ,@ReportStartTime , Getdate()) ) + ' secs'

		----------------------------------------------------------------
		-- Open a cursor to traverse through all the Routing Entities
		-- and populate the report for them
		----------------------------------------------------------------

		------------------------------------------------
		-- Create temporary table to hold the rates
		-- for each Routing Entity
		------------------------------------------------

		Create table #TempRoutingEntityRate
		(

			RateEntityID int,
			RateEntity varchar(200),
			Rate Decimal(19,6)	
		)


		DECLARE db_Get_LCR_Cur CURSOR FOR  
		select Destination , DestinationID , CallType , CallTypeID
		From #TempDistinctRoutingEntity


		OPEN db_Get_LCR_Cur   
		FETCH NEXT FROM db_Get_LCR_Cur
		INTO @VarDestination , @VarDestinationID , @VarCallType, @VarCallTypeID 

		WHILE @@FETCH_STATUS = 0   
		BEGIN  

				Delete from #TempRoutingEntityRate

				Insert into #TempRoutingEntityRate (RateEntityID ,RateEntity , Rate)
				Select RatePlanID , RatePlan , Rate
				From #TempMasterData
				where DestinationID = @VarDestinationID
				and CallTypeID = @VarCallTypeID

				Set @Counter = 1

				set @SQLStr = 'Update '  + @TableName + ' set '+ Char(10) 

				DECLARE db_Get_LCR_Per_RE_Cur CURSOR FOR  
				select RateEntity , Rate
				From #TempRoutingEntityRate
				order by Rate

				OPEN db_Get_LCR_Per_RE_Cur   
				FETCH NEXT FROM db_Get_LCR_Per_RE_Cur
				INTO @VarRateEntity , @VarRate 

				WHILE @@FETCH_STATUS = 0   
				BEGIN
		
						if ( @Counter > @MaxReportCount )
						Begin

								GOTO PROCESSNEXTREC

						End	
				
				
						set @SQLStr = @SQLStr +
									  ' RateEntity_' + convert(varchar(10) , @Counter) + ' = ''' + @VarRateEntity + '''' + ',' + Char(10)+
									  ' LCR_' + convert(varchar(10) , @Counter) + ' = ''' + convert(varchar(20) , @VarRate) + '''' + ',' + Char(10)


						set @Counter = @Counter + 1

		 
						FETCH NEXT FROM db_Get_LCR_Per_RE_Cur
						INTO @VarRateEntity , @VarRate 

				END

		PROCESSNEXTREC:

		        set @SQLStr = substring(@SQLStr , 1 , len(@SQLStr) - 2) + Char(10) +
							' where DestinationID = ' + convert(varchar(20) , @VarDestinationID) + Char(10)+ 
							' and CallTypeID = ' + convert(varchar(20) , @VarCallTypeID)

				print @SQLStr

				Exec(@SQLStr)

				CLOSE db_Get_LCR_Per_RE_Cur  
				DEALLOCATE db_Get_LCR_Per_RE_Cur

				set @SQLStr = '' -- Empty the string after update

				FETCH NEXT FROM db_Get_LCR_Cur
				INTO @VarDestination , @VarDestinationID , @VarCallType, @VarCallTypeID 
 
		END   

		CLOSE db_Get_LCR_Cur  
		DEALLOCATE db_Get_LCR_Cur

--Select 'Time Elapsed After Populating Data : ' + convert(varchar(20) ,DateDiff(ss ,@ReportStartTime , Getdate()) ) + ' secs'


		------------------------------------------------------------
		-- Print records depending on the MAX Report Count paramter
		------------------------------------------------------------

		set @Counter = 1

		set @SQLStr = 'Select Destination,CallType,'

		While ( @Counter <= @MaxReportCount )
		Begin

				set @SQLStr =  @SQLStr + 'RateEntity_'+ convert(varchar(10) , @Counter) + ',LCR_'+ convert(varchar(10) , @Counter)+','
				set @Counter = @Counter + 1		

		End

		set @SQLStr = substring (@SQLStr , 1 , len(@SQLStr) -1)

		set @SQLStr  =  @SQLStr + ' from ' + @TableName +
						' order by Destination , CallType'


		Exec(@SQLStr)

		set @ExecutionStr = @SQLStr

--Select 'Time Elapsed After Printing Result : ' + convert(varchar(20) ,DateDiff(ss ,@ReportStartTime , Getdate()) ) + ' secs'

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Running Least Costing Route Report.' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO PROCESSEND

End Catch

-----------------------------------------------------------
-- Drop all the temporary tables post processing of data
-----------------------------------------------------------

PROCESSEND:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMasterData') )
Drop table #TempMasterData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDistinctRoutingEntity') )
Drop table #TempDistinctRoutingEntity

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRoutingEntityRate') )
Drop table #TempRoutingEntityRate

if exists (select 1 from sysobjects where xtype = 'U' and name = @TableName )
Exec('Drop table ' + @TableName)
GO
