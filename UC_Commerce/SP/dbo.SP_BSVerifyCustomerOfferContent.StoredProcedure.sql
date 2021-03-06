USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSVerifyCustomerOfferContent]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSVerifyCustomerOfferContent]
(
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

-----------------------------------------------------------
-- Check to see that destination name is not NULL or empty
-----------------------------------------------------------
update tbl1
set tbl1.ErrorMessage = 'Records exist with Destination name missing or empty',
    tbl1.ErrorCode = '1'
from #TempCustomerOfferData tbl1
where ErrorMessage is NULL
and tbl1.Destination is NULL

----------------------------------------------------------
-- Check to ensure that all the Effective dates are not NULL
----------------------------------------------------------
update tbl1
set tbl1.ErrorMessage = 'Records exist with missing or empty Effective date',
    tbl1.ErrorCode = '2'
from #TempCustomerOfferData tbl1
where ErrorMessage is NULL
and tbl1.EffectiveDate is NULL


----------------------------------------------------------
-- Check to ensure that all the Rating Methods are not NULL
----------------------------------------------------------
update tbl1
set tbl1.ErrorMessage = 'Records exist with missing or empty Rating Method',
    tbl1.ErrorCode = '3'
from #TempCustomerOfferData tbl1
where ErrorMessage is NULL
and tbl1.RatingMethod is NULL


-----------------------------------------------------------------
-- Check to ensure that all the Rate Dimension Band are not NULL
-----------------------------------------------------------------
update tbl1
set tbl1.ErrorMessage = 'Records exist with missing or empty Rate Dimension Band',
    tbl1.ErrorCode = '4'
from #TempCustomerOfferData tbl1
where ErrorMessage is NULL
and tbl1.RateDimensionBand is NULL


---------------------------------------------------------------------
-- Check to ensure that Rate not missing or non numeric value
----------------------------------------------------------------------
update tbl1
set tbl1.ErrorMessage  = 
   'Destination : ' + tbl1.Destination + ' has missing or non numeric rate for effective date : ' + convert(varchar(10) , tbl1.EffectiveDate , 120),
    tbl1.ErrorCode = '5'
from  #TempCustomerOfferData tbl1
where ErrorMessage is NULL
and
(
   isnumeric(isnull(tbl1.Rate , 'No Rates')) = 0 
   or
   charindex(',' , convert(varchar(25) ,tbl1.Rate) ) <> 0
 )

------------------------------------------------------------------------
-- Check to ensure that all the Rating Methods provided in the offer
-- sheet exist in the system
-------------------------------------------------------------------------

update tbl1
set tbl1.ErrorMessage  = 'Rating Method : '+ tbl1.RatingMethod + ' does not exist in the uClick Reference system'   ,
    tbl1.ErrorCode = '6'
from #TempCustomerOfferData tbl1
left join UC_Reference.dbo.tb_RatingMethod tbl2 on tbl1.RatingMethod = tbl2.RatingMethod and tbl2.Flag & 1 <> 1
where tbl2.RatingMethod is NULL
and ErrorMessage is NULL; -- Essential to add for CTE based queries


-------------------------------------------------------------------------------------
-- Check to ensure that all the Rating Method and Rate Dimension band combinations
-- exist in the uclick Reference system
-------------------------------------------------------------------------------------

With CTE_DistinctRatingMethodAndBandCombinations
As
(
	select Distinct RatingMethod , RateDimensionBand
	from #TempCustomerOfferData
	where ErrorMessage is NULL
),
CTE_RatingMEthodAndBandCombinationMissing
as
(
	select tbl1.RatingMethod , tbl1.RateDimensionBand
	from CTE_DistinctRatingMethodAndBandCombinations tbl1
	-- We do inner instead of left because all the records where rating method must be missing would have been filtered out already
	inner join UC_Reference.dbo.tb_RatingMethod tbl2 on tbl1.RatingMethod = tbl2.RatingMethod and tbl2.Flag & 1 <> 1
	left join UC_Reference.dbo.tb_RateNumberIdentifier tbl3 on tbl2.RatingMethodID = tbl3.RatingMethodID
	left join UC_Reference.dbo.tb_RateDimensionBand tbl4 on tbl3.RateDimension1BandID = tbl4.RateDimensionBandID 
														  and
															tbl1.RateDimensionBand = tbl4.RateDimensionBand
	where tbl4.RateDimensionBand is NULL
)
update tbl1
set tbl1.ErrorMessage = 'The combination of Rating Method : ' + tbl1.RatingMethod  +' and Dimension Band : '+ tbl1.RateDimensionBand + ' doesnot exist in system',
    tbl1.ErrorCode = '7'
from #TempCustomerOfferData tbl1
inner join CTE_RatingMEthodAndBandCombinationMissing tbl2 on tbl1.RatingMethod = tbl2.RatingMethod
                                                            and
															 tbl1.RateDimensionBand = tbl2.RateDimensionBand
where ErrorMessage is NULL;


------------------------------------------------------------------------
-- Check to ensure that all destinations provided in the offer sheet 
-- are available at the provided effective date
------------------------------------------------------------------------

With CTE_DDActiveOnRateSheetEffectiveDate
as
(
	Select tbl1.Destination , tbl1.EffectiveDate , tbl3.DialedDigits
	from #TempCustomerOfferData tbl1
	inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.NumberplanID = -2
	inner join UC_Reference.dbo.tb_DialedDigits tbl3 on tbl2.DestinationID = tbl3.DestinationID
	Where tbl1.EffectiveDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.EffectiveDate)
	and tbl1.EffectiveDate between tbl3.BeginDate and isnull(tbl3.EndDate , tbl1.EffectiveDate)
	and ErrorMessage is NULL
),
CTE_DDCountPerDestination
as
(
	select Destination , EffectiveDate , count(*) as TotalDD
	from CTE_DDActiveOnRateSheetEffectiveDate
	group by Destination , EffectiveDate
)
update tbl1
set tbl1.ErrorMessage = 'Destination : ' + tbl1.Destination + ' does not have active breakouts during effective date : ' + convert(varchar(10) , tbl1.EffectiveDate , 120),
    tbl1.ErrorCode = '8'
