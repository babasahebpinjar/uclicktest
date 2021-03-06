USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetRateDetail]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetRateDetail]
(
	@RateID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check to ensure that the RATEID is not NULL and exists
-- in the system
----------------------------------------------------------

if ( (@RateID is NULL) or not exists (select 1 from tb_rate where rateID = @RateID) )
Begin

		set @ErrorDescription = 'ERROR !!!! Rate ID passed is either NULL or does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------
-- Get the Rating Method ID from the rate record
--------------------------------------------------

Declare @RatingMethodID int 

select @RatingMethodID = RatingMethodID
from tb_Rate
where rateID = @RateID

Create table #TempRateTypeDetails (RateTypeID  int, RateType varchar(300) )

insert into #TempRateTypeDetails
select ri.RateItemID , ri.RateItemDescription + '-' + '(' + rdb1.RateDimensionBand + ')' 
from tb_RateNumberIdentifier rni
inner join tb_RateDimensionBand rdb1 on rni.RateDimension1BandID = rdb1.RateDimensionBandID
inner join tb_RateItem ri on rni.RateItemID = ri.RateItemID
where RatingMethodID = @RatingMethodID

----------------------------------------------
-- Return the result set for the data record
----------------------------------------------

select tbl1.RateDetailID , tbl2.RateTypeID , tbl2.RateType , tbl1.Rate
from tb_RateDetail tbl1
inner join #TempRateTypeDetails tbl2 on tbl1.RateTypeID = tbl2.RateTypeID
where tbl1.RateID = @RateID
order by tbl2.RateType

Return 0


GO
