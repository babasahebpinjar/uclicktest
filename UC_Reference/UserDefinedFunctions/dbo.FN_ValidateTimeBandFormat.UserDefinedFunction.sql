USE [UC_Reference]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_ValidateTimeBandFormat]    Script Date: 5/2/2020 6:33:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[FN_ValidateTimeBandFormat]
(
	@TimeBand varchar(8)
)
Returns int
As

Begin

		Declare @ValidFlag int = 0, -- 0 Valid , 1 InValid
		        @Hour varchar(2) = substring(@TimeBand , 1,2),
				@Minute varchar(2) = substring(@TimeBand , 4,2),
				@Second varchar(2) = substring(@TimeBand , 7,2)

        if (len(@TimeBand) <> 8 )
		Begin

			set @ValidFlag = 1
			GOTO ENDRESULT

		End

		if ( 
			  (	ISNUMERIC(@Hour) = 0 )
			  or
			  (	ISNUMERIC(@Minute) = 0 )
			  or
			  (	ISNUMERIC(@Second) = 0 )
		   )
		Begin

				set @ValidFlag = 1
				GOTO ENDRESULT

		End

		if ( 
			  (	Convert(int ,@Hour) > 23 )
			  or
			  (	Convert(int , @Minute) > 59 )
			  or
			  (	Convert(int ,@Second) > 59 )
		   )
		Begin

				set @ValidFlag = 1
				GOTO ENDRESULT

		End

ENDRESULT:

		Return @ValidFlag

End
GO
