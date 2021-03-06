USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIServiceLevelUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIServiceLevelUpdate]
(
    @ServiceLevelID int,
	@ServiceLevel varchar(60),
	@ServiceLevelAbbrv varchar(20),
	@RoutingFlag varchar(5),
	@PriorityOrder int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------------
-- Validate all the input information for semantics and syntax
---------------------------------------------------------------

if (@ServiceLevelID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Service Level ID is NULL'
	set @ResultFlag = 1
	return 1

End

if not exists (Select 1 from tb_ServiceLevel where ServiceLevelID = @ServiceLevelID)
Begin

	set @ErrorDescription = 'ERROR !!! There does not exist any Service Level record in the system for input Service Level ID'
	set @ResultFlag = 1
	return 1

End


if (@ServiceLevel is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Service Level is NULL'
	set @ResultFlag = 1
	return 1

End

if (@ServiceLevelAbbrv is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Service Level Abbreviation is NULL'
	set @ResultFlag = 1
	return 1

End

if  ( (@RoutingFlag is NULL) or ( @RoutingFlag not in ('No', 'Yes') ) )
Begin

	set @ErrorDescription = 'ERROR !!! Routing Flag is NULL or has invalid value. Valid values are (No, Yes) '
	set @ResultFlag = 1
	return 1

End

if ( (@PriorityOrder is NULL) or ( @PriorityOrder < 0 ))
Begin

	set @ErrorDescription = 'ERROR !!! Priority Order is NULL or has invalid values. Please give numerical value greater than 0'
	set @ResultFlag = 1
	return 1

End

-------------------------------------------------------------------------
-- Check for any duplicate entries for the service level and abbreviation
-------------------------------------------------------------------------

if exists ( select 1 from tb_servicelevel where  ServiceLevelID <> @ServiceLevelID and (ltrim(rtrim(servicelevel)) = ltrim(rtrim(@ServiceLevel)) or ltrim(rtrim(servicelevelabbrv)) = ltrim(rtrim(@ServiceLevelAbbrv)) ))
Begin

	set @ErrorDescription = 'ERROR !!! Service Level Name or Abbreviation is duplicate and already exists'
	set @ResultFlag = 1
	return 1


End

------------------------------------------------------------------------
-- Check if ay service level entry exists with the same priority order
------------------------------------------------------------------------

if exists ( select 1 from tb_servicelevel where PriorityOrder = @PriorityOrder and ServiceLevelID <> @ServiceLevelID)
Begin

	set @ErrorDescription = 'ERROR !!! Service Level record already exists with the same priority order. Please change the priority order for new or old service level'
	set @ResultFlag = 1
	return 1


End

----------------------------------------------------------
--  Insert record into the database for new service level
----------------------------------------------------------

Begin Try

    update tb_servicelevel
	set ServiceLevel = @ServiceLevel,
	    ServiceLevelAbbrv = @ServiceLevelAbbrv,
		RoutingFlag = 		Case 
								when @RoutingFlag = 'No' Then 0
								when @RoutingFlag = 'Yes' Then 1
							End ,
        PriorityOrder = @PriorityOrder ,
		ModifiedDate = Getdate(),
		ModifiedByID = @UserID
     Where ServiceLevelID = @ServiceLevelID


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While updating the ServiceLevel record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch
GO
