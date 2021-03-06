USE [UC_Reference]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_ValidatePersonName]    Script Date: 5/2/2020 6:30:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[FN_ValidatePersonName]
(
   @PersonName varchar(50)
)
Returns Int 
As

Begin 

	Declare @ReturnFlag int
	
	set @ReturnFlag = 0

	set @PersonName = isnull(@PersonName , '')

	set @PersonName = LTRIM(RTRIM(@PersonName)) -- remove leading and trailing blanks


	set @ReturnFlag = Case

				When patindex ('%[&'',":;!+=\/()<>@._]%', @PersonName) > 0 then  1         -- Invalid characters
				When patindex ('[-]%', @PersonName) > 0 then 1                        -- Valid but cannot be starting character
				When patindex ('%[-]', @PersonName) > 0  then 1                       -- Valid but cannot be ending character
				When substring(@PersonName, 1,1) in ('|' , '-' , '_' , '<' , '>') then 1 -- Starts with special character
                Else 0
			End

	Return @ReturnFlag

End

GO
