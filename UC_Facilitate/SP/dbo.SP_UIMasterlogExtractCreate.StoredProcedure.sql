USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMasterlogExtractCreate]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMasterlogExtractCreate]
(

	@UserID int,
	@CallID varchar(500) = NULL , 
	@CallingNumber varchar(500) = NULL ,
    @CalledNumber varchar(500) = NULL ,
    @MasterlogExtractName varchar(100) = NULL ,
    @ExtractDescription varchar(100) = NULL,

	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output

)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check to see if the User ID is valid and is active
----------------------------------------------------------

if not exists ( select 1 from ReferenceServer.UC_Admin.dbo.tb_Users where UserID = @UserID and USerstatusID = 1 )
Begin

		set @ErrorDescription = 'ERROR !!!! User ID passed for extract creation does not exist or is inactive'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------------------------
-- Check to see that there does not exist another Masterlog Extract with the same name
-- for the user
---------------------------------------------------------------------------------

if exists ( select 1 from tb_MasterlogExtract where MasterlogExtractName = @MasterlogExtractName and userID = @UserID )
Begin

		set @ErrorDescription = 'ERROR !!!! There already exists a Masterlog extract in the system by the same name for this user'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

if (( @CallID is not Null ) and ( len(@CallID) = 0 ) )
Begin
	set @CallID = NULL
End

if (( @CallingNumber is not Null ) and ( len(@CallingNumber) = 0 ) )
Begin	
	set @CallingNumber = NULL
End

if (( @CalledNumber is not Null ) and ( len(@CalledNumber) = 0 ) )
Begin	
	set @CalledNumber = NULL
End

if ( ( @CallID <> '_') and charindex('_' , @CallID) <> -1 )
Begin

	set @CallID = replace(@CallID , '_' , '[_]')

End

if ( ( @CallingNumber <> '_') and charindex('_' , @CallingNumber) <> -1 )
Begin

	set @CallingNumber = replace(@CallingNumber , '_' , '[_]')

End

if ( ( @CalledNumber <> '_') and charindex('_' , @CalledNumber) <> -1 )
Begin

	set @CalledNumber = replace(@CalledNumber , '_' , '[_]')

End



--------------------------------------------------------------------
-- insert the new MastelogExtract Extract data into the schema for Registration
--------------------------------------------------------------------

Declare @MasterlogExtractID int

Begin Transaction ins_Extract

Begin Try

			------------------------------------------------
			-- Insert record into the table tb_MasterlogExtract
			------------------------------------------------

			insert into tb_MasterlogExtract
			(
				MasterlogExtractName , UserID , MasterlogExtractStatusID,
                MasterlogExtractRequestDate,ModifiedDate, ModifiedByID
			)
			Values
			(
				@MasterlogExtractName , @UserID , -1 ,
				GetDate() , GetDate() , @UserID
			)

			select @MasterlogExtractID = MasterlogExtractID
			from tb_MasterlogExtract
			where MasterlogExtractName = @MasterlogExtractName
			and MasterlogExtractStatusID = -1 -- Registered
			and UserID = @UserID

			insert into tb_MasterlogExtractParamList
			(
				MasterlogExtractID, CallID,
				CallingNumber, CalledNumber,
				ModifiedDate, ModifiedByID
			)
			Values
			(
				@MasterlogExtractID , @CallID,
				@CallingNumber, @CalledNumber,
				GetDate() , @UserID
			)

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!! While inserting record for new Masterlog extract. ' + ERROR_MESSAGE()
			set @ResultFlag = 1

			Rollback Transaction ins_Extract

			GOTO ENDPROCESS

End Catch


Commit transaction ins_Extract

-------------------------------------------------------------
-- Check to see if Masterlog Extract via email has been enabled in 
--  the system
-------------------------------------------------------------

Declare @SendMasterlogExtractAlertViaEmail int

select @SendMasterlogExtractAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendMasterlogExtractAlertViaEmail'
and AccessScopeID = -8 

if ( @SendMasterlogExtractAlertViaEmail = 1 )
Begin

		Exec SP_BSMasterlogExtractAlert @MasterlogExtractID

End 


ENDPROCESS:

Return 0
GO
