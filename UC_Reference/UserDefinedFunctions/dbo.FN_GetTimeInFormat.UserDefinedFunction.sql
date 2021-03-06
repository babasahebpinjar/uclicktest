USE [UC_Reference]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_GetTimeInFormat]    Script Date: 5/2/2020 6:30:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[FN_GetTimeInFormat]
(
	@TimeInSeconds int
)
Returns Varchar(8) As

Begin

	Declare @TimeInFormat varchar(8),
			@HourOfDay varchar(2),
			@MinuteOfDay varchar(2),
			@SecOfDay varchar(2)

	set @HourOfDay = Right('0' + convert(varchar(2) ,@TimeInSeconds/3600) , 2)
	set @MinuteOfDay = Right('0' + convert(varchar(2) ,(@TimeInSeconds%3600)/60) , 2)
	set @SecOfDay = Right('0' + convert(varchar(2) ,((@TimeInSeconds%3600)%60)) , 2)

	select @TimeInFormat = @HourOfDay + ':' + @MinuteOfDay + ':' + @SecOfDay

	Return @TimeInFormat


End
GO
