USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPGenerateReportLCR_Manual_Nexwave]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPGenerateReportLCR_Manual_Nexwave]
(
	@ReportRunDate Datetime ,
	@MaxReportCount int,
	@RateEntityGroupID int
)

As

--Declare @ReportRunDate date = convert(date , Getdate()),
--        @MaxReportCount int = 10

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
where Dest.NumberPlanID = -1 -- Routing Numberplan
and rtd.RatetypeID = 101 -- Tier 1 rate
and rp.DirectionID = 2 -- Outbound
and rp.ProductCataLogID not in (-1 ,-3 ,-5)
and rp.RatePlanGroupID = isnull(@RateEntityGroupID , rp.RatePlanGroupID)
and @ReportRunDate between rt.BeginDate and isnull(rt.EndDate , @ReportRunDate)

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

-----------------------------------------------------------
-- Drop all the temporary tables post processing of data
-----------------------------------------------------------


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMasterData') )
Drop table #TempMasterData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDistinctRoutingEntity') )
Drop table #TempDistinctRoutingEntity

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRoutingEntityRate') )
Drop table #TempRoutingEntityRate

if exists (select 1 from sysobjects where xtype = 'U' and name = @TableName )
Exec('Drop table ' + @TableName)
GO
