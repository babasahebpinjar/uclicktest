USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtracMain]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRExtracMain]
(
	@CDRExtractID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output 
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @UserID int,
        @SendCDRExtractAlertViaEmail int,
		@CDRExtractName varchar(500)

-------------------------------------------------------------
-- Check to see if CDR Extract via email has been enabled in 
--  the system
-------------------------------------------------------------

select @SendCDRExtractAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendCDRExtractAlertViaEmail'
and AccessScopeID = -8 

---------------------------------------------------------------
-- Check to see that the passed CDR Extract ID exists in the
-- system, and is in Registered state
----------------------------------------------------------------

if not exists ( select 1 from tb_CDRExtract where CDRExtractID = @CDRExtractID and CDRExtractStatusID = -1 ) -- Registered
Begin

		set @ErrorDescription = 'ERROR !!!! There is either no CDR extract in the system for passed ID, or it is not in Registered state'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

-------------------------------------------------
-- Get the USERID details from the CDR Extract
--------------------------------------------------

select @UserID = UserID,
       @CDRExtractName = CDRExtractName
from tb_CDRExtract
where CDRExtractID = @CDRExtractID

--------------------------------------------------------------
-- Get the essential parameters for initiating the CDR Extract
--------------------------------------------------------------

Declare @BeginDate datetime,
        @EndDate datetime, 
   	    @CallTypeID int,
		@INAccountIDList nvarchar(max) ,
		@OUTAccountIDList nvarchar(max),
		@INCommercialTrunkIDList nvarchar(max),
		@OUTCommercialTrunkIDList nvarchar(max),
		@INTechnicalTrunkIDList nvarchar(max),
		@OUTTechnicalTrunkIDList nvarchar(max),
		@CountryIDList nvarchar(max),
		@DestinationIDList nvarchar(max),
 		@ServiceLevelIDList nvarchar(max),
		@ConditionClause nvarchar(max),
        @DisplayFieldList nvarchar(max),
		@CDRExtractFileName varchar(1000)

Select  @BeginDate  = BeginDate,
        @EndDate = EndDate,
   	    @CallTypeID = CallTypeID,
		@INAccountIDList = INAccountList,
		@OUTAccountIDList  = OUTAccountList,
		@INCommercialTrunkIDList = INCommercialTrunkList ,
		@OUTCommercialTrunkIDList = OUTCommercialTrunkList,
		@INTechnicalTrunkIDList = INTechnicalTrunkList,
		@OUTTechnicalTrunkIDList = OUTTechnicalTrunkList ,
		@CountryIDList  = CountryList,
		@DestinationIDList  = DestinationList,
 		@ServiceLevelIDList = ServiceLevelList,
		@ConditionClause  = ConditionClause,
        @DisplayFieldList  = DisplayFieldList
From tb_CDRExtractParamList
where CDRExtractID = @CDRExtractID

--------------------------------------------------------------
-- Change the status of the CDR Extract to Running and call
-- the execution procedure
---------------------------------------------------------------

Update tb_CDRExtract
set CDRExtractStatusID = -2 -- Running
where CDRExtractID = @CDRExtractID
and CDRExtractStatusID = -1 -- Registered

if ( @SendCDRExtractAlertViaEmail = 1 )
Begin

	Exec SP_BSCDRExtractAlert @CDRExtractID

End

Begin Try

		if (substring(@CDRExtractName , 1, 12) = 'Full Extract')
		Begin

				Exec SP_BSCDRExtractGenerateFull @BeginDate , @EndDate , @CallTypeID , @INAccountIDList,
											 @OutAccountIDList, @INCommercialTrunkIDList , @OUTCommercialTrunkIDList,
											 @INTechnicalTrunkIDList , @OUTTechnicalTrunkIDList, @CountryIDList,
											 @DestinationIDList , @ServiceLevelIDList , @ConditionClause , @DisplayFieldList,
											 @CDRExtractFileName Output , @ErrorDescription Output , @ResultFlag Output

		End

		Else
		Begin

				Exec SP_BSCDRExtractGenerate @BeginDate , @EndDate , @CallTypeID , @INAccountIDList,
											 @OutAccountIDList, @INCommercialTrunkIDList , @OUTCommercialTrunkIDList,
											 @INTechnicalTrunkIDList , @OUTTechnicalTrunkIDList, @CountryIDList,
											 @DestinationIDList , @ServiceLevelIDList , @ConditionClause , @DisplayFieldList,
											 @CDRExtractFileName Output , @ErrorDescription Output , @ResultFlag Output

		End

		if ( @ResultFlag = 1 )
		Begin

				GOTO ENDPROCESS			

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While executing CDR Extraction process. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch


---------------------------------------------------------
-- Extract the name of the CDR Extract file created by
-- the process
---------------------------------------------------------

set @CDRExtractFileName = reverse(substring(reverse(@CDRExtractFileName) , 1 , charindex('\' ,reverse(@CDRExtractFileName)) - 1))


ENDPROCESS:

if ( @ResultFlag = 1 ) -- Failure
Begin

	Update tb_CDRExtract
	set CDRExtractStatusID = -4, -- Failed
	    Remarks = @ErrorDescription,
		ModifiedDate = Getdate(),
		ModifiedByID = -1
    where CDRExtractID = @CDRExtractID
	and CDRExtractStatusID = -2 -- Running

End


if ( @ResultFlag = 0 ) -- Success
Begin

	Update tb_CDRExtract
	set CDRExtractStatusID = -3, -- Success,
	    Remarks = @ErrorDescription,
	    CDRExtractCompletionDate = Getdate(),
		CDRExtractFileName = @CDRExtractFileName,
		ModifiedDate = Getdate(),
		ModifiedByID = -1
    where CDRExtractID = @CDRExtractID
	and CDRExtractStatusID = -2 -- Running
	

End 

--------------------------------------------------------
-- Send and email alert regarding the status of extract  
--------------------------------------------------------

if ( @SendCDRExtractAlertViaEmail = 1 )
Begin

	Exec SP_BSCDRExtractAlert @CDRExtractID

End 

Return 0
GO
