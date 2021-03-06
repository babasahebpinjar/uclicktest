USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SP_UIEntityGroupGetDetails] 
(
	@EntityGroupID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


if ( @EntityGroupID is null )
Begin

		set @ErrorDescription = 'ERROR !!! Entity Group ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_EntityGroup where EntityGroupID = @EntityGroupID )
Begin

		set @ErrorDescription = 'ERROR !!! Entity Group does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

select tbl1.EntityGroupID , tbl1.EntityGroup , tbl1.EntityGroupAbbrv , 
       tbl2.EntityGroupTypeID , tbl2.EntityGroupType
from tb_EntityGroup tbl1
inner join tb_EntityGroupType tbl2 on tbl1.EntityGroupTypeID = tbl2.EntityGroupTypeID
where EntityGroupID = @EntityGroupID

Return 0

GO
