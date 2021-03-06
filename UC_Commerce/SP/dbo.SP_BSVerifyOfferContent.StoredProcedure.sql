USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSVerifyOfferContent]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSVerifyOfferContent]
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

Declare @ErrorMsgStr varchar(2000)

----------------------------------------------------
-- Add an Entry into the Log File indicating that
-- Generic Validation Checks are being Run
----------------------------------------------------

Exec UC_Admin.dbo.SP_LogMessage NULL , @LogFileName
set @ErrorMsgStr = '	==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	****************** GENERIC VALIDATION CHECKS *****************'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName


-------------------------------------------------------------------
-- Mark Error Code for all the records, where the Effective Date 
-- value is not correct and equals 12/31/1899
-------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has invalid value for Effective Date',
    tbl1.ErrorCode = '1'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.EffectiveDate = '12/31/1899'

--set @ErrorMsgStr = '	POST CHECK 1......'
--Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

-----------------------------------------
-- CHECK 1 : DialCode is not numeric
-----------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'DialCode  : '  + tbl1.DialedDigit + ' is not a numeric value',
    tbl1.ErrorCode = '2'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and
(
   ISNUMERIC(tbl1.DialedDigit) = 0
   or
   charindex('.' , convert(varchar(20) ,tbl1.DialedDigit) ) <> 0
)

--set @ErrorMsgStr = '	POST CHECK 2......'
--Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

-------------------------------------------------------
-- CHECK 2 : DialCode length greater than 15 characters
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'DialCode  : '  + tbl1.DialedDigit + ' length greater than 15 characters',
    tbl1.ErrorCode = '3'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and ISNUMERIC(tbl1.DialedDigit) = 1
and LEN(tbl1.DialedDigit) > 15

--set @ErrorMsgStr = '	POST CHECK 3......'
--Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName


--------------------------------------------------------------------
-- CHECK 4 : Destination With no associated dial codes or rates
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has no associated Dial Codes or Rates',
    tbl1.ErrorCode = '4'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is null
and
(
   isnumeric(isnull(tbl1.Rate , 'No Rates')) = 0 
   or
   charindex(',' , convert(varchar(25) ,tbl1.Rate) ) <> 0
 )

--set @ErrorMsgStr = '	POST CHECK 4......'
--Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

--------------------------------------------------------------------
-- CHECK 5 : Destination With associated dial codes but no rates
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has  associated Dial Codes but no Rates',
    tbl1.ErrorCode = '5'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is not null
and
(
   isnumeric(isnull(tbl1.Rate , 'No Rates')) = 0 
   or
   charindex(',' , convert(varchar(25) ,tbl1.Rate) ) <> 0
 )


--set @ErrorMsgStr = '	POST CHECK 5......'
--Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

--------------------------------------------------------------------
-- CHECK 6 : Destination With associated rates but no dial codes
--------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has  associated Rates but no Dial Codes',
    tbl1.ErrorCode = '6'
from  #TempVendorOfferData tbl1
where ErrorMessage is NULL
and tbl1.DialedDigit is null
and isnumeric(isnull(tbl1.Rate , 'No Rates')) = 1

--set @ErrorMsgStr = '	POST CHECK 6......'
--Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

--------------------------------------------------------
-- CHECK 7 : More than one entry for the combination of 
-- 1. Destination
-- 2. Effective Date
-- 3. Dialed Digit
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Multiple Entries exist for Destination : ' + tbl1.Destination + ' and  EffectiveDate : '+ CONVERT(varchar(10), tbl1.EffectiveDate, 120 ) +' and DialedDigit : ' + tbl1.DialedDigit,
    tbl1.ErrorCode = '7'
from  #TempVendorOfferData tbl1
inner join
(  
	Select COUNT(*) as TotalRecords, Destination , EffectiveDate , DialedDigit , RatingMethod , RateTimeBand
	from #TempVendorOfferData
	where ErrorMessage is NULL
	group by Destination , EffectiveDate , DialedDigit , RatingMethod , RateTimeBand
	Having COUNT(1) > 1
) tbl2
on tbl1.destination = tbl2.destination
and tbl1.EffectiveDate = tbl2.EffectiveDate
and tbl1.DialedDigit = tbl2.DialedDigit
and tbl1.RatingMethod = tbl2.RatingMethod
and tbl1.RateTimeBand = tbl2.RateTimeBand
where tbl1.ErrorMessage is NULL

--set @ErrorMsgStr = '	POST CHECK 7......'
--Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

--------------------------------------------------------
-- CHECK 8 : Duplicate Dial code for same effective date
-- across different destinations.
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Duplicate Dial Code : ' + tbl1.DialedDigit + ' for Effective Date :' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ),
    tbl1.ErrorCode = '8'
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
-- CHECK 9 : Multiple rates for the same destination and 
-- Effective date.
--------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Multiple rates for Destination : ' + tbl1.Destination + ' and  Effective Date :' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ),
    tbl1.ErrorCode = '9'
