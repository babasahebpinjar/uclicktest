USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardCDRErrorSummary]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashboardCDRErrorSummary]
As

Declare @StartDate datetime,
        @EndDate datetime,
		@CurrentDate Datetime



set @EndDate = convert(datetime ,convert(varchar(10) , getdate() , 120))

set @StartDate = convert(datetime ,
                           convert(varchar(4) , year(@EndDate)) + '-' +
                           right('0' + convert(varchar(2) , month(@EndDate)) , 2) + '-' +
				           '01')
						  

-----------------------------------------------------------
-- Get all the Error Records based on the date crietria
-----------------------------------------------------------

Delete from tb_DashboardCDRErrorSummary

insert into tb_DashboardCDRErrorSummary
(
	ErrorType ,
	Direction ,
	MinCallDate ,
	MaxCallDate ,
	Answered ,
	Seized ,
	CallDuration
)
select
       tbl2.CDRErrortype,
	   tbl3.Direction,
	   min(CallDate),
	   max(CallDate),
	   sum(Answered),
	   sum(Seized),
	   convert(Decimal(19,2) ,sum(CallDuration))  
from tb_CDRErrorSummary tbl1
inner join tb_CDRErrortype tbl2 on tbl1.Errortype = tbl2.CDRErrorTypeID
inner join REFERENCESERVER.UC_Reference.dbo.tb_Direction tbl3 on tbl1.DirectionID = tbl3.DirectionID
where tbl1.CallDate between @StartDate and @EndDate
group by tbl1.ErrorType , tbl2.CDRErrortype , tbl1.DirectionID, tbl3.Direction


Return 0
GO
