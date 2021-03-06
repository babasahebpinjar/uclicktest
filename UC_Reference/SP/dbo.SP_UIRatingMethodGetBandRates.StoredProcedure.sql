USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodGetBandRates]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodGetBandRates]
(
	@RatingMethodID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------------------
-- Make sure that Rating Method ID is not NULL and exists in the system
------------------------------------------------------------------------

if (
		(@RatingMethodID is NULL )
		or
		not exists ( select 1 from tb_RatingMethod where RatingMethodID = @RatingMethodID and flag & 1 <> 1 )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method ID is NULL or does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

-----------------------------------------------------------
-- Get the band details depending on the type of Rate
-- dimension template associated with the Rating method
-----------------------------------------------------------

select tbl1.RateNumberIdentifierID , 
rd1.RateDimension as RateDimension1 ,rdt1.RateDimensionTemplateID as RateDimension1TemplateID , db1.RateDimensionBandID as Dimension1BandID, case when tbl1.RateDimension1BandID is NULL then NULL else '(' + rdt1.RateDimensionTemplate + ')' + '--->' + '(' + db1.RateDimensionBand + ')' End as Dimension1Band,
rd2.RateDimension as RateDimension2 ,rdt2.RateDimensionTemplateID as RateDimension2TemplateID , db2.RateDimensionBandID as Dimension2BandID, case when tbl1.RateDimension2BandID is NULL then NULL else '(' + rdt2.RateDimensionTemplate + ')' + '--->' + '(' + db2.RateDimensionBand + ')' End as Dimension2Band,
rd3.RateDimension as RateDimension3 ,rdt3.RateDimensionTemplateID as RateDimension3TemplateID , db3.RateDimensionBandID as Dimension3BandID, case when tbl1.RateDimension3BandID is NULL then NULL else '(' + rdt3.RateDimensionTemplate + ')' + '--->' + '(' + db3.RateDimensionBand + ')' End as Dimension3Band,
rd4.RateDimension as RateDimension4 ,rdt4.RateDimensionTemplateID as RateDimension4TemplateID ,db4.RateDimensionBandID as Dimension4BandID , case when tbl1.RateDimension4BandID is NULL then NULL else '(' + rdt4.RateDimensionTemplate + ')' + '--->' + '(' + db4.RateDimensionBand + ')' End as Dimension4Band,
rd5.RateDimension as RateDimension5 ,rdt5.RateDimensionTemplateID as RateDimension5TemplateID ,db5.RateDimensionBandID as Dimension5BandID, case when tbl1.RateDimension5BandID is NULL then NULL else '(' + rdt5.RateDimensionTemplate + ')' + '--->' + '(' + db5.RateDimensionBand + ')' End as Dimension5Band,
tbl2.RateItemID , tbl2.RateItemName,
tbl1.ModifiedDate,
UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
from tb_RateNumberIdentifier tbl1
left join tb_RateDimensionBand db1 on tbl1.RateDimension1BandID = db1.RateDimensionBandID
left join tb_RateDimensionTemplate rdt1 on db1.RateDimensionTemplateID = rdt1.RateDimensionTemplateID
LEFT join tb_RateDimension rd1 on rdt1.RateDimensionID = rd1.RateDimensionID
left join tb_RateDimensionBand db2 on tbl1.RateDimension2BandID = db2.RateDimensionBandID
left join tb_RateDimensionTemplate rdt2 on db2.RateDimensionTemplateID = rdt2.RateDimensionTemplateID
LEFT join tb_RateDimension rd2 on rdt2.RateDimensionID = rd2.RateDimensionID
left join tb_RateDimensionBand db3 on tbl1.RateDimension3BandID = db3.RateDimensionBandID
left join tb_RateDimensionTemplate rdt3 on db3.RateDimensionTemplateID = rdt3.RateDimensionTemplateID
LEFT join tb_RateDimension rd3 on rdt3.RateDimensionID = rd3.RateDimensionID
left join tb_RateDimensionBand db4 on tbl1.RateDimension4BandID = db4.RateDimensionBandID
left join tb_RateDimensionTemplate rdt4 on db4.RateDimensionTemplateID = rdt4.RateDimensionTemplateID
LEFT join tb_RateDimension rd4 on rdt4.RateDimensionID = rd4.RateDimensionID
left join tb_RateDimensionBand db5 on tbl1.RateDimension5BandID = db5.RateDimensionBandID
left join tb_RateDimensionTemplate rdt5 on db5.RateDimensionTemplateID = rdt5.RateDimensionTemplateID
LEFT join tb_RateDimension rd5 on rdt5.RateDimensionID = rd5.RateDimensionID
inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
where tbl1.RatingMethodID = @RatingMethodID
				
         
GO
