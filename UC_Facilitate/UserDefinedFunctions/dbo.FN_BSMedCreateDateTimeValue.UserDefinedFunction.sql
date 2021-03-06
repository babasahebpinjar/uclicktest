USE [UC_Facilitate]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_BSMedCreateDateTimeValue]    Script Date: 5/2/2020 6:48:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[FN_BSMedCreateDateTimeValue]
(
	@DateString varchar(200)
)
Returns DateTime
As

Begin

    DEclare @ReturnDateTime datetime

    if @DateString is NULL
	Begin
	   	set @ReturnDateTime = NULL
	End

	Else
	Begin
	        set @ReturnDateTime = 
			convert (DateTime ,
			substring(@DateString , 7,4) + '-'+
			substring(@DateString , 4,2) + '-'+
			substring(@DateString , 1,2) + ' '+
			substring(@DateString , 12, 8) + '.' +
			substring(@DateString , 21, 3))
	End

	Return @ReturnDateTime

End
GO
