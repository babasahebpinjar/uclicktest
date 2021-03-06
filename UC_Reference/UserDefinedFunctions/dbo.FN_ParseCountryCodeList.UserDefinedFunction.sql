USE [UC_Reference]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_ParseCountryCodeList]    Script Date: 5/2/2020 6:30:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function [dbo].[FN_ParseCountryCodeList]
(
	@CountryCode varchar(100)
)
Returns @DialCodeList table ( Dialcode varchar(100) )
As

Begin

		Declare @Tempstring varchar(100) = @CountryCode,
		        @DialCode varchar(100) = ''


		while ( len(@Tempstring) > 0 )
		Begin

					----------------------------------------------
					-- Only non numeric values allowed are ","
					----------------------------------------------

					if ( substring(@Tempstring , 1 , 1)  = ',' )
					Begin
					        
							if ( len(rtrim(ltrim(@DialCode))) > 0 )
							Begin

									insert into @DialCodeList values ( rtrim(ltrim(@DialCode)) )

							End

							set @DialCode = ''

					End


					Else
					Begin
				      
							set @DialCode = @DialCode + substring(@Tempstring , 1 , 1)

					End

					set @Tempstring = substring(@Tempstring , 2 , len(@Tempstring))

		End

		if ( len(rtrim(ltrim(@DialCode))) > 0 )
		Begin

				insert into @DialCodeList values ( rtrim(ltrim(@DialCode)) )

		End

		Return
		
End




GO
