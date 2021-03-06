USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPrepaidThresholdList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIPrepaidThresholdList]
(
	@AccountID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

----------------------------------------------------------------
-- Check if the AccountID exists in the system and is not NULL
----------------------------------------------------------------
set @ResultFlag = 0
if (@AccountID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!!AccountID cannot be a NULL value'
		set @ResultFlag = 1
		Return 1

End

if not exists (Select 1 from tb_Account where AccountID = @AccountID)
Begin

		set @ErrorDescription = 'ERROR !!! AccountID is not valid or does not exist in the system'
		set @ResultFlag = 1
		Return 1

End


--------------------------------------------------------
-- Get list of all the threhold records for the account
--------------------------------------------------------

select ppth.PrepaidThresholdID,
       ppth.Threshold_1,
	   ppth.Threshold_2,
	   ppth.BeginDate,
	   ppth.EndDate,
	   Case
			When convert(date , getdate()) between ppth.BeginDate and isnull(ppth.EndDate , convert(date , getdate())) Then 0
			Else
				Case
						When ppth.BeginDate < convert(date , getdate()) and ppth.EndDate < convert(date , getdate()) Then 1
						When ppth.BeginDate > convert(date , getdate()) and isnull(ppth.EndDate , ppth.BeginDate) > convert(date , getdate()) Then 2
				End

	   End as ThresholdType, -- 0 : Present , 1 : Past , 2 : Future
	   ppth.ModifiedDate,
	   us.Name as ModifiedBy
from tb_PrepaidThreshold ppth
inner join UC_Admin.dbo.tb_Users us on ppth.ModifiedByID = us.UserID
where ppth.AccountID = @AccountID
order by ppth.BeginDate

Return 0

GO
