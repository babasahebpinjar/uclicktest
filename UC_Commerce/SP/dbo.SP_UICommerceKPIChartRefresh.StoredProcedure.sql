USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommerceKPIChartRefresh]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICommerceKPIChartRefresh]
(
	@TopNCount int = NULL,
	@LastNMonthCount int = NULL

)
As

if ( ( @TopNCount is NULL) or ( @TopNCount <= 0) )
	set @TopNCount = 10


if ( ( @LastNMonthCount is NULL) or ( @LastNMonthCount <= 0) )
	set @LastNMonthCount = 6


Declare @SQLStr Varchar(2000)

------------------------------------------------------
-- Select TOP N latest offers processed by system
------------------------------------------------------

set @SQLStr = 'select top ' + convert(varchar(10) ,@TopNCount) + ' OfferID , ExternalOfferFileName , OfferFilename ,OfferDate , OfferContent ,tbl2.OfferStatus ' + char(10) +
              ' from tb_Offer tbl1 ' + char(10) +   
              ' inner join tb_OfferStatus tbl2 on  dbo.FN_GetVendorOfferCurrentStatus(tbl1.OfferID) = tbl2.OfferStatusID ' + char(10) +
              ' where tbl1.offertypeID = -1 ' + char(10) +
              ' order by OfferDate desc '


truncate table  tb_UIChartTopNOffersProcessed

insert into tb_UIChartTopNOffersProcessed
Exec (@SQLStr)


-------------------------------------------------------
-- Offer Distribution by Content for Current Month
------------------------------------------------------

truncate table tb_UIChartOfferDistributionByContent

insert into tb_UIChartOfferDistributionByContent
select OfferContent , count(*)
from tb_Offer
where offertypeID = -1 -- Vendor Offers
and month(offerDate) = month(getdate())
and year(offerdate) = year(getdate())
group by OfferContent


-----------------------------------
-- Offer trend in Last N Months 
-----------------------------------

truncate table tb_UIChartOfferTrendLastNMonths

insert into tb_UIChartOfferTrendLastNMonths
select  offercontent,
       substring(convert(varchar(30) ,offerdate),1,3) + '-' + substring(convert(varchar(30) , offerdate),8,4) ,
	   convert(int ,convert(varchar(4) ,year(offerdate)) + right( '0' + convert(varchar(2) ,month(offerdate)) , 2)) ,
	   count(*)
from tb_Offer
where offertypeid = -1
and datediff(mm , offerdate , getdate() ) < @LastNMonthCount
group by substring(convert(varchar(30) ,offerdate),1,3) + '-' + substring(convert(varchar(30) , offerdate),8,4),
          offercontent,
		  convert(int ,convert(varchar(4) ,year(offerdate)) + right( '0' + convert(varchar(2) ,month(offerdate)) , 2))
order by convert(int ,convert(varchar(4) ,year(offerdate)) + right( '0' + convert(varchar(2) ,month(offerdate)) , 2))


------------------------------------------------------------------
-- Top N partners by Number of Rate sheets send in last N Months
------------------------------------------------------------------


set @SQLStr = 'select Top ' + convert(varchar(10) , @TopNCount) + ' tbl2.Source, count(*) ' + char(10) +       
              ' from tb_Offer tbl1 ' + char(10) +
              ' inner join tb_Source tbl2 on tbl1.SourceID = tbl2.SourceID ' + char(10) +
              ' where tbl1.OfferTypeID = -1 ' + char(10) +  --- Vendor Offer
              ' and tbl2.SourceTypeID = -1 ' + char(10) +  -- Vendor Source
              ' and datediff(mm , offerdate , getdate() ) < ' + convert(varchar(10) , @LastNMonthCount) + char(10) +
              ' group by tbl2.Source ' + char(10) +
              ' order by 2 Desc '


truncate table tb_UIChartTopNPartnersByOffers

insert into tb_UIChartTopNPartnersByOffers
Exec (@SQLStr)

-----------------------------------------------------------------------------
-- TOP N Offer Dates by Number of rate sheets received in Current Month
-----------------------------------------------------------------------------


set @SQLStr = 'select Top ' + convert(varchar(10) , @TopNCount) + ' convert(Date , OfferDate) , count(*) ' + char(10) +
              ' from tb_offer ' + char(10) +
              ' where month(offerDate) = month(getdate()) ' + char(10) +
              ' and year(offerdate) = year(getdate()) ' + char(10) +
              ' group by convert(Date , OfferDate) ' +  char(10) +
              ' order by 2 desc ,convert(Date , OfferDate) desc'

truncate table tb_UIChartTopNOfferDateByOffers

insert into tb_UIChartTopNOfferDateByOffers
Exec (@SQLStr)

       
------------------------------------------------------------------------------------------
-- Average time taken to process vendor offer by Content Type in Current Month
------------------------------------------------------------------------------------------

truncate table tb_UIChartAverageOfferProcessTimeByContent


insert into tb_UIChartAverageOfferProcessTimeByContent
select OfferContent,AVG( ProcessTimeInMin )
from
(
		select TBL1.OfferID , TBL1.OfferCOntent , TBL1. OfferDate , TBL2.ModifiedDate as OfferProcessStartDate , TBL1.OfferProcessEndDate ,
			   DateDiff(mi , TBL2.ModifiedDate , TBL1.OfferProcessEndDate) ProcessTimeInMin
		from
		(
			select tbl1.offerID , tbl1.offerContent , tbl1.offerdate , tbl2.ModifiedDate as OfferProcessEndDate
			from tb_offer tbl1
			inner join tb_OfferWorkflow tbl2 on tbl1.OfferID = tbl2.OfferID
			where tbl1.offertypeID = -1
			and tbl2.OfferStatusID = 6 -- Export Successful
			and month(tbl1.offerDate) = month(getdate())
			and year(tbl1.offerdate) = year(getdate())
		) TBL1
		inner join tb_OfferWorkflow TBL2 on TBL1.OfferID = TBL2.OfferID
		where TBL2.OfferStatusID = 1 -- Created
) as FinalTab
group by OfferContent







GO
