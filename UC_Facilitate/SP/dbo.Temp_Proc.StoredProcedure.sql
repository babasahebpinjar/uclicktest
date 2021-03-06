USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[Temp_Proc]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE [UC_Facilitate]
--GO
--/****** Object:  StoredProcedure [dbo].[Temp_Proc]    Script Date: 7/24/2018 6:45:53 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
CREATE Procedure [dbo].[Temp_Proc] as

if exists ( select 1 from sysobjects where name = 'tb_CDRFileDataAnalyzed' and xtype = 'U')
	Drop table tb_CDRFileDataAnalyzed
	

--- Create a schema to hold the analyzed CDr records
	
select *
into tb_CDRFileDataAnalyzed
from tb_CDRFileData
where calldate between '2018-08-01' and '2018-08-21'


Alter table tb_CDRFileDataAnalyzed Add RecordID int identity(1,1)
Alter table tb_CDRFileDataAnalyzed Add INAccount varchar(100)
Alter table tb_CDRFileDataAnalyzed Add OUTAccount varchar(100)
Alter table tb_CDRFileDataAnalyzed Add Country varchar(100)
Alter table tb_CDRFileDataAnalyzed Add OutCountry varchar(100)
Alter table tb_CDRFileDataAnalyzed Add Destination varchar(100)
Alter table tb_CDRFileDataAnalyzed Add OutDestination varchar(100)
Alter table tb_CDRFileDataAnalyzed Add INRate Decimal(19,6)
Alter table tb_CDRFileDataAnalyzed Add OUTRate Decimal(19,6)
Alter table tb_CDRFileDataAnalyzed Add CallDurationMinutes Decimal(19,4)
Alter table tb_CDRFileDataAnalyzed Add INAmount Decimal(19,4)
Alter table tb_CDRFileDataAnalyzed Add OUTAmount Decimal(19,4)

-- Get the IN and OUT Account Details

update tbl1
set INAccount = isnull( tbl2.Account, 'Not Resolved')
from tb_CDRFileDataAnalyzed tbl1
left join  tb_TrunkToAccountMapping tbl2 on tbl1.INTrunk = tbl2.Trunk

update tbl1
set OUTAccount = isnull( tbl2.Account, 'Not Resolved')
from tb_CDRFileDataAnalyzed tbl1
left join  tb_TrunkToAccountMapping tbl2 on tbl1.OUTTrunk = tbl2.Trunk

-- Hard coding for Celcom Traffic wrong IN trunk

update tb_CDRFileDataAnalyzed 
set INAccount = 'Celcom'
where INTrunk = 'kpgig.celcom.my;user=phone'

--select * from tb_CDRFileDataAnalyzed
--where INAccount = 'Not Resolved'
--or OutAccount = 'Not Resolved'

-- For GIC account, there may be Called numbers with 8080 Code, that needs to be removed

update tb_CDRFileDataAnalyzed
set CalledNumber = 
				Case 
					when substring(CalledNumber ,1,4) = '8080' then substring(callednumber , 5 , len(callednumber))
					Else CalledNumber
				End
Where OutAccount = 'GIC'

-- Populate the Destination based on the Routing Plan and the CalledNumber

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_RoutingBreakout') )
		Drop table #temp_RoutingBreakout

select *
into #temp_RoutingBreakout
from
(
	Select tbl1.DestinationID , tbl1.Destination , tbl1.CountryID,
		   tbl1.DestinationTypeID , tbl1.NumberPlanID, tbl1.BeginDate as DestBeginDate,
		   tbl1.EndDate as DestEndDate , tbl2.DialedDigitsID , tbl2.DialedDigits,
		   tbl2.BeginDate as DDBeginDate , tbl2.EndDate as DDEndDate
	from REFERENCESERVER.UC_Reference.dbo.tb_Destination tbl1
	inner join REFERENCESERVER.UC_Reference.dbo.tb_DialedDigits tbl2
		   on tbl1.DestinationID = tbl2.DestinationID
	where tbl1.Flag & 1 <> 1
	and tbl2.Flag & 1 <> 1
) as TBL1
where TBL1.numberplanid = -1


Declare @MaxLength int,
        @MaxLengthRef int,
        @Counter int = 1,
		@SQLStr varchar(2000),
		@ErrorDEscription varchar(2000)

select @MaxLength = Max(Len(CalledNumber))
from tb_CDRFileDataAnalyzed

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
		from tb_CDRFileDataAnalyzed
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

--select *
--from #temp_CDRCalledNumberBreakout

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

--select top 1000 *
--from #temp_CDRCalledNumberBreakout

---------------------------------------------------------------------
-- Update tb_CDRFileDataAnalyzed with the Destination and Country details
----------------------------------------------------------------------

update tbl1
set tbl1.Destination = tbl2.Destination,
    tbl1.Country = tbl2.Country
from tb_CDRFileDataAnalyzed tbl1
inner join #temp_CDRCalledNumberBreakout tbl2
     on tbl1.RecordID = tbl2.RecordID

update tb_CDRFileDataAnalyzed
set Destination = 'Not Resolved',
    Country = 'Not Resolved'
where Destination is NULL

---------------------------------------------------------------------------
-- Populate the outbound Settlement Destination details in the CDR Records
---------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_SetltlementNPBreakout') )
		Drop table #temp_SetltlementNPBreakout

select tbl1.DestinationID , tbl1.DEstination , tbl1.DEstinationTypeID , 
       tbl1.BeginDate as DEstBeginDate , tbl1.EndDate as DestEndDate,
	   tbl3.DialedDigitsID , tbl3.DialedDigits , tbl3.BeginDate as DDBeginDate,
	   tbl3.EndDate as DDEndDate , tbl3.NumberplanID , tbl1.CountryID , tbl4.Country
into #temp_SetltlementNPBreakout
from REFERENCESERVER.UC_Reference.dbo.tb_destination tbl1
inner join
(
		select distinct tbl5.numberplanid
		from referenceserver.uc_reference.dbo.tb_RatePlan tbl1
		inner join referenceserver.uc_reference.dbo.tb_Agreement tbl2 on tbl1.AgreementID = tbl2.AgreementID
		inner join referenceserver.uc_reference.dbo.tb_Account tbl3 on tbl2.AccountID = tbl3.AccountID
		inner join referenceserver.uc_commerce.dbo.tb_Source tbl4 on tbl1.RatePlanID = tbl4.RatePlanID and tbl4.SourcetypeID = -1
		inner join referenceserver.uc_reference.dbo.tb_numberplan tbl5 on tbl4.SourceID = tbl5.ExternalCode
		inner join (select distinct OutAccount as Account from tb_CDRFileDataAnalyzed) tbl6 on tbl6.Account = tbl3.AccountAbbrv
) tbl2 on tbl1.NumberplanID = tbl2.NumberplanID
inner join REFERENCESERVER.UC_Reference.dbo.tb_dialeddigits tbl3 on
					tbl1.DestinationID = tbl3.DestinationID
inner join REFERENCESERVER.UC_Reference.dbo.tb_Country tbl4 on tbl1.CountryID = tbl4.countryID


set @Counter = 1

select @MaxLength = Max(Len(CalledNumber))
from tb_CDRFileDataAnalyzed

select @MaxLengthRef = Max(Len(DialedDigits))
from #temp_SetltlementNPBreakout

set @MaxLength = 
    Case
			when @MaxLength <= @MaxLengthRef then @MaxLength
			when @MaxLength > @MaxLengthRef then @MaxLengthRef
	End


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRCalledNumberBreakoutSettlement') )
		Drop table #temp_CDRCalledNumberBreakoutSettlement

Begin Try

		Create table #temp_CDRCalledNumberBreakoutSettlement
		(
			RecordID int,
			CalledNumber varchar(100),
			CallDate datetime,
			Numberplanid int,
			Destination varchar(100),
			Country varchar(100)
		)

		while ( @Counter <= @MaxLength )
		Begin

				set @SQLStr = 'Alter table #temp_CDRCalledNumberBreakoutSettlement add CalledNumber_'+convert(varchar(10) ,@Counter) + ' varchar(100)'
		
				Exec (@SQLStr)

				set @Counter = @Counter + 1

		End

		---------------------------------------------------------------------
		-- Insert records into the temp table for each of the CDR records
		---------------------------------------------------------------------

		insert into #temp_CDRCalledNumberBreakoutSettlement
		(RecordID , CalledNumber , CallDate , numberplanid)
		select tbl6.RecordID , tbl6.CalledNumber , tbl6.CallDate ,tbl5.numberplanid 
		from referenceserver.uc_reference.dbo.tb_RatePlan tbl1
		inner join referenceserver.uc_reference.dbo.tb_Agreement tbl2 on tbl1.AgreementID = tbl2.AgreementID
		inner join referenceserver.uc_reference.dbo.tb_Account tbl3 on tbl2.AccountID = tbl3.AccountID
		inner join referenceserver.uc_commerce.dbo.tb_Source tbl4 on tbl1.RatePlanID = tbl4.RatePlanID and tbl4.SourcetypeID = -1
		inner join referenceserver.uc_reference.dbo.tb_numberplan tbl5 on tbl4.SourceID = tbl5.ExternalCode
		inner join tb_CDRFileDataAnalyzed tbl6 on tbl6.OutAccount = tbl3.AccountAbbrv



		set @Counter = 1
		set @SQLStr = 'Update #temp_CDRCalledNumberBreakoutSettlement set ' + char(10)

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

		set @ErrorDescription = 'ERROR !!!! During populating break out table for Settlement Destination resolution. ' + ERROR_MESSAGE()
		RaisError( '%s' , 16,1 , @ErrorDescription)
		GOTO ENDPROCESS

End Catch

--select *
--from #temp_CDRCalledNumberBreakout

-----------------------------------------------------------------------
-- Update the settlement Destination and settlement Country in the
-- temporary table
------------------------------------------------------------------------
Begin Try

		set @Counter = @MaxLength

		While ( @Counter > 0 )
		Begin

				set @SQLStr = 'update tbl1 ' + char(10) +
				              ' set tbl1.Destination  = tbl2.Destination ,' + char(10) +
							  ' tbl1.Country = tbl2.Country ' + char(10) +
							  ' from #temp_CDRCalledNumberBreakoutSettlement tbl1 ' + char(10) +
							  ' inner join #temp_SetltlementNPBreakout tbl2 on ' + char(10) +
							  ' tbl1.CalledNumber_'+ convert(varchar(30) , @Counter) + ' = tbl2.DialedDigits '+ char(10) +
							  ' where tbl1.Destination is NULL' + char(10) +
							  ' and tbl1.numberplanID = tbl2.numberplanID ' + char(10)+
							  ' and tbl1.CallDate between tbl2.DDBeginDate and isnull(tbl2.DDEndDate , tbl1.CallDate)'+ char(10) +
							  ' and tbl1.CallDate between tbl2.DestBeginDate and isnull(tbl2.DestEndDate , tbl1.CallDate)'


				--print @SQLStr
							  
				Exec (@SQLStr)			   
					  
				set @Counter = @Counter - 1			  		

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! When updating the settlement Destination and country details in Temporary table. ' + ERROR_MESSAGE()
		RaisError('%s' , 16,1 ,@ErrorDescription)
		GOTO ENDPROCESS

End Catch

---------------------------------------------------------------------------------
-- Update tb_CDRFileDataAnalyzed with the OUTDestination and OUTCountry details
---------------------------------------------------------------------------------

update tbl1
set tbl1.OutDestination = tbl2.Destination,
    tbl1.OutCountry = tbl2.Country
from tb_CDRFileDataAnalyzed tbl1
inner join #temp_CDRCalledNumberBreakoutSettlement tbl2
     on tbl1.RecordID = tbl2.RecordID

update tb_CDRFileDataAnalyzed
set OutDestination = 'Not Resolved',
    OutCountry = 'Not Resolved'
where OutDestination is NULL

-----------------------------------------------------------
-- Populate the CallDurationMinutes based on Call Duration
-----------------------------------------------------------

update tb_CDRFileDataAnalyzed
set CallDurationMinutes = convert(Decimal(19,4) , CallDuration/60.0)

--------------------------------------------------------------------
-- Build the Tb_Rate table for all the Inbound and Outbound rates
--------------------------------------------------------------------

if exists (select 1 from sysobjects where name = 'tb_rate' and xtype = 'U')
	Drop table tb_Rate

select * 
into tb_rate 
from
(	
	select tbl3.AccountAbbrv as Account , tbl8.Destination , tbl7.Rate, tbl6.BeginDate , tbl6.EndDate,
		   'Outbound' as Direction
	from referenceserver.uc_reference.dbo.tb_RatePlan tbl1
	inner join referenceserver.uc_reference.dbo.tb_Agreement tbl2 on tbl1.AgreementID = tbl2.AgreementID
	inner join referenceserver.uc_reference.dbo.tb_Account tbl3 on tbl2.AccountID = tbl3.AccountID
	inner join referenceserver.uc_commerce.dbo.tb_Source tbl4 on tbl1.RatePlanID = tbl4.RatePlanID and tbl4.SourcetypeID = -1
	inner join referenceserver.uc_reference.dbo.tb_numberplan tbl5 on tbl4.SourceID = tbl5.ExternalCode
	inner join referenceserver.uc_reference.dbo.tb_Rate tbl6 on tbl1.RatePlanID = tbl6.RatePlanID
	inner join referenceserver.uc_reference.dbo.tb_RateDetail tbl7 on tbl6.RateID = tbl7.RateID
	inner join referenceserver.uc_reference.dbo.tb_Destination tbl8 on tbl6.DestinationID = tbl8.DestinationID
	where tbl8.numberplanid <> -1
	union
	select tbl3.AccountAbbrv as Acocunt , tbl6.Destination, tbl5.Rate , tbl4.BeginDate , tbl4.EndDate , 'Inbound' as Direction
	from referenceserver.uc_reference.dbo.tb_RatePlan tbl1
	inner join referenceserver.uc_reference.dbo.tb_Agreement tbl2 on tbl1.AgreementID = tbl2.AgreementID
	inner join referenceserver.uc_reference.dbo.tb_Account tbl3 on tbl2.AccountID = tbl3.AccountID
	inner join referenceserver.uc_reference.dbo.tb_Rate tbl4 on tbl1.RatePlanId = tbl4.RatePlanID
	inner join referenceserver.uc_reference.dbo.tb_RateDetail tbl5 on tbl4.RateID = tbl5.RateID
	inner join referenceserver.uc_reference.dbo.tb_Destination tbl6 on tbl4.DestinationID = tbl6.DestinationID
	where tbl1.DirectionID = 1
) as TBL1	 

--------------------------------------------------------------
-- Populate the rates from the rate table for all the records
--------------------------------------------------------------

update tbl1
set tbl1.INRate = tbl2.Rate,
	tbl1.INAmount = tbl1.CallDurationMinutes * tbl2.Rate
from tb_CDRFileDataAnalyzed tbl1
inner join tb_Rate tbl2 on
			tbl1.INAccount = tbl2.Account
			and
			tbl1.Destination = tbl2.Destination
			and
			tbl2.Direction = 'Inbound'
			and 
			tbl1.CallDate between tbl2.BeginDate and ISNULL(tbl2.EndDate , tbl1.CallDate)

update tbl1
set tbl1.OUTRate = tbl2.Rate,
	tbl1.OUTAmount = tbl1.CallDurationMinutes * tbl2.Rate
from tb_CDRFileDataAnalyzed tbl1
inner join tb_Rate tbl2 on
			tbl1.OutAccount = tbl2.Account
			and
			tbl1.OutDestination = tbl2.Destination
			and
			tbl2.Direction = 'Outbound'
			and 
			tbl1.CallDate between tbl2.BeginDate and ISNULL(tbl2.EndDate , tbl1.CallDate)

select distinct INAccount , Destination
from tb_CDRFileDataAnalyzed

select distinct OUTAccount , Destination
from tb_CDRFileDataAnalyzed

Select *
from tb_CDRFileDataAnalyzed
where callduration > 0
and ( INAmount is NULL or OUTAmount is NULL )

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRCalledNumberBreakout') )
		Drop table #temp_CDRCalledNumberBreakout

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_RoutingBreakout') )
		Drop table #temp_RoutingBreakout

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_SetltlementNPBreakout') )
		Drop table #temp_SetltlementNPBreakout

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_CDRCalledNumberBreakoutSettlement') )
		Drop table #temp_CDRCalledNumberBreakoutSettlement






GO
