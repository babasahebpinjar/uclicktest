USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_TempUploadSellingRates]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_TempUploadSellingRates] As

Declare @RatePlanID int = 38

if exists ( select 1 from sysobjects where name = 'Temp_Rate' and xtype = 'U' )
	Drop table Temp_Rate

Create table Temp_Rate
(
	RatePlanID int,
	Destination varchar(100),
	Rate Decimal(19,6),
	BeginDate datetime,
	EndDate datetime
)

------------------------------------------------------
-- Section to insert the rates in the temp_rate table
------------------------------------------------------

insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-8110-R',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-812',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-8120-R',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-813',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-821',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-822',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-823',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-851',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-852',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-853',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Telkomsel-8530-R',0.0389,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Indosat-814',0.0365,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Indosat-815',0.0365,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Indosat-816',0.0365,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Indosat-855',0.0365,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Indosat-856',0.0365,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Indosat-857',0.0365,'2018-10-16' , NULL)
insert into Temp_Rate values (38, 'Indonesia-Mobile Indosat-858',0.0365,'2018-10-16' , NULL)

-----------------------------------------------------------
-- Alter table to add identity column for each rate record
-----------------------------------------------------------

Alter table Temp_Rate Add RecordID int identity(1,1)

Declare @ErrorMsgStr varchar(2000),
        @ResultFlag int = 0

-------------------------------------------
--		    VALIDATION SECTION 
-------------------------------------------

---------------------------------------------------------------
-- Check to see if the Rate Plan exists in the system and has 
-- direction as INBOUND
---------------------------------------------------------------

if not exists (Select 1 from tb_RatePlan where RatePlanID = @RatePlanID and DirectionID = 1 )
Begin

		set @ErrorMsgStr = 'ERROR !!!! Cannot find rateplan in the system for ID : ' + convert(varchar(10) , @RatePlanID)
		RaisError('%s',16,1,@ErrorMsgStr)
		GOTO ENDPROCESS 

End

---------------------------------------------------------------------
-- Check the data to see if there are no overlapping rate records
-- For each destination whose rates have been provided
---------------------------------------------------------------------

Declare @VarDestination varchar(100),
        @VarRecordID int,
		@VarBeginDate datetime,
		@VarEndDate datetime,
		@MaxEndDate datetime

Create table #TempDateOverlapCheck
(
	BeginDate datetime,
	EndDate datetime
)

DECLARE db_Validate_Rate_Records CURSOR FOR  
select Destination , RecordID , BeginDate , EndDate
From Temp_Rate
order by RecordID

OPEN db_Validate_Rate_Records   
FETCH NEXT FROM db_Validate_Rate_Records
INTO @VarDestination , @VarRecordID , @VarBeginDate ,@VarEndDate



