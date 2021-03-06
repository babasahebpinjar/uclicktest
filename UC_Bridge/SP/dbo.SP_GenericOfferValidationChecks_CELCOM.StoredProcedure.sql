USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_GenericOfferValidationChecks_CELCOM]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_GenericOfferValidationChecks_CELCOM]
(
    @VendorOfferID int,
    @LogFileName varchar(500),
    @UserID int,
    @ResultFlag int output,
    @ErrorDescription varchar(2000) output
)
--With Encryption
As 


set @ResultFlag = 0
set @ErrorDescription = NULL

-----------------------
-- Declare Variables
-----------------------

Declare @ErrorMsgStr varchar(2000),
        @OfferDate datetime ,

        @SourceID int , 
        @RatePlanID int,
        @NumberPlanID int,
        @ServiceID int,
		@OfferContent varchar(20),
		@OfferContentID int,
		@ProcessOfferContentType varchar(20),
		@PartialOfferProcessFlag int,
		@SkipRateIncreaseCheck int,
		@ReferenceID int,
		@OfferUpdateStatus varchar(100),
		@ProcessOfferContentTypeID int,
		@RateIncreasePeriodRefLevel int,
		@CheckNewDestination int

Declare @TotalDestinations int,
        @TotalDialedDigits int,
	@TotalRecords int

set @PartialOfferProcessFlag = 0

----------------------------------------------------
-- Get all the essential parameters for the offer
-- from the reference and vendor offer tables
----------------------------------------------------

select @OfferDate = offdet.offerreceivedate ,
       @SourceID = refdet.VendorSourceid,
       @RatePlanID = src.RatePlanid ,
       @NumberPlanID = np.numberplanid,
       @ServiceID = src.callTypeID,
       @OfferContent = offdet.offertype,
	   @OfferContentID = offdet.offertypeID,
       @SkipRateIncreaseCheck = refdet.SkipRateIncreaseCheck,
	   @RateIncreasePeriodRefLevel = refdet.RateIncreasePeriod,
       @CheckNewDestination =  refdet.CheckNewDestination,
	   @ReferenceID = offdet.ReferenceID
from TB_VendorOfferDetails offdet
inner join tb_VendorReferenceDetails refdet on offdet.Referenceid = refdet.ReferenceID
inner join vw_Vendorsource src on refdet.VendorSourceid = src.sourceid
left join vw_numberplan np on np.ExternalCode = src.sourceid -- Could be a case where the offer is being loaded for the very first time
where offdet.VendorOfferID = @VendorOfferID


set @ProcessOfferContentType = @OfferContent

----------------------------------------------------
-- Add an Entry into the Log File indicating that
-- Generic Validation Checks are being Run
----------------------------------------------------

Exec SP_LogMessage NULL , @LogFileName
set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '****************** GENERIC VALIDATION CHECKS *****************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @LogFileName


-------------------------------------------------------------------
-- Mark Error Code for all the records, where the Effective Date 
-- value is not correct and equals 12/31/1899
-------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has invalid value for Effective Date',
    tbl1.ErrorCode = '4010'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.EffectiveDate = '12/31/1899'

-----------------------------------------
-- CHECK 1 : DialCode is not numeric
-----------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'DialCode  : '  + tbl1.DialedDigit + ' is not a numeric value',
    tbl1.ErrorCode = '3010'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and
(
   ISNUMERIC(tbl1.DialedDigit) = 0
   or
   charindex('.' , convert(varchar(20) ,tbl1.DialedDigit) ) <> 0
)


-------------------------------------------------------
-- CHECK 2 : DialCode length greater than 15 characters
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'DialCode  : '  + tbl1.DialedDigit + ' length greater than 15 characters',
    tbl1.ErrorCode = '3020'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and ISNUMERIC(tbl1.DialedDigit) = 1
and LEN(tbl1.DialedDigit) > 15

---------------------------------------------------------
-- CHECK 3 : Destination name should be less than the
-- configured length
---------------------------------------------------------

Declare @DestinationNameLength int

select @DestinationNameLength = isnull(convert(int , ConfigValue) , 999)
from tb_config
where configname = 'DestinationNameLength'

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : (' + tbl1.Destination + ') has length greater than ' + convert(varchar(20) , @DestinationNameLength) + ' characters' ,
    tbl1.ErrorCode = '1070'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and len(tbl1.Destination) > @DestinationNameLength

---------------------------------------------------------
-- CHECK 4 : New Destination has no Dial Codes associated.
---------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'New Destination : ' + tbl1.Destination + ' has no associated Dial Codes',
    tbl1.ErrorCode = '1030'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is null
and tbl1.destination not in
(
   select distinct destination
   from vw_destination
   where numberplanID = @NumberPlanID
   and enddate is null
)


--------------------------------------------------------------------
-- CHECK 5 : Destination With no associated dial codes or rates
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has no associated Dial Codes or Rates',
    tbl1.ErrorCode = '1040'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is null
