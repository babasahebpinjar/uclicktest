USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionBandGetInfo]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionBandGetInfo]
(
	@RateDimensionBandID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------
-- Rate Dimension Band should not be NULL and have a valid
-- value
----------------------------------------------------------------

if ( (@RateDimensionBandID is NULL ) 
     or
	 not exists ( select 1 from tb_RateDimensionBand where RateDimensionBandID = @RateDimensionBandID )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Band ID is NULL or not valid and does not exist in the system'
		set @ResultFlag = 1
		Return 1
End

Select RateDimensionBandID , RateDimensionBand , RateDimensionBandAbbrv       
from tb_RateDimensionBand
where RateDimensionBandID = @RateDimensionBandID

Return 0



GO
