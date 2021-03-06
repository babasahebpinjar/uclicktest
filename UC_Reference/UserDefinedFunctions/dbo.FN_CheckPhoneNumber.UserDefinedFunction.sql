USE [UC_Reference]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_CheckPhoneNumber]    Script Date: 5/2/2020 6:30:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function [dbo].[FN_CheckPhoneNumber]
(
	@PhuneNumber varchar(50)
)
Returns INT as

Begin

	Declare @StatusFlag int = 0,
			@Tempstring varchar(50) = @PhuneNumber

    if ( (@PhuneNumber is NULL) or  ( (@PhuneNumber is not NULL) and (len(ltrim(rtrim(@PhuneNumber))) = 0) ) )
	Begin

			set @StatusFlag = 1
			GOTO ENDPROCESS

	End

	while ( len(@Tempstring) > 0 )
	Begin

			if ( isnumeric(substring(@Tempstring , 1 , 1)) = 0 )
			Begin

			    ----------------------------------------------
				-- Only non numeric values allowed are + and -
				----------------------------------------------

				if ( substring(@Tempstring , 1 , 1) not in ('+' , '-' ) )
				Begin
					
					 set  @StatusFlag = 1 -- Invalid Value
					 set  @Tempstring = '' -- Set string length to 0  	

				End

			End

			set @Tempstring = substring(@Tempstring , 2 , len(@Tempstring))

	End

ENDPROCESS:

	return @StatusFlag

End
GO