and
(
   isnumeric(isnull(tbl1.Rate , 'No Rates')) = 0 
   or
   charindex(',' , convert(varchar(25) ,tbl1.Rate) ) <> 0
 )


--------------------------------------------------------------------
-- CHECK 6 : Destination With associated dial codes but no rates
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has  associated Dial Codes but no Rates',
    tbl1.ErrorCode = '1060'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and
(
   isnumeric(isnull(tbl1.Rate , 'No Rates')) = 0 
   or
   charindex(',' , convert(varchar(25) ,tbl1.Rate) ) <> 0
 )



--------------------------------------------------------------------
-- CHECK 7 : Destination With associated rates but no dial codes
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has  associated Rates but no Dial Codes',
    tbl1.ErrorCode = '1050'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is null
and isnumeric(isnull(tbl1.Rate , 'No Rates')) = 1


--------------------------------------------------------
-- CHECK 8 : More than one entry for the combination of 
-- 1. Destination
-- 2. Effective Date
-- 3. Dialed Digit
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Multiple Entries exist for Destination : ' + tbl1.Destination + '  EffectiveDate : '+ CONVERT(varchar(10), tbl1.EffectiveDate, 120 ) +' and DialedDigit : ' + tbl1.DialedDigit,
    tbl1.ErrorCode = '1010'
from  #TempVendorOfferData tbl1
inner join
(  
	Select COUNT(*) as TotalRecords, Destination , EffectiveDate , DialedDigit , RatingMethod , RateBand
	from #TempVendorOfferData
	where ErrorMessage is NULL
	group by Destination , EffectiveDate , DialedDigit , RatingMethod , RateBand
	Having COUNT(1) > 1
) tbl2
on tbl1.destination = tbl2.destination
and tbl1.EffectiveDate = tbl2.EffectiveDate
and tbl1.DialedDigit = tbl2.DialedDigit
and tbl1.RatingMethod = tbl2.RatingMethod
and tbl1.RateBand = tbl2.RateBand
where tbl1.ErrorMessage is NULL


--------------------------------------------------------
-- CHECK 9 : Duplicate Dial code for same effective date
-- across different destinations.
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Duplicate Dial Code : ' + tbl1.DialedDigit + ' for Effective Date :' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ),
    tbl1.ErrorCode = '3040'
from  #TempVendorOfferData tbl1
inner join
(  
	Select COUNT(*) as TotalRecords, count(Distinct Destination) as TotalDestinations ,EffectiveDate , DialedDigit
	from #TempVendorOfferData
	where ErrorMessage is NULL
	group by  EffectiveDate , DialedDigit
	Having COUNT(1) > 1
) tbl2
on tbl1.EffectiveDate = tbl2.EffectiveDate
and tbl1.DialedDigit = tbl2.DialedDigit
where tbl1.ErrorMessage is NULL
and tbl2.TotalDestinations > 1


--------------------------------------------------------
-- CHECK 10 : Multiple rates for the same destination and 
-- Effective date.
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Multiple rates for Destination : ' + tbl1.Destination + ' and  Effective Date :' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ),
    tbl1.ErrorCode = '2010'
from  #TempVendorOfferData tbl1
inner join
(
	select count(*) as TotalRecords , Destination , EffectiveDate , RateTypeID
	from
	(
		select distinct Destination , Effectivedate , Rate , RateTypeID
		from #TempVendorOfferData
		where ErrorMessage is NULL
	) as tbl
	Group by Destination , EffectiveDate , RateTypeID
	having count(1) > 1
)tbl2
on tbl1.EffectiveDate = tbl2.EffectiveDate
and tbl1.Destination = tbl2.Destination
and tbl1.RatetypeID = tbl2.RateTypeID
where tbl1.ErrorMessage is NULL



-------------------------------------------------------
-- CHECK 11 : Check for record Items which have the 
-- country code as NOT EXIST
------------------------------------------------------

Declare @ListOfCountriesToSkip varchar(1000),
        @CountryCode varchar(15),
	@VarSkipCountryCode varchar(10)

select @ListOfCountriesToSkip = ConfigValue
from tb_config
where configname = 'SkipCountryCodes'

--select LEN(@ListOfCountriesToSkip)

create table #TempSkipCountryCodes ( CountryCode varchar(15) )

while ( charindex('|' , @ListOfCountriesToSkip ) <> 0)
Begin

	set @CountryCode = substring( @ListOfCountriesToSkip , 1 , charindex('|' , @ListOfCountriesToSkip ) - 1 )

	if ( isnumeric(@CountryCode) = 1 )
	Begin

		insert into #TempSkipCountryCodes values (@CountryCode)

	End

	set @ListOfCountriesToSkip = substring( @ListOfCountriesToSkip , charindex('|' , @ListOfCountriesToSkip ) + 1 , Len(@ListOfCountriesToSkip) )

End

set @CountryCode = substring( @ListOfCountriesToSkip , 1 , Len(@ListOfCountriesToSkip) )

