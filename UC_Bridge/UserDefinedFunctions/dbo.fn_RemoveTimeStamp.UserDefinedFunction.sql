USE [UC_Bridge]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_RemoveTimeStamp]    Script Date: 5/2/2020 6:45:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[fn_RemoveTimeStamp]
(
@FileName nvarchar(max)
)
returns nvarchar(max)
AS
BEGIN
  declare @bridgeIndex int;
  set @bridgeIndex = CHARINDEX('_BRIDGE_', @FileName )

  IF  @bridgeIndex > 0 
	BEGIN
	   declare @finalFileName nvarchar(max);
	   SELECT @finalFileName = SUBSTRING(@FileName, 1, @bridgeIndex-1)
	   select @finalFileName = @finalFileName + REVERSE(SUBSTRING(REVERSE(@FileName),0,CHARINDEX('.',REVERSE(@FileName))+1))
	   return @finalFileName
	END
  
  return @FileName	
END
GO
