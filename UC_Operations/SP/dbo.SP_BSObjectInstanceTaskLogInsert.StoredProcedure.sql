USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSObjectInstanceTaskLogInsert]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSObjectInstanceTaskLogInsert]
(
    @InstanceID int,
	@TaskName varchar(500),
	@ObjectInstanceTaskLogID varchar(100) Output
)
As

------------------------------------------------------------
-- Insert a record in the tb_ObjectInstanceTaskLog table
-- for the new task
------------------------------------------------------------

Declare @TaskStartDate datetime

set @TaskStartDate = Getdate()

set @ObjectInstanceTaskLogID = convert(varchar(100), @InstanceID) + '-' + 
                        replace(replace(replace(convert(varchar(30) , @TaskStartDate , 120), '-' , ''), ' ', ''), ':', '') + '-' +
						convert(varchar(5) ,convert(int ,rand() * 1000))

insert into tb_ObjectInstanceTaskLog
(
	ObjectInstanceTaskLogID,
	ObjectInstanceID,
	TaskName,
	TaskStartDate
)
Values
(
	@ObjectInstanceTaskLogID,
	@InstanceID,
	@TaskName,
	@TaskStartDate
)

Return 0
GO
