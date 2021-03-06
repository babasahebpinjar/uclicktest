USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDestinationUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIDestinationUpdate]
(
    @DestinationID int,
	@Destination varchar(60),
	@DestinationAbbrv varchar(30),
	@DestinationTypeID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------
-- Check the validity of the DestinationID passed to the 
-- API
-------------------------------------------------------

if ( ( @DestinationID is null ) )
Begin

	set @ErrorDescription = 'ERROR!!! DestinationID Cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End

if not exists (select 1 from tb_Destination where Destinationid = @DestinationID )
Begin

	set @ErrorDescription = 'ERROR!!! No record exists for the Destination ID'
	set @ResultFlag = 1
	return 1

End

----------------------------------------------------------
-- Get the numberplanID for the destination being updated
----------------------------------------------------------

Declare @NumberPlanID int

Select @NumberPlanID = numberplanid
from tb_Destination
where destinationID = @DestinationID

------------------------------------------------------------------
-- Check to ensure that Destination name , abbrv and code are not NULL
------------------------------------------------------------------

if ( ( @Destination is null ) or ((@Destination is not NULL) and (len(ltrim(rtrim(@Destination))) = 0) ))
Begin

	set @ErrorDescription = 'ERROR!!! Destination Cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End


if ( ( @DestinationAbbrv is null ) or ((@DestinationAbbrv is not NULL) and (len(ltrim(rtrim(@DestinationAbbrv))) = 0) ))
Begin

	set @ErrorDescription = 'ERROR!!! Destination Abbreviation Cannot be NULL or empty'
	set @ResultFlag = 1
	return 1

End


--------------------------------------------------------------
-- Check to ensure that the Destination name and abbreviation are
-- unique
--------------------------------------------------------------

if exists ( 
			select 1 
			from tb_Destination 
			where ( 
					Destination = ltrim(rtrim(@Destination))
					or 
					Destinationabbrv = ltrim(rtrim(@DestinationAbbrv))
				   ) 
				   and Destinationid <> @DestinationID 
				   and NumberPlanID = @NumberPlanID
				   and convert(date , GetDate()) between BeginDate and isNull(EndDate , convert(date , GetDate()))
		   )
Begin

	set @ErrorDescription = 'ERROR!!! Destination name or abbreviation have to be unique for each number plan. There cannot be more than one ACTIVE destination under same number plan'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------
-- Update the data into the tb_Destination table 
-----------------------------------------------

Begin Try

		update tb_Destination
		set Destination  = @Destination,
		    DestinationAbbrv  = @DestinationAbbrv, 
			DestinationTypeID  = @DestinationTypeID, 
			ModifiedDate = getdate(), 
			ModifiedByID = @UserID , 
			Flag = 0
		where Destinationid = @DestinationID


End Try

Begin Catch

		set  @ResultFlag = 1 
		set  @ErrorDescription = 'ERROR !!! Updating record for Destination. '+ ERROR_MESSAGE()
		Return 1	

End Catch

Return 0

GO