from  #TempVendorOfferData tbl1
inner join
(
	select count(*) as TotalRecords , Destination , EffectiveDate , RateTimeBand
	from
	(
		select distinct Destination , Effectivedate , Rate , RateTimeBand
		from #TempVendorOfferData
		where ErrorMessage is NULL
	) as tbl
	Group by Destination , EffectiveDate , RateTimeBand
	having count(1) > 1
)tbl2
on tbl1.EffectiveDate = tbl2.EffectiveDate
and tbl1.Destination = tbl2.Destination
and tbl1.RateTimeBand = tbl2.RateTimeBand
where tbl1.ErrorMessage is NULL



-------------------------------------------------------
-- CHECK 10 : Check for record Items which have the 
-- country code as NOT EXIST
------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 
   'Country Code cannot be resolved for Destination : '+ Destination +' and DialedDigit : ' + tbl1.DialedDigit + ' and  Effective Date :' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ) ,
    tbl1.ErrorCode = '10' 
from #TempVendorOfferData tbl1
where tbl1.ErrorMessage is NULL
and tbl1.CountryCode = 'NOT EXIST'


------------------------------------------------
-- CHECK 11 : Multiple Country Codes for the
-- Same Destination.
--------------------------------------------------------------------
-- Multiple Code Scenarios would be:
-- 1. Two Different country codes belonging to no group
-- 2. Two Different country codes belonging to two different groups
-- 3. Two different country codes one belonging to group, other to no group
---------------------------------------------------------------------

select tbl1.EntityGroupID as GroupID , EntityGroup as [Group] , EntityGroupAbbrv as GroupAbbrv,
       tbl3.CountryID , tbl3.CountryCode
into #TempCountryGroupXRef
from UC_Reference.dbo.tb_EntityGroup tbl1
inner join UC_Reference.dbo.tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.InstanceID = tbl3.CountryID
where tbl1.EntityGroupTypeID = -4  -- Country Group 
and tbl1.Flag & 1 <> 1

------------------------
-- Handle Condition 1
------------------------

update tbl1
set tbl1.ErrorMessage ='Multiple Country Code : ' + tbl1.CountryCode + ' for Destination :' + tbl1.Destination,
    tbl1.ErrorCode = '11'
from  #TempVendorOfferData tbl1
inner join
(
	select destination , groupid , COUNT(*) as TotalCountryCode
	from
	(
		select distinct tbl1.destination , tbl1.countrycode , ISNULL(tbl2.GroupID , 99999) as GroupId
		from #TempVendorOfferData tbl1
		left join #TempCountryGroupXRef tbl2 on tbl1.countrycode = tbl2.countrycode
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
    tbl1.ErrorCode = '12'
from  #TempVendorOfferData tbl1
inner join
(
	select destination , count(*) as TotalGroup
	from
	(
		select distinct tbl1.destination  , ISNULL(tbl2.GroupID , 99999) as GroupId
		from #TempVendorOfferData tbl1
		left join #TempCountryGroupXRef tbl2 on tbl1.countrycode = tbl2.countrycode
		where tbl1.errormessage is null
	) as tbl
	group by destination
	having COUNT(2) > 1
) as tbl2
on tbl1.destination = tbl2.destination
where tbl1.ErrorMessage is NULL

Drop table #TempCountryGroupXRef

-------------------------------------------------------------------
-- Print the various error messages to the Log File for tracking
-- purpose.
-------------------------------------------------------------------

Exec UC_Admin.dbo.SP_LogMessage NULL, @LogFileName


Declare @VarErrorMessage varchar(2000),
        @VarErrorCode varchar(20),
		@PrevErrorCode varchar(20) = ''

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

				Exec UC_Admin.dbo.SP_LogMessage NULL, @LogFileName
			End

			set @PrevErrorCode = @VarErrorCode

	 End

	set @ErrorMsgStr = '		ERROR : ' + @VarErrorMessage

	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

	Fetch Next From Log_Error_Messages_Cur
	Into @VarErrorMessage, @VarErrorCode

End

Close Log_Error_Messages_Cur
Deallocate Log_Error_Messages_Cur

-----------------------------------------------------------------
-- Set the return flag to error and populate the error description
------------------------------------------------------------------

if exists ( select 1 from #TempVendorOfferData where ErrorMessage is not NULL)
Begin

	Exec UC_Admin.dbo.SP_LogMessage NULL , @LogFileName
	set @ErrorMsgStr = '	ERROR !!! One or more offer records encountered with errors'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

	set @ErrorDescription = 'ERROR !!! One or more offer records encountered with errors'
	set @ResultFlag = 1

End

Return 0





GO