from #TempCustomerOfferData tbl1
left join CTE_DDActiveOnRateSheetEffectiveDate tbl2 on 
                                 tbl1.Destination = tbl2.Destination
								 and
								 tbl1.Effectivedate = tbl2.EffectiveDate
Where tbl2.Destination is NULL -- Destination for which no active DialedDigits exist at particular effective date
and ErrorMessage is NULL; -- Essential to add for CTE based queries
 

--------------------------------------------------------------------------------
-- Check to ensure that multiple rates do not exist for the same destination
-- Effective Date and RateDimensionBand
---------------------------------------------------------------------------------

With CTE_RecordCountPerDestinationAndEffectiveDate
As
(

	select count(*) as TotalRecords , Destination , EffectiveDate , RateDimensionBand
	from
	(
		select distinct Destination , Effectivedate , Rate , RateDimensionBand
		from #TempCustomerOfferData
		where ErrorMessage is NULL
	) as tbl
	Group by Destination , EffectiveDate , RateDimensionBand
	having count(1) > 1
)
update tbl1
set tbl1.ErrorMessage  = 
   'Multiple rates for Destination : ' + tbl1.Destination + ' and  Effective Date :' + CONVERT(varchar(10) , tbl1.EffectiveDate , 120 ),
    tbl1.ErrorCode = '9'
from  #TempCustomerOfferData tbl1
inner join CTE_RecordCountPerDestinationAndEffectiveDate tbl2
			on tbl1.EffectiveDate = tbl2.EffectiveDate
			and tbl1.Destination = tbl2.Destination
			and tbl1.RateDimensionBand = tbl2.RateDimensionBand
where tbl1.ErrorMessage is NULL



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
from #TempCustomerOfferData
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

if exists ( select 1 from #TempCustomerOfferData where ErrorMessage is not NULL)
Begin

	Exec UC_Admin.dbo.SP_LogMessage NULL , @LogFileName
	set @ErrorMsgStr = '	ERROR !!! One or more offer records encountered with errors'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

	set @ErrorDescription = 'ERROR !!! One or more offer records encountered with errors'
	set @ResultFlag = 1

End

Return 0





GO
