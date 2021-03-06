USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodGetAttributes]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodGetAttributes]
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

--------------------------------------------------
-- Display the details related to rating method
--------------------------------------------------

Create Table #TempRatingMethodDetails
(
	RatingMethodDetailID int,
	RateItemTypeID int,
	RateItemType varchar(60),
	RateItemID int,
	RateItemName varchar(60),
	RateItemNumber int,
	ItemValue varchar(100),
	UIControlTypeID int,
	UIControlType varchar(60),
	ExecutionScript varchar(1000)
)

------------------------------------------------------
-- If details already exist, then list them from the
-- rating method detail
------------------------------------------------------

if exists ( Select 1 from tb_RatingMethodDetail where RatingMethodID = @RatingMethodID )
Begin

		Insert into #TempRatingMethodDetails
		(
			RatingMethodDetailID,
			RateItemTypeID,
			RateItemType,
			RateItemID,
			RateItemName,
			RateItemNumber,
			ItemValue,
			UIControlTypeID,
			UIControlType,
			ExecutionScript
		)
		Select tbl1.RatingMethodDetailID ,tbl3.RateItemTypeID ,tbl3.RateItemType ,
		       tbl1.RateItemID ,tbl2.RateItemName ,  tbl1.Number ,
			   Case
			      when tbl3.RateItemTypeID = 3 then tbl4.RateDimensionTemplate
				  Else convert(varchar(100) ,convert(int,tbl1.ItemValue	))
			   End  ,
			   isNull(tbl5.UIControlTypeID ,-1),
			   tbl6.UIControlType,
			   NULL
		from tb_RatingMethodDetail tbl1
		inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
		inner join tb_RateItemType tbl3 on tbl2.RateItemTypeID = tbl3.RateItemTypeID
		left join tb_RateDimensionTemplate tbl4 on convert(int ,tbl1.ItemValue) = tbl4.RateDimensionTemplateID
		left join tb_RateItemControlType tbl5 on tbl1.RateItemID = tbl5.RateItemID
		inner join tb_UIControlType tbl6 on isnull(tbl5.UIControlTypeID , -1) = tbl6.UIControlTypeID
		where tbl1.RatingMethodID = @RatingMethodID

End

----------------------------------------------------------
-- Rating Method exists in the system but attributes have 
-- not been configured till now
----------------------------------------------------------

Else
Begin

		Insert into #TempRatingMethodDetails
		(
			RatingMethodDetailID,
			RateItemTypeID,
			RateItemType,
			RateItemID,
			RateItemName,
			RateItemNumber,
			ItemValue,
			UIControlTypeID,
			UIControlType,
			ExecutionScript
		)
		Select NULL  ,tbl3.RateItemTypeID ,tbl3.RateItemType ,
		       tbl1.RateItemID ,tbl2.RateItemName ,  tbl1.Number , NULL,
			   isNull(tbl5.UIControlTypeID ,-1),
			   tbl6.UIControlType,
			   NULL
		from tb_RateStructureRateItem tbl1
		inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
		inner join tb_RateItemType tbl3 on tbl2.RateItemTypeID = tbl3.RateItemTypeID
		inner join tb_RatingMethod tbl4 on tbl1.RateStructureID =  tbl4.RateStructureID
		left join tb_RateItemControlType tbl5 on tbl1.RateItemID = tbl5.RateItemID
		inner join tb_UIControlType tbl6 on isnull(tbl5.UIControlTypeID , -1) = tbl6.UIControlTypeID
		where tbl4.RatingMethodID = @RatingMethodID
		and tbl3.RateItemTypeID not in (1,4,5)
		and tbl1.Flag & 1 <> 1
		and tbl2.Flag & 1 <> 1

End


------------------------------------------------------
-- Open a cursor to populate the Execution Script
-- for each of the rate items
------------------------------------------------------

Declare @VarRateItemID int,
        @ExecutionScript varchar(1000)

Declare Cur_Populate_ExecutionScript Cursor For
Select Distinct RateItemID
from #TempRatingMethodDetails
where UIControlTypeID in (-2,-3)

Open Cur_Populate_ExecutionScript
Fetch next From Cur_Populate_ExecutionScript
Into @VarRateItemID

While @@FETCH_STATUS = 0
Begin
  
		Begin Try

				set @ExecutionScript = NULL

				Exec SP_BSGetExecutionScript @RatingMethodID , @VarRateItemID , @ExecutionScript Output

				update #TempRatingMethodDetails
				set ExecutionScript = @ExecutionScript
				where RateItemID = @VarRateItemID

		End Try

		Begin Catch

				Close Cur_Populate_ExecutionScript
				Deallocate Cur_Populate_ExecutionScript
				Return 1

		End Catch

		Fetch next From Cur_Populate_ExecutionScript
		Into @VarRateItemID

End

Close Cur_Populate_ExecutionScript
Deallocate Cur_Populate_ExecutionScript

select *
from #TempRatingMethodDetails
order by RateItemTypeID , RateItemNumber 

-----------------------------------------------------
-- Drop the temporary table post data processing
-----------------------------------------------------

Drop table #TempRatingMethodDetails

Return 0


GO
