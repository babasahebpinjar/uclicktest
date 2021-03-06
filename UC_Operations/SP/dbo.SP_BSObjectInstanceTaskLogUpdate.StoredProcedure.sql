USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSObjectInstanceTaskLogUpdate]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSObjectInstanceTaskLogUpdate]
(
	@ObjectInstanceTaskLogID varchar(100),
	@TaskEndDate datetime,
	@CommentLog varchar(2000),
	@Measure1 int,
	@Measure2 int,
	@Measure3 int,
	@Measure4 int,
	@Measure5 int
)
As

Update tb_ObjectInstanceTaskLog
set TaskEndDate = 
            Case 
			    when @TaskEndDate is not NULL then Getdate()
				Else TaskEndDate
			End,
    CommentLog = 
	        Case
				When CommentLog is NULL then @CommentLog
				Else CommentLog + '<b>' + @CommentLog
			End,
	Measure1 =  Case when @Measure1 is NULL then Measure1 Else @Measure1 End,
	Measure2 =  Case when @Measure2 is NULL then Measure2 Else @Measure2 End,
	Measure3 =  Case when @Measure3 is NULL then Measure3 Else @Measure3 End,
	Measure4 =  Case when @Measure4 is NULL then Measure4 Else @Measure4 End,
	Measure5 =  Case when @Measure5 is NULL then Measure5 Else @Measure5 End
where ObjectInstanceTaskLogID = @ObjectInstanceTaskLogID

Return 0
GO
