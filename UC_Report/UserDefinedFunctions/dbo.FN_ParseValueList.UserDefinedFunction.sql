USE [UC_Report]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_ParseValueList]    Script Date: 5/2/2020 6:40:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[FN_ParseValueList]
(
	@VariableValue nvarchar(max)
)
Returns @ValueList table ( RecordValue varchar(100) )
As

Begin

		Declare @Tempstring nvarchar(max) = @VariableValue,
		        @TempValue varchar(100) = ''


		while ( len(@Tempstring) > 0 )
		Begin

					----------------------------------------------
					-- Only non numeric values allowed are ","
					----------------------------------------------

					if ( substring(@Tempstring , 1 , 1)  = ',' )
					Begin
					        
							if ( len(rtrim(ltrim(@TempValue))) > 0 )
							Begin

									insert into @ValueList values ( rtrim(ltrim(@TempValue)) )

							End

							set @TempValue = ''

					End


					Else
					Begin
				      
							set @TempValue = @TempValue + substring(@Tempstring , 1 , 1)

					End

					set @Tempstring = substring(@Tempstring , 2 , len(@Tempstring))

		End

		if ( len(rtrim(ltrim(@TempValue))) > 0 )
		Begin

				insert into @ValueList values ( rtrim(ltrim(@TempValue)) )

		End

		Return
		
End



GO
