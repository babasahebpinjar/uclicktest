USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateGetBandDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateGetBandDetails]
(
	@RateDimensionTemplateID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------
-- Rate Dimension Templtae should not be NULL and have a valid
-- value
----------------------------------------------------------------

if ( (@RateDimensionTemplateID is NULL ) 
     or
	 not exists ( select 1 from tb_RateDimensionTemplate where RateDimensionTemplateID = @RateDimensionTemplateID and flag & 1 <> 1 )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Template ID is NULL or not valid and does not exist in the system'
		set @ResultFlag = 1
		Return 1
End

--------------------------------------------------
-- Depending on the Rate Dimension Template type
-- Select the schema for extracting band details
--------------------------------------------------

Declare @RateDimensionID int

select @RateDimensionID = RateDimensionID
from tb_RateDimensionTemplate
where RateDimensionTemplateID = @RateDimensionTemplateID

if ( @RateDimensionID = 1 ) --- Date and Time Dimension
Begin

		--Select tbl2.RateDimensionBandID , tbl2.RateDimensionBand ,
		--	   tbl1.DateTimeBandID ,EventYear , 
		--	   Case
		--			When EventMonth = 0 Then 'All'
		--			When EventMonth = 1 Then 'Jan'
		--			When EventMonth = 2 Then 'Feb'
		--			When EventMonth = 3 Then 'Mar'
		--			When EventMonth = 4 Then 'Apr'
		--			When EventMonth = 5 Then 'May'
		--			When EventMonth = 6 Then 'Jun'
		--			When EventMonth = 7 Then 'Jul'
		--			When EventMonth = 8 Then 'Aug'
		--			When EventMonth = 9 Then 'Sep'
		--			When EventMonth = 10 Then 'Oct'
		--			When EventMonth = 11 Then 'Nov'
		--			When EventMonth = 12 Then 'Dec'
		--	   End as EventMonth,
		--	   Case
		--			When EventDay = 0 Then 'All'
		--			Else convert(varchar(10), EventDay)
		--	   End as EventDay,
		--	   Case
		--			When EventWeekDay= 0 Then 'All'
		--			When EventWeekDay= 1 Then 'Sun'
		--			When EventWeekDay= 2 Then 'Mon'
		--			When EventWeekDay= 3 Then 'Tue'
		--			When EventWeekDay= 4 Then 'Wed'
		--			When EventWeekDay= 5 Then 'Thu'
		--			When EventWeekDay= 6 Then 'Fri'
		--			When EventWeekDay= 7 Then 'Sat'
		--	   End as EventWeekDay,
		--	   dbo.FN_GetTimeInFormat(FromField) as FromField,
		--	   dbo.FN_GetTimeInFormat(ToField) as ToField,
		--	   tbl1.ModifiedDate,
		--	   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
		--from tb_DateTimeBandDetail tbl1
		--inner join tb_RateDimensionBand tbl2 on tbl1.DateTimeBandID = tbl2.RateDimensionBandID
		--where RateDimensionTemplateID = @RateDimensionTemplateID

		Select tbl1.DateTimeBandDetailID as RateDimensionBandDetailID,
		      tbl2.RateDimensionBandID , tbl2.RateDimensionBand ,
			   EventYear, EventMonth,EventDay, EventWeekDay,
			   dbo.FN_GetTimeInFormat(FromField) as FromField,
			   dbo.FN_GetTimeInFormat(ToField) as ToField,
			   tbl1.ModifiedDate,
			   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
		from tb_DateTimeBandDetail tbl1
		inner join tb_RateDimensionBand tbl2 on tbl1.DateTimeBandID = tbl2.RateDimensionBandID
		where RateDimensionTemplateID = @RateDimensionTemplateID

End

Else
Begin

		Select tbl1.RateDimensionBandDetailID ,tbl2.RateDimensionBandID , tbl2.RateDimensionBand ,
			   FromField, ToField, ApplyFrom,
			   tbl1.ModifiedDate,
			   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
		from tb_RateDimensionBandDetail tbl1
		inner join tb_RateDimensionBand tbl2 on tbl1.RateDimensionBandID = tbl2.RateDimensionBandID
		where RateDimensionTemplateID = @RateDimensionTemplateID

End

Return 0
GO
