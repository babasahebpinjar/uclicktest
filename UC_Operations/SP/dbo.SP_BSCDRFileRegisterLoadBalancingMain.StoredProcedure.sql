USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRFileRegisterLoadBalancingMain]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRFileRegisterLoadBalancingMain]
As

Declare @ErrorDescription varchar(2000),
	    @ResultFlag int 

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @InstanceID int,
        @InstanceName varchar(200),
		@ObjectName varchar(200),
		@ObjectID int


Select @ObjectID = ObjectID,
       @ObjectName = ObjectName
from tb_Object
where ObjectTypeId = 101


------------------------------------------------
-- Build the name of the Object Instance
------------------------------------------------

set @InstanceName = @ObjectName + ' ' + convert(varchar(20) , getdate() , 120 )

-----------------------------------------------------------
-- Insert the record for the new Instance into the schema
-----------------------------------------------------------

insert into tb_ObjectInstance
(
	ObjectID,
	ObjectInstance,
	StatusID,
	ProcessStartTime,
	ProcessEndTime ,
	ModifiedDate,
	ModifiedByID
)
select @ObjectID ,
		@InstanceName,
		10110, -- CDR Collect Registered
		Getdate(),
		NULL,
		Getdate(),
		-1


-----------------------------------------------------------------
-- Get the InstanceID for the newly inserted Object Instance
-----------------------------------------------------------------

select @InstanceID = ObjectInstanceID
from tb_ObjectInstance
where ObjectInstance = @InstanceName
and StatusID = 10110

------------------------------------------------------------------
-- Get all the parameter values before calling the main procedure
-- for registering the CDR files in system
------------------------------------------------------------------

Declare @FileNameTag varchar(50) ,
		@FileExtension varchar(50) ,
		@ControlFileExtension varchar(50) ,
		@CDRFileLocation varchar(1000) ,
		@CDRDestinationLocation varchar(1000)

Exec SP_BSGetObjectParamValue @InstanceID , 'FileNameTag' , @FileNameTag Output

if ( @FileNameTag is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! FileNameTag is not defined for CDR Collect and Load Balancing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

Exec SP_BSGetObjectParamValue @InstanceID , 'FileExtension' , @FileExtension Output

if ( @FileExtension is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! FileExtension is not defined for CDR Collect and Load Balancing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End


Exec SP_BSGetObjectParamValue @InstanceID , 'ControlFileExtension' , @ControlFileExtension Output

if ( @ControlFileExtension is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! ControlFileExtension is not defined for CDR Collect and Load Balancing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

Exec SP_BSGetObjectParamValue @InstanceID , 'CDRFileSource' , @CDRFileLocation Output

if ( @CDRFileLocation is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! CDRFileSource is not defined for CDR Collect and Load Balancing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End


Exec SP_BSGetObjectParamValue @InstanceID , 'CDRFileDestination' , @CDRDestinationLocation Output

if ( @CDRDestinationLocation is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! CDRFileDestination is not defined for CDR Collect and Load Balancing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End


-----------------------------------------------------------------
-- Call the procedure to perform the CDR Collection and Load 
-- balancing
-----------------------------------------------------------------
Begin Try


	Exec SP_BSCDRFileRegisterLoadBalancing  @InstanceID,
	                                        @FileNameTag ,
		                                    @FileExtension ,
		                                    @ControlFileExtension,
		                                    @CDRFileLocation ,
		                                    @CDRDestinationLocation ,
											@ErrorDescription Output,
											@ResultFlag Output



	if ( @ResultFlag = 1 )
	Begin
	
			GOTO ENDPROCESS

	End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! During CDR file Collection and Load Balancing. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch


ENDPROCESS:

---------------------------------------------------
-- Set the status of the Object instance, based on
-- Result flag
--------------------------------------------------

update tb_ObjectInstance
set StatusID = 
       Case
			When @ResultFlag = 0 then 10112 -- CDR Collect Completed
			When @ResultFlag = 1 then 10113 -- CDR Collect Failed
	   End,
	ProcessEndTime = getdate(),
	Remarks = 
       Case
			When @ResultFlag = 0 then NULL 
			When @ResultFlag = 1 then @ErrorDescription 
	   End
Where ObjectInstanceID = @InstanceID




GO
