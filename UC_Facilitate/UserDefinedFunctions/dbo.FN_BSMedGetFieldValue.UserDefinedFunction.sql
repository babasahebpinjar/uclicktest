USE [UC_Facilitate]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_BSMedGetFieldValue]    Script Date: 5/2/2020 6:48:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[FN_BSMedGetFieldValue]
(
	@CompleteString Varchar(Max),
	@FieldNumber int,
	@FieldDelimiter varchar(20)
)
returns varchar(100)
As

Begin

		Declare @RunningCounter int = 0,
		        @TempString varchar(Max),
		        @TotalRecordLength int,
				@TotalRecordLengthWithoutDelimiter int,
				@TotalNumberOfFields int,
				@RecordFoundFlag int = 0,
				@FinalString varchar(100) = NULL

		Set @TotalRecordLength = Len(@CompleteString)

		Set @TotalRecordLengthWithoutDelimiter = Len(Replace(@CompleteString , @FieldDelimiter , ''))

		set @TotalNumberOfFields = ( @TotalRecordLength - @TotalRecordLengthWithoutDelimiter ) + 1
				
        set @TempString = @CompleteString

		-----------------------------------------------------------------------------
		-- Handle exception where Field Number to extract is by mistake greater than
		-- Total Number Of Fields
		------------------------------------------------------------------------------

		if ( @TotalNumberOfFields < @FieldNumber )
		Begin

				set @FinalString = NULL

		End

		if ( @FieldNumber = 1 )
		Begin

				set @FinalString = substring(@TempString , 1 , charindex(@FieldDelimiter , @TempString) - 1 )
				set @RecordFoundFlag = 1

		End

		While ( ( @RunningCounter <= @TotalNumberOfFields ) and ( @RecordFoundFlag = 0 ) )
		Begin
			
				set @TempString = substring(@TempString , charindex(@FieldDelimiter , @TempString) + 1 , len(@TempString))
				set @RunningCounter = @RunningCounter + 1

				if  (@FieldNumber = (@RunningCounter + 1))
				Begin

				        if ( @TotalNumberOfFields > @FieldNumber )
						Begin

								set @FinalString = substring(@TempString , 1 , CHARINDEX(@FieldDelimiter , @TempString) - 1)
								set @RecordFoundFlag = 1

						End

				        if ( @TotalNumberOfFields = @FieldNumber )
						Begin

								set @FinalString = substring(@TempString , 1 , len(@TempString))
								set @RecordFoundFlag = 1

						End

				End

		End
		
		Return @FinalString
End
GO
