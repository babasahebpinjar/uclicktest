USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodGetDetails]
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
-- Display the details related to rating structure
--------------------------------------------------

select tbl1.RatingMethodID , tbl1.RatingMethod , tbl1.RatingMethodAbbrv,
       tbl1.RateStructureID , tbl2.RateStructure,
       tbl1.ModifiedDate,
       UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
from tb_RatingMethod tbl1
inner join tb_RateStructure tbl2 on tbl1.RateStructureID = tbl2.RateStructureID
where RatingMethodID = @RatingMethodID
and tbl1.Flag & 1 <> 1

GO
