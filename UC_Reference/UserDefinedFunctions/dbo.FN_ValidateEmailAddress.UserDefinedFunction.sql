USE [UC_Reference]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_ValidateEmailAddress]    Script Date: 5/2/2020 6:30:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function [dbo].[FN_ValidateEmailAddress]
(
   @EmailAddress varchar(50)
)
Returns Int 
As

Begin 

	Declare @ReturnFlag int
	
	set @ReturnFlag = 0

	set @EmailAddress = isnull(@EmailAddress , '')

	set @EmailAddress = LTRIM(RTRIM(@EmailAddress)) -- remove leading and trailing blanks


	set @ReturnFlag = Case

				When patindex ('%[ &'',":;!+=\/()<>]%', @EmailAddress) > 0 then  1         -- Invalid characters
				When patindex ('[@.-_]%', @EmailAddress) > 0 then 1                        -- Valid but cannot be starting character
				When patindex ('%[@.-_]', @EmailAddress) > 0  then 1                       -- Valid but cannot be ending character
				When @EmailAddress not like '%@%.%'   then 1                               -- Must contain at least one @ and one .
				When @EmailAddress like '%..%'        then 1                               -- Cannot have two periods in a row
				When @EmailAddress like '%@%@%'       then 1                               -- Cannot have two @ anywhere
				When @EmailAddress like '%.@%' or @EmailAddress like '%@.%' then 1         -- Cant have @ and . next to each other
				When @EmailAddress like '%.cm' or @EmailAddress like '%.co' then 1         -- Unlikely. Probably typos 
				When @EmailAddress like '%.or' or @EmailAddress like '%.ne' then 1         -- Missing last letter
				When substring(@EmailAddress, 1,1) in ('|' , '-' , '_' , '<' , '>') then 1 -- Starts with special character
                Else 0
			End

	Return @ReturnFlag

End

GO
