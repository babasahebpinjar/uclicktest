USE [UC_Admin]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_GetUserName]    Script Date: 02-05-2020 14:39:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Function [dbo].[FN_GetUserName]
(
	@UserId int
)
returns varchar(30) As

Begin

		Declare @UserName varchar(30) = 'Invalid User' 
		
		select @UserName = name
		from tb_users
		where userid = @UserId
		
		return isnull(@UserName , 'Invalid User' ) 

End


GO
