USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanGroupUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanGroupUpdate]
(
    @RatePlanGroupID int,
	@RatePlanGroup varchar(60),
	@RatePlanGroupAbbrv varchar(20),
	@UserID int ,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription  = NULL
set @ResultFlag = 0

-------------------------------------------------------------
-- Check to ensure that the RatePlanGroupID is valid value
-------------------------------------------------------------

if ( @RatePlanGroupID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


if not exists ( select 1 from tb_RatePlanGroup where RatePlanGroupID  = @RatePlanGroupID )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group ID does not exist or is not valid'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------------------
-- Check that the Rate plan group or abbreviation are not NULL
-----------------------------------------------------------------

if ((@RatePlanGroup is NULL ) or (@RatePlanGroupAbbrv is NULL) )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group name or abbreviation is NULL'
	set @ResultFlag = 1
	return 1


End
-----------------------------------------------------------------
-- Check that the Rate plan group and abbreviation are unique
-----------------------------------------------------------------

if exists ( 
				select 1 
				from tb_rateplangroup 
				where  (
							ltrim(rtrim(rateplangroup)) = ltrim(rtrim(@RatePlanGroup))
							or 
							ltrim(rtrim(RatePlanGroupAbbrv)) = ltrim(rtrim(@RatePlanGroupAbbrv)) 
					   )
					   and RatePlanGroupID <> @RatePlanGroupID 
		  )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group name or abbreviation is not unique'
	set @ResultFlag = 1
	return 1


End

-----------------------------------------------------
-- Update record into the tb_RatePlanGroup table
-----------------------------------------------------

Begin Try

		Update tb_RatePlanGroup
		set RatePlanGroup = @RatePlanGroup ,
		    RatePlanGroupAbbrv = @RatePlanGroupAbbrv,
			ModifiedDate = getdate(),
			ModifiedByID = @UserID
		where RatePlanGroupID = @RatePlanGroupID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Updating Rate Plan Group details.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch
GO
