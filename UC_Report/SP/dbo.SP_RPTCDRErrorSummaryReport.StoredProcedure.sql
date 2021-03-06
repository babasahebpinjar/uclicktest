USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTCDRErrorSummaryReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTCDRErrorSummaryReport]
(
	
	@StartDate datetime,
	@EndDate datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------------
-- Check to ensure that Start date is less then equal to End Date
------------------------------------------------------------------

if ( @StartDate > @EndDate )
Begin

		set @ErrorDescription = 'ERROR !!!! Start Call Date cannot be greater than End Call Date'
		set @ResultFlag = 1
		return 1

End

-----------------------------------------------------------
-- Get all the Error Records based on the date crietria
-----------------------------------------------------------

select tbl1.ErrorType as ErrorTypeID ,
       tbl2.CDRErrortype as ErrorType , 
	   tbl1.DirectionID, tbl3.Direction,
	   min(CallDate) as MinCallDate,
	   max(CallDate) as MaxCallDate,
	   sum(Answered) as Answered,
	   sum(Seized) as Seized,
	   convert(Decimal(19,2) ,sum(CallDuration)) as CallDuration   
from tb_CDRErrorSummary tbl1
inner join tb_CDRErrortype tbl2 on tbl1.Errortype = tbl2.CDRErrorTypeID
inner join REFERENCESERVER.UC_Reference.dbo.tb_Direction tbl3 on tbl1.DirectionID = tbl3.DirectionID
where tbl1.CallDate between @StartDate and @EndDate
group by tbl1.ErrorType , tbl2.CDRErrortype , tbl1.DirectionID, tbl3.Direction
order by tbl3.Direction , tbl1.ErrorType


Return 0
GO