if ( isnumeric(@CountryCode) = 1 )
Begin

	insert into #TempSkipCountryCodes values (@CountryCode)

End

Declare Update_SkipCountryCode_Cur Cursor For
select countrycode
from #TempSkipCountryCodes
order by len(countrycode) desc

Open Update_SkipCountryCode_Cur
Fetch Next From Update_SkipCountryCode_Cur
Into @VarSkipCountryCode

While @@FETCH_STATUS = 0
Begin

	update tbl1
	set tbl1.ErrorMessage  = 
	   'Destination : ' + tbl1.Destination +' has been removed because of skip rule on Country Code : ' + @VarSkipCountryCode ,
	    tbl1.ErrorCode = '9999' 
	from #TempVendorOfferData tbl1
	where tbl1.ErrorMessage is NULL
	and tbl1.CountryCode = @VarSkipCountryCode
	 
	Fetch Next From Update_SkipCountryCode_Cur
	Into @VarSkipCountryCode

End

Close Update_SkipCountryCode_Cur
Deallocate Update_SkipCountryCode_Cur


update tbl1
set tbl1.ErrorMessage  = 
   'Country Code cannot be resolved for Destination : '+ Destination +' and DialedDigit : ' + tbl1.DialedDigit + ' and  Effective Date :' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ) ,
    tbl1.ErrorCode = '5020' 
from #TempVendorOfferData tbl1
where tbl1.ErrorMessage is NULL
and tbl1.CountryCode = 'NOT EXIST'

drop table #TempSkipCountryCodes

------------------------------------------------
-- CHECK 12 : Multiple Country Codes for the
-- Same Destination.
--------------------------------------------------------------------
-- Multiple Code Scenarios would be:
-- 1. Two Different country codes belonging to no group
-- 2. Two Different country codes belonging to two different groups
-- 3. Two different country codes one belonging to group, other to no group
---------------------------------------------------------------------

------------------------
-- Handle Condition 1
------------------------

update tbl1
set tbl1.ErrorMessage ='Multiple Country Code : ' + tbl1.CountryCode + ' for Destination :' + tbl1.Destination,
    tbl1.ErrorCode = '1020'
from  #TempVendorOfferData tbl1
inner join
(
	select destination , groupid , COUNT(*) as TotalCountryCode
	from
	(
		select distinct tbl1.destination , tbl1.countrycode , ISNULL(tbl2.GroupID , 99999) as GroupId
		from #TempVendorOfferData tbl1
		left join vw_countryGroupXRef tbl2 on tbl1.countrycode = tbl2.countrycode
		where tbl1.errormessage is null
	) as tbl
	group by destination , groupid
	having COUNT(3) > 1
) as tbl2
on tbl1.destination = tbl2.destination
where tbl1.ErrorMessage is NULL
and tbl2.groupid = 99999

-----------------------------
-- Handle Condition 2 and 3
-----------------------------

update tbl1
set tbl1.ErrorMessage ='Multiple Country Code : ' + tbl1.CountryCode + ' for Destination :' + tbl1.Destination,
    tbl1.ErrorCode = '1020'
from  #TempVendorOfferData tbl1
inner join
(
	select destination , count(*) as TotalGroup
	from
	(
		select distinct tbl1.destination  , ISNULL(tbl2.GroupID , 99999) as GroupId
		from #TempVendorOfferData tbl1
		left join vw_countryGroupXRef tbl2 on tbl1.countrycode = tbl2.countrycode
		where tbl1.errormessage is null
	) as tbl
	group by destination
	having COUNT(2) > 1
) as tbl2
on tbl1.destination = tbl2.destination
where tbl1.ErrorMessage is NULL


--------------------------------------------------
-- CHECK 13 : Effective Date greater than allowed
-- limit
--------------------------------------------------

Declare @EffectiveDateFutureDays int

select @EffectiveDateFutureDays = convert(int , ConfigValue) 
from tb_config
where configname = 'EffectiveDateFutureDays'

set @EffectiveDateFutureDays = isnull(@EffectiveDateFutureDays , 999)

update tbl1
set tbl1.ErrorMessage ='Effective Date  : ' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ) + ' for Destination :' + tbl1.Destination + ' greater than : '+ convert(varchar(10) , @EffectiveDateFutureDays) + ' days',
    tbl1.ErrorCode = '4012'
from  #TempVendorOfferData tbl1
where tbl1.ErrorMessage is NULL 
and tbl1.Effectivedate > dateadd(dd , @EffectiveDateFutureDays , @OfferDate)  

--------------------------------------------------
-- CHECK 14 : Rate Increase Notice Violation
--------------------------------------------------
--  AND
---------------------------------------------------------------------
-- CHECK 15 : New Destination being provided for future or back date
---------------------------------------------------------------------

Declare @RateIncreasePeriod int,
		@RateIncreasePeriodSysLevel int,
		@RateIncreaseViolationFlag int,
	    @CheckNewDestinationFlag int 

