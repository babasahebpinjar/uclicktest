USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkDetailDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UITechnicalTrunkDetailDelete]
(
	@TrunkDetailID int,
	@UserID int ,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

-------------------------------------------------------------
-- Perform all the essential validations before deleting the
-- trunk detail recodr from the system
-------------------------------------------------------------

if ( @TrunkDetailID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Need to provide the Technical Trunk Detail ID whih needs to be deleted'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_TrunkDetail where TrunKDetailID = @TrunkDetailID )
Begin

		set @ErrorDescription = 'ERROR !!! Technical Trunk Detail does not exist. Please check the same'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------------------------
-- If the provided technical detail is the only record for the trunk
-- then it cannot be deleted
--------------------------------------------------------------------

Declare @TrunkID int

Select @TrunkID = TrunkID
from tb_TrunkDetail
where TrunKDetailID = @TrunkDetailID

if ( (select count(*) from tb_TrunkDetail where trunkid = @TrunkID and flag & 1 <> 1 ) = 1 )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete the only attribute detail record existing for the technical trunk'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------------------
-- Check if deletion of this Technical Detail record will cause
-- overlapping CDR match record or not
--------------------------------------------------------------

Declare @CDRMatch varchar(60),
        @SwitchID int,
		@ResultFlag2 int = 0

select @CDRMatch = CDRMatch,
       @SwitchID = SwitchID
from tb_trunk
where trunkID = @TrunkID

Exec SP_BSCheckOverlappingActiveTrunksOnAttributeDelete @CDRMatch , @SwitchID , @TrunkID , @TrunkDetailID , @ResultFlag2 output

if (@ResultFlag2 = 1)
Begin

		set @ErrorDescription = 'ERROR !!! Deleting the trunk detail leads to overlapping CDR Match condition for CDR Match : ' + @CDRMatch
		set @ResultFlag = 1
		Return 1

End


---------------------------------------------------
-- Delete the trunk detail record from the system
---------------------------------------------------

Begin Try

	Delete from tb_trunkdetail
	where trunkdetailID = @TrunkDetailID

End Try


Begin Catch

		set @ErrorDescription = 'ERROR !!! Deleting the trunk detail record. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch

GO