WHILE @@FETCH_STATUS = 0   
BEGIN

		---------------------------------------------------
		-- Check to see if there are no overlap records
		-- provided for upload
		----------------------------------------------------

		Delete from #TempDateOverlapCheck

		set @ResultFlag = 0

		insert into #TempDateOverlapCheck
		select BeginDate , EndDate
		from Temp_Rate
		where Destination = @VarDestination
		and RecordID <> @VarRecordID

		if ( ( select count(*) from #TempDateOverlapCheck) > 0)
		Begin

				Exec SP_BSCheckDateOverlap @VarBeginDate , @VarEndDate , @ResultFlag Output

				if (@ResultFlag = 1)
				Begin

						set @ErrorMsgStr = 'ERROR !!! Overlapping records provided for Destination: ' + @VarDestination
						RaisError('%s' , 16,1 , @ErrorMsgStr)

						CLOSE db_Validate_Rate_Records  
						DEALLOCATE db_Validate_Rate_Records

						GOTO ENDPROCESS

				End


		End

		---------------------------------------------------------------------
		-- Check to see if the Reference number plan has a destination by
		-- the name and provided Rate Period
		---------------------------------------------------------------------

		if (@VarEndDate is NULL)
		Begin

				if not exists ( 
								select 1 from tb_Destination 
								where Destination = @VarDestination 
								and	@VarBeginDate between BeginDate and isnull(EndDate, @VarBeginDate)
							  )
				Begin

						set @ErrorMsgStr = 'ERROR !!! No Destination exists in the reference for record with destination : '+ @VarDestination +
						                   ' and BeginDate : ' + convert(varchar(10) , @VarBeginDate, 120)

						RaisError('%s' , 16,1 , @ErrorMsgStr)

						CLOSE db_Validate_Rate_Records  
						DEALLOCATE db_Validate_Rate_Records

						GOTO ENDPROCESS

				End

		End

		Else
		Begin

				if not exists ( 
								select 1 from tb_Destination 
								where Destination = @VarDestination 
								and	@VarBeginDate between BeginDate and isnull(EndDate, @VarBeginDate)
								and @VarEndDate between BeginDate and isnull(EndDate, @VarEndDate)
							  )
				Begin

						set @ErrorMsgStr = 'ERROR !!! No Destination exists in the reference number plan for record with destination : '+ @VarDestination +
						                   ' and BeginDate : ' + convert(varchar(10) , @VarBeginDate, 120) +
										   ' and EndDte : ' + convert(varchar(10), @VarEndDate,120)

						RaisError('%s' , 16,1 , @ErrorMsgStr)

						CLOSE db_Validate_Rate_Records  
						DEALLOCATE db_Validate_Rate_Records

						GOTO ENDPROCESS

				End

		End

		----------------------------------------------------
		-- If there are multiple records existing for a 
		-- Destination without overlap, then EndDate of one
		-- record should be Start Date of another record

		-- THIS IS TO CHECK FOR ANY RATE GAP
		-----------------------------------------------------

		if ( ( select count(*) from #TempDateOverlapCheck) > 0)
		Begin

				select @MaxEndDate = max(EndDate)
				from Temp_Rate
				where Destination = @VarDestination
				and EndDate is not null

				select @MaxEndDate as MaxEndDate , @VarDestination

				if ( (@VarEndDate is not NULL ) and (@VarEndDate <> @MaxEndDate))
				Begin

						if not exists (Select 1 from #TempDateOverlapCheck where BeginDate = DateAdd(dd , 1 , @VarEndDate) )
						Begin

								set @ErrorMsgStr = 'ERROR !!! There is rate gap for record with destination : '+ @VarDestination +
												   ' and BeginDate : ' + convert(varchar(10) , @VarBeginDate, 120) +
												   ' and EndDate : ' + convert(varchar(10), @VarEndDate,120)

								RaisError('%s' , 16,1 , @ErrorMsgStr)

								CLOSE db_Validate_Rate_Records  
								DEALLOCATE db_Validate_Rate_Records

								GOTO ENDPROCESS


						End

				End

				if (@VarEndDate is NULL)
				Begin

						if not exists (Select 1 from #TempDateOverlapCheck where EndDate = DateAdd(dd , -1 , @VarBeginDate) )
						Begin

								set @ErrorMsgStr = 'ERROR !!! There is rate gap for record with destination : '+ @VarDestination +
												   ' and BeginDate : ' + convert(varchar(10) , @VarBeginDate, 120) 

								RaisError('%s' , 16,1 , @ErrorMsgStr)

								CLOSE db_Validate_Rate_Records  
								DEALLOCATE db_Validate_Rate_Records

								GOTO ENDPROCESS


						End

				End


		End


		FETCH NEXT FROM db_Validate_Rate_Records
		INTO @VarDestination , @VarRecordID , @VarBeginDate ,@VarEndDate 
 
END  

CLOSE db_Validate_Rate_Records  
DEALLOCATE db_Validate_Rate_Records

------------------------------------------------------
-- Open transaction to commit the rate records into
-- reference tables
------------------------------------------------------

Begin Transaction Commit_Rates

Begin Try

    --------------------------------------------------------
	-- Update the end date for old entries in the reference
	-- tables
	--------------------------------------------------------

	if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMaxExistingRec') )
			Drop table #TempMaxExistingRec

	select rt.RateID , rt.DestinationID
	into #TempMaxExistingRec
	from tb_Rate rt
	inner join
	(
		Select max(BeginDate) as MaxBeginDate, DestinationID
		from tb_Rate
		where RatePlanID = @RatePlanID
		group by DestinationID
	) tbl2 on rt.DestinationID = tbl2.DestinationID and rt.BeginDate = tbl2.MaxBeginDate
	Where rt.RatePlanID = @RatePlanID

	--select * from #TempMaxExistingRec

 --   select rt.*, DateAdd(dd , -1 , tbl3.BeginDate) as ProposedEndDate
	--from tb_rate rt
	--inner join #TempMaxExistingRec tbl2 on rt.DestinationID = tbl2.DestinationID and rt.RateID = tbl2.RateID
	--inner join 
	--(
	--	select min(tbl1.BeginDate) as BeginDate , dest.DestinationID
	--	from Temp_Rate tbl1
	--	inner join tb_Destination dest on tbl1.Destination = Dest.Destination
	--	and dest.NumberPlanID = -2
	--	and tbl1.BeginDate between Dest.BeginDate and isnull(Dest.EndDate , tbl1.BeginDate)
	--	and isnull(tbl1.EndDate,tbl1.BeginDate) between  Dest.BeginDate and isnull(Dest.EndDate , isnull(tbl1.EndDate,tbl1.BeginDate))
	--	group by dest.DestinationID
	--) tbl3 on tbl2.DestinationID = tbl3.DestinationID
	--where rt.RatePlanID = @RatePlanID


	update rt
	set EndDate = DateAdd(dd , -1 , tbl3.BeginDate)
	from tb_rate rt
	inner join #TempMaxExistingRec tbl2 on rt.DestinationID = tbl2.DestinationID and rt.RateID = tbl2.RateID
	inner join 
	(
		select min(tbl1.BeginDate) as BeginDate , dest.DestinationID
		from Temp_Rate tbl1
		inner join tb_Destination dest on tbl1.Destination = Dest.Destination
		and dest.NumberPlanID = -2
		and tbl1.BeginDate between Dest.BeginDate and isnull(Dest.EndDate , tbl1.BeginDate)
		and isnull(tbl1.EndDate,tbl1.BeginDate) between  Dest.BeginDate and isnull(Dest.EndDate , isnull(tbl1.EndDate,tbl1.BeginDate))
		group by dest.DestinationID
	) tbl3 on tbl2.DestinationID = tbl3.DestinationID
	where rt.RatePlanID = @RatePlanID


	insert into tb_rate
	(
		RatePlanID ,
		DestinationID,
		CallTypeID ,
		RatingMethodID,
		BeginDate,
		EndDate , 
		ModifiedDate,
		ModifiedByID,
		Flag
	)
	select rp.rateplanid , dest.DestinationID , 1 , -2 , tbl1.BeginDate , tbl1.EndDate , getdate() , -1 , 0
	from tb_rateplan rp
	inner join Temp_Rate tbl1 on tbl1.RatePlanID = rp.RatePlanID
	inner join tb_Destination dest on tbl1.Destination = Dest.Destination
	where rp.Directionid = 1
	and dest.NumberPlanID = -2
	and tbl1.BeginDate between Dest.BeginDate and isnull(Dest.EndDate , tbl1.BeginDate)
	and isnull(tbl1.EndDate,tbl1.BeginDate) between  Dest.BeginDate and isnull(Dest.EndDate , isnull(tbl1.EndDate,tbl1.BeginDate))

	insert into tb_RateDetail
	(
		Rate,
		RateID,
		RateTypeID ,
		ModifiedDate,
		ModifiedByID,
		Flag
	)
	select tbl1.Rate , rt.RateID , 101 , getdate() , -1 , 0
	from tb_rateplan rp
	inner join Temp_Rate tbl1 on tbl1.RatePlanID = rp.RatePlanID
	inner join tb_Destination dest on tbl1.Destination = Dest.Destination
	inner join tb_rate rt on
			rt.DestinationID = dest.DestinationID
			and
			rt.RatePlanId = rp.RatePlanID
			and
			rt.BeginDate = tbl1.BeginDate
	where rp.Directionid = 1
	and dest.NumberPlanID = -2
	and tbl1.BeginDate between Dest.BeginDate and isnull(Dest.EndDate , tbl1.BeginDate)
	and isnull(tbl1.EndDate,tbl1.BeginDate) between  Dest.BeginDate and isnull(Dest.EndDate , isnull(tbl1.EndDate,tbl1.BeginDate))

End Try

Begin Catch 


		set @ErrorMsgStr = 'ERROR !!! Exception during rate commit. ' + ERROR_MESSAGE()

		RaisError('%s' , 16,1 , @ErrorMsgStr)

		Rollback transaction Commit_Rates

		GOTO ENDPROCESS

End Catch

Commit Transaction Commit_Rates


ENDPROCESS:

if exists ( select 1 from sysobjects where name = 'Temp_Rate' and xtype = 'U' )
	Drop table Temp_Rate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateOverlapCheck') )
	Drop table #TempDateOverlapCheck

GO