set @RateIncreaseViolationFlag = 1
set @CheckNewDestinationFlag = 1

		
select @RateIncreasePeriodSysLevel = convert(int , ConfigValue) 
from tb_config
where configname = 'RateIncreasePeriod'

set @RateIncreasePeriodSysLevel = isnull(@RateIncreasePeriodSysLevel , 0)

-----------------------------------------------------
-- Establish whether to use the reference level or
-- system level Rate Increase Period
-----------------------------------------------------

if (@RateIncreasePeriodRefLevel is not NULL)
Begin

	set @RateIncreasePeriod = @RateIncreasePeriodRefLevel

End

Else
Begin

	set @RateIncreasePeriod = @RateIncreasePeriodSysLevel

End

select Distinct dest.Destination , dest.destinationid , 
       rd.rate as ExistingRate , rt.BeginDate as ExistingRateBeginDate, 
       rt.EndDate as ExistingRateEndDate, rt.RatingMethodID , rd.RateTypeID
into #tempAllExistingRates        
from
(
	select distinct destination , EffectiveDate , Rate , RatetypeID
	from #TempVendorOfferData
	where ErrorMessage is NULL
) as tbl1
inner join vw_destination dest on tbl1.Destination = dest.Destination and dest.NumberPlanID = @NumberPlanID
inner join vw_rate rt on dest.destinationID = rt.DestinationID and rt.CalltypeID = @ServiceID
inner join vw_ratedetail rd on rt.rateid = rd.rateid and tbl1.RateTypeID = rd.ratetypeID
where rt.rateplanid = @RatePlanID
and tbl1.EffectiveDate between rt.begindate and isnull(rt.enddate , tbl1.EffectiveDate)


if ( isnull(@SkipRateIncreaseCheck,0) <> 1 )
Begin

     ---------------------
	 -- Debugging Purpose
	 ---------------------
        --select @OfferDate as OfferDate ,datediff(dd , @OfferDate ,  tbl1.EffectiveDate ) ,  tbl1.*
		--from #TempVendorOfferData tbl1
		--inner join #tempAllExistingRates tbl2 on tbl1.Destination = tbl2.destination and tbl1.ratetypeID = tbl2.rateTypeID
		--where ErrorMessage is NULL
		--and
		--(
		--	( tbl1.Rate > ExistingRate )
		--	and
		--	 ( datediff(dd , @OfferDate ,  tbl1.EffectiveDate ) < @RateIncreasePeriod )
		--)

		update tbl1
		set tbl1.ErrorMessage = 
		   Case
			 When ( tbl1.Rate > ExistingRate ) Then
					Case
						When ( datediff(dd , @OfferDate ,  tbl1.EffectiveDate ) < @RateIncreasePeriod ) then
						    'Rate increased prior to notice period of : ' + convert(varchar(10) , @RateIncreasePeriod) + ' days from : ' + convert(varchar(20) , ExistingRate) + ' to : ' + convert(varchar(20) , tbl1.Rate) + ' for destination : ( '+ tbl1.destination + ' ) Effective Date : ' + convert(varchar(10) , tbl1.EffectiveDate , 120)	+ ' and Time Band : ' + tbl1.RateBand						
						Else NULL
						
					End
			 Else NULL
		   End,
		tbl1.ErrorCode =
		   Case
			 When ( tbl1.Rate > ExistingRate ) Then
					Case
						When ( datediff(dd , @OfferDate ,  tbl1.EffectiveDate ) < @RateIncreasePeriod ) then '2020'
						Else NULL
						
					End
			 Else NULL
		   End
		from #TempVendorOfferData tbl1
		inner join #tempAllExistingRates tbl2 on tbl1.Destination = tbl2.destination and tbl1.ratetypeID = tbl2.rateTypeID
		where ErrorMessage is NULL

End

Else
Begin

	set @RateIncreaseViolationFlag = 0

End

---------------
-- CHECK 15
---------------

if ( isnull(@CheckNewDestination , 0) = 1 )
Begin

		update tbl1
		set tbl1.ErrorMessage = 
		   Case
			 When ( datediff(dd , @OfferDate ,  tbl1.EffectiveDate ) < @RateIncreasePeriod ) Then 
					Case
						When  @OfferDate  >  tbl1.EffectiveDate then
							'New Destination : (' + tbl1.Destination + ') is being introduced on back date of : ( '+ CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ) + ')'
						When  @OfferDate  <=  tbl1.EffectiveDate then
							'New Destination : (' + tbl1.Destination + ') is being introduced on date : ( '+ CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ) + ') violating the notice period of ' + convert(varchar(10) , @RateIncreasePeriod) + ' days'
							
						Else NULL
						
					End
			 Else NULL
		   End,
		tbl1.ErrorCode =

		   Case
			 When ( datediff(dd , @OfferDate ,   tbl1.EffectiveDate ) < @RateIncreasePeriod ) Then 
					Case
						When  @OfferDate  >  tbl1.EffectiveDate then '2030'				        
						When  @OfferDate  <=  tbl1.EffectiveDate then '2040'		       
						Else NULL
						
					End
			 Else NULL
		   End
		from #TempVendorOfferData tbl1
		left join #tempAllExistingRates tbl2 on tbl1.Destination = tbl2.Destination and tbl1.RateTypeID = tbl2.RateTypeID
		where ErrorMessage is NULL
		and tbl2.Destination is NULL

