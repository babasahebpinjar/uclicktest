USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_TempTrafficMarginAndQOS]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_TempTrafficMarginAndQOS]
(
	@BeginDate date,
	@EndDate date
)
As

Select INAccount , OutAccount , Country , Destination,
       count(*) as Seized,
	   sum( Case When CallDuration > 0 then 1 Else 0 End) as Answered,
	   convert(int ,(sum( Case When CallDuration > 0 then 1 Else 0 End) * 100.0)/Count(*)) as ASR,
	   convert(decimal(19,2) ,sum(CallDurationMinutes)) as Minutes,
	   convert(decimal(19,2) ,sum(CallDurationMinutes)/sum( Case When CallDuration > 0 then 1 Else 0 End)) as ALOC,
	   convert(decimal(19,4) ,sum(isnull(INAmount,0))/sum(CallDurationMinutes)) as RPM,
	   convert(decimal(19,4) ,sum(isnull(OUTAmount,0))/sum(CallDurationMinutes)) as CPM,
	   convert(decimal(19,2) ,sum(isnull(INAmount,0))) as Revenue,
	   convert(decimal(19,2) ,sum(isnull(OUTAmount,0))) as Cost,
	   convert(decimal(19,2) ,sum(isnull(INAmount,0))) - convert(decimal(19,2) ,sum(isnull(OUTAmount,0))) as Margin
From tb_CDRFileDataAnalyzed
where CallDate between @BeginDate and @EndDate
group by INAccount , OutAccount , Country , Destination
having sum(CallDurationMinutes) > 0
order by 14 desc

return 0
GO
