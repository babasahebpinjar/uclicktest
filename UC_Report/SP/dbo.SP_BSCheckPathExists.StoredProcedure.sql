USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCheckPathExists]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_BSCheckPathExists]
@ParentFolder VARCHAR(255),
@DirName VARCHAR(255)
AS
BEGIN
DECLARE @ANSW BIT

CREATE TABLE #Temp(Directory varchar(255))

INSERT INTO #Temp
EXEC master..xp_subdirs @ParentFolder

IF EXISTS (Select * from #Temp WHERE Directory = @DirName)
SET @ANSW = 1 ELSE SET @ANSW = 0

DROP TABLE #Temp
RETURN @ANSW
END
GO