End

Else
Begin

	set @CheckNewDestinationFlag = 0

End


Drop table #tempAllExistingRates

-------------------------------------------------------------------
-- Print the various error messages to the Log File for tracking
-- purpose.
-------------------------------------------------------------------



-----------------------------------------------------------------
-- Make sure to print in the log if essential checks for rate 
-- increase or new destination have ben switched off for this 
-- offer
-----------------------------------------------------------------

if ( @RateIncreaseViolationFlag = 0 )
Begin
	set @ErrorMsgStr = '	CHECK DISABLED ALERT : Rate Increase Violation check was switched off for this offer' 
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
End

if ( @CheckNewDestinationFlag = 0 )
Begin
	set @ErrorMsgStr = '	CHECK DISABLED ALERT : Check for New Destination was switched off for this offer'
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
End


Exec SP_LogMessage NULL, @LogFileName



set @ErrorMsgStr = '	*******************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	EXCEPTION/SKIP RULE SECTION :- '
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	********************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName



Declare @VarErrorMessage varchar(2000),
        @VarErrorCode varchar(20),
		@PrevErrorCode varchar(20)

set @PrevErrorCode = ''

Declare Log_Error_Messages_Cur Cursor For
Select distinct ErrorMessage , ErrorCode
from #TempVendorOfferData
where ErrorMessage is not NULL
order by ErrorCode

Open Log_Error_Messages_Cur
Fetch Next From Log_Error_Messages_Cur
Into @VarErrorMessage, @VarErrorCode


While @@FETCH_STATUS = 0
Begin

     ---------------------------------------
	 -- Add some formatting to the log file
	 ---------------------------------------

     if ( ( @VarErrorCode <> @PrevErrorCode ) )
	 Begin

	 		if ( @PrevErrorCode <> '' )
			Begin

				Exec SP_LogMessage NULL, @LogFileName
			End

			set @PrevErrorCode = @VarErrorCode

	 End

	if ( @VarErrorCode = '9999' )
	Begin
		set @ErrorMsgStr = '	SKIP RULE : ' + @VarErrorMessage
	End

	Else
	Begin

		set @ErrorMsgStr = '	ERROR : ' + @VarErrorMessage

	End
	
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName

	Fetch Next From Log_Error_Messages_Cur
	Into @VarErrorMessage, @VarErrorCode

End

Close Log_Error_Messages_Cur
Deallocate Log_Error_Messages_Cur

delete from #TempVendorOfferData
where ErrorCode = '9999'

-----------------------------------------------------
-- Take the essential action as per the error codes
-----------------------------------------------------

Exec SP_LogMessage NULL, @LogFileName

set @ErrorMsgStr = '	*****************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	ACTION TAKEN :- '
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	******************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

------------------
-- REJECT COUNTRY
------------------

if exists ( 
		select 1 
		from #TempVendorOfferData
		where ErrorCode in ('1010' , '1020' , '2020' , '3010' , '3020' , '4012' , '2010' , '3040' , '4010' , '1070', '2030' , '2040')
	   )
Begin

        set @PartialOfferProcessFlag = 1

	Declare @VarCountryCode varchar(10),
	        @VarCountryName varchar(60)

	Declare Reject_Country_Cur Cursor For
	Select distinct CountryCode
	from #TempVendorOfferData
	where ErrorCode in ('1010' , '1020' , '2020' , '3010' , '3020' , '4012' , '2010' , '3040' , '4010' , '1070' ,  '2030' , '2040')

	Open Reject_Country_Cur
	Fetch Next From Reject_Country_Cur
	Into @VarCountryCode

	While @@FETCH_STATUS = 0
	Begin

	    Select @VarCountryName = Country
		from vw_country
		where 
			Case 
				When charindex( (','+ @VarCountryCode + ',') ,CountryCode) <> 0 then substring( CountryCode , charindex( (','+ @VarCountryCode + ',') ,CountryCode) +1 , len(@VarCountryCode))
					when charindex( (@VarCountryCode + ',') ,CountryCode) <> 0 then substring( CountryCode , 1 , len(@VarCountryCode))
					When charindex( (','+ @VarCountryCode) ,CountryCode) <> 0 then substring( CountryCode , charindex( (','+ @VarCountryCode) ,CountryCode) +1 , len(@VarCountryCode))
				Else CountryCode
			End = @VarCountryCode



		set @ErrorMsgStr = '	Rejected Country : ' + @VarCountryName + ' with Code : ' + @VarCountryCode +' from vendor offer'
		Exec SP_LogMessage @ErrorMsgStr , @LogFileName
		
		delete from #TempVendorOfferData
		where CountryCode = @VarCountryCode

		Fetch Next From Reject_Country_Cur
		Into @VarCountryCode

	End

	Close Reject_Country_Cur
	Deallocate Reject_Country_Cur

	set @ProcessOfferContentType = 
	       Case
	            When @OfferContent = 'AZ' then 'FC'
				When @OfferContent = 'PR' then 'PR'
				When @OfferContent = 'FC' then 'FC'
	       End

