USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCheckMissingDestinationsforCustomerOffer]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCheckMissingDestinationsforCustomerOffer]
(
	@OfferContent varchar(50),
	@LogFileName varchar(1000),
	@ResultFlag int Output,
	@ErrorDescription varchar(2000) Output
)
As

Declare @ErrorMsgStr varchar(2000);


With CTE_DDActiveOnRateSheetEffectiveDate
as
(
	Select tbl1.Destination , tbl2.DestinationID , tbl2.CountryID ,tbl1.EffectiveDate , tbl3.DialedDigits
	from #TempCustomerOfferData tbl1
	inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.NumberplanID = -2
	inner join UC_Reference.dbo.tb_DialedDigits tbl3 on tbl2.DestinationID = tbl3.DestinationID
	Where tbl1.EffectiveDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.EffectiveDate)
	and tbl1.EffectiveDate between tbl3.BeginDate and isnull(tbl3.EndDate , tbl1.EffectiveDate)
),
CTE_RateSheetDestinationsWithCountryAndEffectiveDate
as
(
	select distinct DestinationID , EffectiveDate , CountryID
	from CTE_DDActiveOnRateSheetEffectiveDate
),
CTE_DestinationActiveInSystemForCountryAndEffectiveDate
as
(

	select Distinct tbl2.Destination ,tbl2.DestinationID , tbl1.CountryID , tbl4.Country ,tbl1.EffectiveDate
	from (select distinct countryID , EffectiveDate from CTE_RateSheetDestinationsWithCountryAndEffectiveDate) tbl1
	inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.CountryID = tbl2.CountryID and tbl2.NumberplanID = -2
	inner join UC_Reference.dbo.tb_DialedDigits tbl3 on tbl2.DestinationID = tbl3.DestinationID
	inner join UC_Reference.dbo.tb_Country tbl4 on tbl2.CountryId = tbl4.CountryID
	Where tbl1.EffectiveDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.EffectiveDate)
	and tbl1.EffectiveDate between tbl3.BeginDate and isnull(tbl3.EndDate , tbl1.EffectiveDate)

)
select tbl1.Destination , tbl1.Country , tbl1.EffectiveDate
into #TempMissingDestinationsInOffer
from CTE_DestinationActiveInSystemForCountryAndEffectiveDate tbl1
left join CTE_RateSheetDestinationsWithCountryAndEffectiveDate tbl2 on
                                          tbl1.DestinationID = tbl2.DestinationID
										  and
										  tbl1.CountryID = tbl2.CountryID
										  and
										  tbl1.EffectiveDate = tbl2.EffectiveDate
where tbl2.DestinationID is NULL

if not exists ( select 1 from #TempMissingDestinationsInOffer )
	GOTO PROCESSEND

---------------------------------------------------------------------
-- Publish the data in the log file for all the missing Destinations
---------------------------------------------------------------------

Exec UC_Admin.dbo.SP_LogMessage NULL , @LogFileName
set @ErrorMsgStr = '	==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	****************** MISSING DESTINATION CHECKS *****************'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	Offer Type is : ' + 
                              Case
									When @OfferContent = 'FC' then 'FULL COUNTRY'
									When @OfferContent = 'AZ' then 'AZ'
									When @OfferContent = 'PR' then 'PARTIAL'
									Else 'UNKNOWN'
							  End
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName


Declare @VarErrorMessage varchar(2000),
        @VarErrorCode varchar(500),
		@PrevErrorCode varchar(500) = ''

Declare Log_Error_Messages_Cur Cursor For
select Destination , 'COUNTRY : (' + Country + ') EFFECTIVE DATE : (' + convert(varchar(10) , EffectiveDate, 120) + ')'
from #TempMissingDestinationsInOffer
order by EffectiveDate , Country

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

			set @PrevErrorCode = @VarErrorCode

			set @ErrorMsgStr = '		==============================================================='
			Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

			set @ErrorMsgStr = '		' + @VarErrorCode
			Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

			set @ErrorMsgStr = '		==============================================================='
			Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

	 End

	set @ErrorMsgStr = '		   ' + @VarErrorMessage

	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

	Fetch Next From Log_Error_Messages_Cur
	Into @VarErrorMessage, @VarErrorCode

End

Close Log_Error_Messages_Cur
Deallocate Log_Error_Messages_Cur

Exec UC_Admin.dbo.SP_LogMessage NULL , @LogFileName
set @ErrorMsgStr = '	==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	NOTE: Please change the offer type to PARTIAL, incase selective '
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	destinations need to be offered'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @LogFileName



if exists ( select 1 from #TempMissingDestinationsInOffer)
Begin

	set @ErrorDescription = 'ERROR !!! Offer is of the type ' + @OfferContent + ' and all destinations for countries are not being offered'
	set @ResultFlag = 1

End


PROCESSEND:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMissingDestinationsInOffer') )
	Drop table #TempMissingDestinationsInOffer





GO
