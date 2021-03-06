USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_CustomValidationChecks]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_CustomValidationChecks]
(
    @VendorOfferID int,
    @LogFileName varchar(500),
    @ResultFlag int = 0 output,
    @ErrorDescription varchar(2000) output

)
--With encryption
As


-----------------------
-- Declare Variables
-----------------------

Declare @ErrorMsgStr varchar(2000),
        @OfferDate datetime ,
	@ReferenceID int,
        @SourceID int , 
        @RatePlanID int,
        @NumberPlanID int,
        @ServiceID int,
	@OfferContent varchar(20),
	@ProcessOfferContentType varchar(20)

Declare @TotalDestinations int,
        @TotalDialedDigits int,
	@TotalRecords int

----------------------------------------------------
-- Get all the essential parameters for the offer
-- from the reference and vendor offer tables
----------------------------------------------------

select @OfferDate = offerreceivedate,
       @ReferenceID = referenceid
from TB_VendorOfferDetails 
where VendorOfferID = @VendorOfferID

----------------------------------------------------
-- Add an Entry into the Log File indicating that
-- Generic Validation Checks are being Run
----------------------------------------------------

Exec SP_LogMessage NULL , @LogFileName
set @ErrorMsgStr = '============================================================='
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '****************** SPECIFIC BUSINESS RULES *****************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '============================================================='
Exec SP_LogMessage @ErrorMsgStr , @LogFileName


-------------------------------------------------------------------
-- Print the various SKIP messages to the Log File for tracking
-- purpose.
-------------------------------------------------------------------

Declare @VarActionScript varchar(2000),
        @VarRuleName varchar(1000)

Declare Exec_Custom_Validation_Cur Cursor For
select ActionScript ,Rulename
from tb_validationrules
where ReferenceID = @ReferenceID
and validationstatusid = 1
order by Rulesequence asc


Open Exec_Custom_Validation_Cur
Fetch Next From Exec_Custom_Validation_Cur
Into @VarActionScript, @VarRuleName

While @@FETCH_STATUS = 0
Begin


       Begin Try

		--------------------------------------------------------
		-- Replace default variables with their respective values
		---------------------------------------------------------

		set @VarActionScript = replace(@VarActionScript , '@OfferDate' , '''' + convert(varchar(10) ,@OfferDate , 120) + '''')

		print @VarActionScript

		Exec (@VarActionScript)

       End Try

       Begin Catch

		set @ErrorMsgStr = '	ERROR!!!!'+ ERROR_MESSAGE()
		Exec SP_LogMessage @ErrorMsgStr , @LogFileName

		set @ResultFlag = 1
		set @ErrorDescription = '	ERROR !!! While performing Custom Validations for Reference'

		return 1

       End Catch

       ---------------------------------------------------
       -- Incase of success print the rule name in the
       -- log file to indicate execution
       ---------------------------------------------------

	set @ErrorMsgStr = '	Executed Rule : ( '+ @VarRuleName + ' )'
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName


	Fetch Next From Exec_Custom_Validation_Cur
	Into @VarActionScript, @VarRuleName

End

Close Exec_Custom_Validation_Cur
Deallocate Exec_Custom_Validation_Cur


----------------------------------------------------
-- Add Summary of information after processing
----------------------------------------------------

set @ErrorMsgStr = '	*******************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	POST SPECIFIC BUSINESS RULES PROCESSING DETAILS :- '
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	*******************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName


select @TotalDestinations = count(*)
from
(
	select distinct destination
	from #TempVendorOfferData
	where ErrorMessage is NULL
) as tbl1

select @TotalRecords = count(*)
from #TempVendorOfferData
where errormessage is NULL

select @TotalDialeddigits = count(*)
from #TempVendorOfferData
where ErrorMessage is NULL

set @ErrorMsgStr = '	Total Records      :- ' + convert(varchar(20) , @TotalRecords)
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	Total Destinations  :- ' + convert(varchar(20) , @TotalDestinations)
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

set @ErrorMsgStr = '	Total Dialed Digits :- ' + convert(varchar(20) , @TotalDialeddigits)
Exec SP_LogMessage @ErrorMsgStr , @LogFileName


set @ErrorMsgStr = '	*******************************************************'
Exec SP_LogMessage @ErrorMsgStr , @LogFileName

Return 0
GO