End

------------------------
-- REJECT DESTINATIONS
------------------------

if exists ( 
		select 1 
		from #TempVendorOfferData
		where ErrorCode in ('1030' , '1040' , '1050' , '1060' , '5020' )
	   )
Begin

        set @PartialOfferProcessFlag = 1

	Declare @VarDestinationName varchar(60),
	        @VarDistinctErrorCode varchar(20),
		    @VarRejectCountryCode varchar(10),
			@VarRejectCountryName varchar(60)

	set @ProcessOfferContentType = 
	       Case
	            When @OfferContent = 'AZ' then 'FC'
				When @OfferContent = 'PR' then 'PR'
				When @OfferContent = 'FC' then 'FC'
	       End

	select distinct destination , ErrorCode , CountryCode
	from #TempVendorOfferData
	where ErrorCode in ('1030' , '1040' , '1050' , '1060' , '5020' )

	Declare Reject_Destination_Cur Cursor For
	Select distinct destination , ErrorCode , CountryCode
	from #TempVendorOfferData
	where ErrorCode in ('1030' , '1040' , '1050' , '1060' , '5020' )

	Open Reject_Destination_Cur
	Fetch Next From Reject_Destination_Cur
	Into @VarDestinationName, @VarDistinctErrorCode, @VarRejectCountryCode

	While @@FETCH_STATUS = 0
	Begin

		if ( @OfferContent in ('AZ' , 'FC' ))
		Begin

            if ( (@VarDistinctErrorCode = '5020') or (@VarRejectCountryCode = 'NOT EXIST'))
			Begin

				set @ErrorMsgStr = '	Rejected Destination : ' + @VarDestinationName +' from vendor offer'
				Exec SP_LogMessage @ErrorMsgStr , @LogFileName

				delete from #TempVendorOfferData
				where destination = @VarDestinationName

			End

			Else
			Begin

				Select @VarRejectCountryName = Country
				from vw_country
				where countrycode = @VarRejectCountryCode

				set @ErrorMsgStr = '	Rejected Country : ' + @VarRejectCountryName + ' with Code : ' + @VarRejectCountryCode +' from vendor offer'
				Exec SP_LogMessage @ErrorMsgStr , @LogFileName

					
				delete from #TempVendorOfferData
				where CountryCode = @VarRejectCountryCode

			End

		End

		if ( @OfferContent = 'PR')
		Begin

			set @ErrorMsgStr = '	Rejected Destination : ' + @VarDestinationName +' from vendor offer'
			Exec SP_LogMessage @ErrorMsgStr , @LogFileName

			delete from #TempVendorOfferData
			where destination = @VarDestinationName

		End

		Fetch Next From Reject_Destination_Cur
		Into @VarDestinationName, @VarDistinctErrorCode , @VarRejectCountryCode

	End

	Close Reject_Destination_Cur
	Deallocate Reject_Destination_Cur


End

--------------------------------------------
-- Print Message regarding how the offer
-- is going to be processed by the system
-------------------------------------------

set @ErrorMsgStr = '	********************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	NOTE : Offer will be processed as : ' +
            Case
				When @ProcessOfferContentType = 'AZ' then 'A-Z'
				When @ProcessOfferContentType = 'FC' then 'FULL COUNTRY'
				when @ProcessOfferContentType = 'PR' then 'PARTIAL'
			End

Exec SP_LogMessage @ErrorMsgStr , @LogFileName

if ( @ProcessOfferContentType <> @OfferContent )
Begin

	set @ErrorMsgStr = '	Post Validation Offer Content Type has been changed to : ' + 
	        Case
				When @ProcessOfferContentType = 'AZ' then 'A-Z'
				When @ProcessOfferContentType = 'FC' then 'FULL COUNTRY'
				when @ProcessOfferContentType = 'PR' then 'PARTIAL'
			End + ' from : ' +
			
	                Case
				When @OfferContent = 'AZ' then 'A-Z'
				When @OfferContent = 'FC' then 'FULL COUNTRY'
				when @OfferContent = 'PR' then 'PARTIAL'
			End			


	Exec SP_LogMessage @ErrorMsgStr , @LogFileName

End

set @ErrorMsgStr = '	********************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

----------------------------------------------------
-- Add Summary of information after processing
----------------------------------------------------

set @ErrorMsgStr = '	*******************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	POST VALIDATION DETAILS :- '
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	*******************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName


