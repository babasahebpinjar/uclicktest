USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodDisplayBandRates]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodDisplayBandRates]
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

Create Table #TempRatingMethodDimensionTemplates
(
	RecordID int identity(1,1),
	RateDimensionID int,
	RateDimension varchar(100),
	RateDimensionTemplateID int,
	RateDimensionTemplate varchar(100),
	ItemNumber int
)

Create table #TempRateNumberIdentifier
(
	RateDimension1 varchar(100),
	RateDimension1TemplateID int,
	Dimension1BandID int,
	Dimension1Band varchar(100),
	RateDimension2 varchar(100),
	RateDimension2TemplateID int,
	Dimension2BandID int,
	Dimension2Band varchar(100),
	RateDimension3 varchar(100),
	RateDimension3TemplateID int,
	Dimension3BandID int,
	Dimension3Band varchar(100),
	RateDimension4 varchar(100),
	RateDimension4TemplateID int,
	Dimension4BandID int,
	Dimension4Band varchar(100),
	RateDimension5 varchar(100),
	RateDimension5TemplateID int,
	Dimension5BandID int,
	Dimension5Band varchar(100),
	RateItemID int,
	RateItemName varchar(60)
)

insert into #TempRatingMethodDimensionTemplates
(
	RateDimensionID ,
	RateDimension ,
	RateDimensionTemplateID,
	RateDimensionTemplate ,
	ItemNumber 
)
select tbl5.RateDimensionID , tbl5.RateDimension ,
       tbl4.RateDimensionTemplateID , tbl4.RateDimensionTemplate,
	   tbl1.Number 
from tb_RatingMethodDetail tbl1
inner join tb_RatingMethod tbl2 on tbl1.RatingMethodID = tbl2.RatingMethodID
inner join tb_RateItem tbl3 on tbl1.RateItemID = tbl3.RateItemID
inner join tb_RateDimensionTemplate tbl4 on convert(int , tbl1.ItemValue) = tbl4.RateDimensionTemplateID
inner join tb_RateDimension tbl5 on tbl4.RateDimensionID = tbl5.RateDimensionID
where tbl1.RatingMethodID = @RatingMethodID
and tbl3.RateItemTypeID = 3 -- Dimension Template
order by tbl1.Number


-----------------------------------------------------------
-- Enter records into the temp table for each of the
-- dimension templates
-----------------------------------------------------------

Declare @MinRecordID int,
        @MaxRecordID int,
		@SQLStr varchar(max)

Declare @VarRateDimensionID int,
		@VarRateDimension varchar(100),
		@VarRateDimensionTemplateID int,
		@VarRateDimensionTemplate varchar(100)

Select @MinRecordID = isnull(min(RecordID), 0),
       @MaxRecordID = isnull(max(RecordID), 0)
from #TempRatingMethodDimensionTemplates

while (@MinRecordID <= @MaxRecordID )
Begin

	select 	@VarRateDimensionID = RateDimensionID ,
	@VarRateDimension = RateDimension ,
	@VarRateDimensionTemplateID = RateDimensionTemplateID,
	@VarRateDimensionTemplate = RateDimensionTemplate
	from  #TempRatingMethodDimensionTemplates
	where RecordID = @MinRecordID

	if ( @MinRecordID = 1 )
	Begin

			insert into #TempRateNumberIdentifier
			(
				RateDimension1 ,
				RateDimension1TemplateID ,
				Dimension1Band,
				Dimension1BandID,
				RateItemID,
				RateItemName 
			)
			Values
			(
				@VarRateDimension ,
				@VarRateDimensionTemplateID ,
				NULL,
				NULL,
				NULL,
				NULL 
			)

	End

	if ( @MinRecordID in (2,3,4,5) )
	Begin

	        set @SQLStr = 
			'Update #TempRateNumberIdentifier set ' + 
			' RateDimension'+ convert(varchar(10) , @MinRecordID)+ ' = ''' + convert(varchar(20) ,@VarRateDimension) + ''' ,'+
		  	' RateDimension'+ convert(varchar(10) , @MinRecordID) + 'TemplateID = ' + convert(varchar(20),@VarRateDimensionTemplateID) + ', '+
			' Dimension' + convert(varchar(10) , @MinRecordID) + 'Band = NULL ' + ',' +
			' Dimension'+ convert(varchar(10) , @MinRecordID) + 'BandID = NULL' 

			Exec (@SQLStr)

	End
	
	set @MinRecordID = @MinRecordID + 1

End

select *
from #TempRateNumberIdentifier

Drop table #TempRatingMethodDimensionTemplates
Drop table #TempRateNumberIdentifier
GO