select @TotalDestinations = count(*)
from
(
	select distinct destination
	from #TempVendorOfferData
	where ErrorMessage is NULL
) as tbl1

select @TotalRecords = count(*)
from #TempVendorOfferData
where errormessage is NULL

select @TotalDialeddigits = count(*)
from
(
	select distinct DialedDigit
	from #TempVendorOfferData
	where ErrorMessage is NULL
) as tbl1

set @ErrorMsgStr = '	Total Records       :- ' + convert(varchar(20) , @TotalRecords)
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	Total Destinations  :- ' + convert(varchar(20) , @TotalDestinations)
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	Total Dialed Digits :- ' + convert(varchar(20) , @TotalDialeddigits)
Exec SP_LogMessage @ErrorMsgStr , @LogFileName


set @ErrorMsgStr = '	*******************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName


-------------------------------------------------------------
-- CHECK 14 : Suspect A To Z : Wrong contents of price list
-------------------------------------------------------------

if ( @ProcessOfferContentType = 'AZ' )
Begin

		Declare @TotalOfferCountries int, 
				@TotalSourceCountries int,
				@PercentContentDeviation int,
				@ActualContentDeviation decimal(19,2)

		select @PercentContentDeviation = convert(int , ConfigValue) 
		from tb_config
		where configname = 'PercentContentDeviation'

		set @PercentContentDeviation = isnull(@PercentContentDeviation , 100)


		select @TotalOfferCountries = count(*)
		from
		(
			select distinct countrycode
			from #TempVendorOfferData
			where ErrorMessage is NULL

		) as tbl1


		select @TotalSourceCountries = count(*)
		from
		(
			select distinct countrycode
			from vw_Destination dest
			inner join vw_DialedDigits dd on dest.destinationid = dd.destinationid
			inner join vw_Country cou on dest.countryid = cou.countryid
			where dest.numberplanID = @NumberPlanID
			and @OfferDate between dd.begindate and isnull(dd.enddate , @OfferDate) 
		) as tbl1


		--------------------------------------------------------------------------
		-- Publish the list of countries which are not being offerd in the new 
		-- A-Z, as against the old reference data
		---------------------------------------------------------------------------

		--set @ErrorMsgStr = '	Start of check : ' + convert(varchar(30) , getdate() , 120)
		--Exec SP_LogMessage @ErrorMsgStr , @LogFileName

		Create table #TempExcludedCountryList ( CountryCode varchar(60), Country varchar(60) )

		insert into #TempExcludedCountryList (CountryCode , Country)
		select distinct countrycode , country
		from vw_Destination dest
		inner join vw_DialedDigits dd on dest.destinationid = dd.destinationid
		inner join vw_Country cou on dest.countryid = cou.countryid
		where dest.numberplanID = @NumberPlanID
		and @OfferDate between dd.begindate and isnull(dd.enddate , @OfferDate) 

		--set @ErrorMsgStr = '	Check Point 1 : ' + convert(varchar(30) , getdate() , 120)
		--Exec SP_LogMessage @ErrorMsgStr , @LogFileName

		delete tbl1
		from #TempExcludedCountryList tbl1
		left join 
		(
			select distinct countrycode
			from #TempVendorOfferData
			where ErrorMessage is NULL
		) tbl2 on
		Case 
			When charindex( (','+ tbl2.CountryCode + ',') ,tbl1.CountryCode) <> 0 then substring( tbl1.CountryCode , charindex( (','+ tbl2.CountryCode + ',') ,tbl1.CountryCode) +1 , len(tbl2.CountryCode))
				when charindex( (tbl2.CountryCode + ',') ,tbl1.CountryCode) <> 0 then substring( tbl1.CountryCode , 1 , len(tbl2.CountryCode))
				When charindex( (','+ tbl2.CountryCode) ,tbl1.CountryCode) <> 0 then substring( tbl1.CountryCode , charindex( (','+ tbl2.CountryCode) ,tbl1.CountryCode) +1 , len(tbl2.CountryCode))
			Else tbl1.CountryCode
		End = tbl2.CountryCode
		where tbl2.CountryCode is not NULL
		

		--set @ErrorMsgStr = '	Check Point 1.5 : ' + convert(varchar(30) , getdate() , 120)
		--Exec SP_LogMessage @ErrorMsgStr , @LogFileName


		if exists ( select 1 from #TempExcludedCountryList )
		Begin

		          Alter table #TempExcludedCountryList Add RecordID int identity(1,1)

		  --      set @ErrorMsgStr = '	Check Point 2 : ' + convert(varchar(30) , getdate() , 120)
				--Exec SP_LogMessage @ErrorMsgStr , @LogFileName

				set @ErrorMsgStr = '	*******************************************************'
				Exec SP_LogMessage @ErrorMsgStr , @LogFileName

				set @ErrorMsgStr = '	COUNTRIES EXCLUDED IN A-Z OFFER :- '
				Exec SP_LogMessage @ErrorMsgStr , @LogFileName

				set @ErrorMsgStr = '	*******************************************************'
				Exec SP_LogMessage @ErrorMsgStr , @LogFileName

	
				Declare @MaxID int,
				        @MinID int,
						@VarExcludedCountry varchar(60),
						@VarExcludedCountryCode varchar(60)

                select @MaxID = max(RecordID),
				       @MinID = min(RecordID)
				from #TempExcludedCountryList

				While ( @MinID <= @MaxID)
				Begin

						select @VarExcludedCountry = Country,
						       @VarExcludedCountryCode = CountryCode
						from #TempExcludedCountryList
						where RecordID = @MinID

						set @MinID = @MinID + 1

						set @ErrorMsgStr = '	' + @VarExcludedCountry + '(' + @VarExcludedCountryCode + ')' 
						Exec SP_LogMessage @ErrorMsgStr , @LogFileName

						--set @ErrorMsgStr = '	Check Point 3 : ' + convert(varchar(30) , getdate() , 120)
						--Exec SP_LogMessage @ErrorMsgStr , @LogFileName


				End


				set @ErrorMsgStr = '	*******************************************************'
				Exec SP_LogMessage @ErrorMsgStr , @LogFileName

		End

		Drop table #TempExcludedCountryList

		--set @ErrorMsgStr = '	Check Point 4 : ' + convert(varchar(30) , getdate() , 120)
		--Exec SP_LogMessage @ErrorMsgStr , @LogFileName

		set @ActualContentDeviation = isnull((( @TotalSourceCountries - @TotalOfferCountries ) * 100 )/nullif(( @TotalSourceCountries * 1.0),0), 0)
		select @ActualContentDeviation as ActualContentDeviation
		set @ActualContentDeviation = ROUND(@ActualContentDeviation, 0)

		select @TotalOfferCountries as TotalOfferCountries,
		       @TotalSourceCountries as TotalSourceCountries,
		       @ActualContentDeviation as ActualContentDeviation

		if ( @ActualContentDeviation > @PercentContentDeviation)
		Begin

			--set @ErrorMsgStr = '	Check Point 5 : ' + convert(varchar(30) , getdate() , 120)
			--Exec SP_LogMessage @ErrorMsgStr , @LogFileName

			set @ErrorMsgStr = '	REJECT : Complete Price List rejected due to suspect content. Deviation more than allowed limit of : ' + convert(varchar(10) , @PercentContentDeviation ) + ' Percent.'
			Exec SP_LogMessage @ErrorMsgStr , @LogFileName
			Exec SP_LogMessage NULL , @LogFileName

			set @ResultFlag = 1
			set @ErrorDEscription = 'REJECT : Complete Price List rejected due to suspect content. Deviation more than allowed limit of : ' + convert(varchar(10) , @PercentContentDeviation ) + ' Percent.'

			select @OfferUpdateStatus = offerstatus 
			from tb_offerstatus where offerstatusid = 4

			update tb_vendorofferdetails
			set offerstatus = @OfferUpdateStatus,
			    offerstatusID = 4,
			    ModifiedDate = getdate(),
			    ModifiedByID = @UserID
			where vendorofferid = @VendorOfferID

			Return 1

		End

End

-------------------------------------------------
-- Check to make sure that all the records of the
-- vendor offer file have not fallen into the
-- error bucket.
-------------------------------------------------

if not exists ( select 1 from #TempVendorOfferData where ErrorMessage is NULL )
Begin

	set @ErrorMsgStr = '	REJECT : All records of pricelist have been rejected due to one or the other error. No records to process'
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	Exec SP_LogMessage NULL , @LogFileName


	set @ResultFlag = 1
	set @ErrorDEscription = 'REJECT : All records of pricelist have been rejected due to one or the other error. No records to process'

        select @OfferUpdateStatus = offerstatus 
	from tb_offerstatus where offerstatusid = 4

	update tb_vendorofferdetails
	set offerstatus = @OfferUpdateStatus,
	    offerstatusID = 4,
	    ModifiedDate = GetDate(),
	    ModifiedByID = @UserID
	where vendorofferid = @VendorOfferID

	Return 1

End

Else
Begin


	------------------------------------------------------
	-- At this stage, all the validations are done on
	-- the data, and the offer file has also not been
	-- rejected due to suspect content.
	-------------------------------------------------------
        select @OfferUpdateStatus = offerstatus 
	from tb_offerstatus where offerstatusid = 3

        select @ProcessOfferContentTypeID = ID 
	from tbloffertype where code = @ProcessOfferContentType

	update tb_vendorofferdetails
	set offerstatus = @OfferUpdateStatus,
	offerstatusid = 3,
	UploadOfferType = @ProcessOfferContentType,
	UploadOfferTypeID = @ProcessOfferContentTypeID,
	PartialOfferProcessFlag = @PartialOfferProcessFlag,
	ModifiedDate = getdate(),
	ModifiedByID = @UserID
	where vendorofferid = @VendorOfferID

End


Return 0   


GO
