USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterBusinessDiscardCustomValidations]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterBusinessDiscardCustomValidations]
(
    @AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------------------------------------
-- DISCARD ALL THE TRAFFIC TERMINATING ON THE IPIVR TRUNKS BASED ON DIFFERENT CRITERIA
----------------------------------------------------------------------------------------

Begin Try

		---------------------------------------------------------
		-- Discard Type : CALLBACK TRIGGER
		-- 1. IN TRUNK is a Retail TDM trunk
		-- 2. OUT TRUNK is a VOIP Retail Trunk for IP IVR account
		-- 3. Incoming Called Number 2 has the prefix 15210
		----------------------------------------------------------

		update tbl1
		set ErrorType = -2,
			ErrorDEscription = 'DISCARD RULE: CALLBACK TRIGGER'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OutAccountID = 157 -- IPIVR account
		and substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,5) = '15210'
		and substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,6) <> '152100'
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : CALL THROUGH ONE STAGE
		-- 1. IN TRUNK is a Retail TDM trunk
		-- 2. OUT TRUNK is a VOIP Retail Trunk for IP IVR account
		-- 3. Incoming Called Number 2 has the prefix 1521
		----------------------------------------------------------

		update tbl1
		set ErrorType = -3,
			ErrorDEscription = 'DISCARD RULE: CALL THROUGH ONE STAGE'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OutAccountID = 157 -- IPIVR account
		and substring(isnull(tbl1.INCalledNumber2, '0000000000'), 1,4) = '1521'
		and 
		(
			substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,5) <> '15210'
			or
			(
			   substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,5) = '15210'
			   and
			   substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,6) = '152100'
			)	
		)
		and tbl1.ErrorDescription is NULL

		------------------------------------------------------------------
		-- Discard Type : CALLBACK SECOND STAGE TRIGGER
		-- 1. IN TRUNK is a Retail TDM trunk
		-- 2. OUT TRUNK is a VOIP Retail Trunk for IP IVR account
		-- 3. Incoming Called Number 2 has the prefix 63090111 or 650090
		-------------------------------------------------------------------

		update tbl1
		set ErrorType = -4,
			ErrorDEscription = 'DISCARD RULE: CALLBACK SECOND STAGE TRIGGER'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OutAccountID = 157 -- IPIVR account
		and 
		  (
		     substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,8) = '63090111'
			 or
			 substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,6) = '650090'
		  )
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : CALL THROUGH 2 STAGE
		-- 1. IN TRUNK is a Retail TDM trunk
		-- 2. OUT TRUNK is a VOIP Retail Trunk for IP IVR account
		-- 3. Incoming Called Number 2 has the prefix 6551
		----------------------------------------------------------

		update tbl1
		set ErrorType = -5,
			ErrorDEscription = 'DISCARD RULE: CALL THROUGH SECOND STAGE'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OutAccountID = 157 -- IPIVR account
		and substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,4) = '6551'
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : CALL FORWARDING
		-- 1. IN TRUNK is a Retail TDM trunk
		-- 2. OUT TRUNK is a VOIP Retail Trunk for IP IVR account
		-- 3. Incoming Called Number 2 has the prefix 90803333
		----------------------------------------------------------

		update tbl1
		set ErrorType = -6,
			ErrorDEscription = 'DISCARD RULE: CALL FORWARDING'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OutAccountID = 157 -- IPIVR account
		and substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,8) = '90803333'
		and tbl1.ErrorDescription is NULL


		---------------------------------------------------------
		-- Discard Type : 3157 PREFIX
		-- 1. IN TRUNK is a Retail TDM trunk
		-- 2. Outgoing Trunk is IP/TDM and Retail/Wholesale( A% or E%)
		-- 3. Incoming Called Number 2 has the prefix 3157
		----------------------------------------------------------

		update tbl1
		set ErrorType = -7,
			ErrorDEscription = 'DISCARD RULE: RETAIL CDR WITH 3157 PREFIX'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.OUTTransmissionTypeID in (1,2,3,4)
		and substring(isnull(tbl1.INCalledNumber2, '0000000000') , 1,4) = '3157'
		and tbl1.ErrorDescription is NULL


		---------------------------------------------------------
		-- Discard Type : ONE VOICE
		-- 1. IN TRUNK is a Retail TDM trunk
		-- 2. OUT TRUNK is a VOIP Retail or TDM retail Trunk 
		-- 3. Incoming Called Number 2 has the prefix 3157
		----------------------------------------------------------

		update tbl1
		set ErrorType = -8,
			ErrorDEscription = 'DISCARD RULE: ONE VOICE'
		from #temp_CustomValidation tbl1
		where tbl1.INTrunk = 'A5'
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OutAccountID = 157 -- IPIVR account
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : ONE VOICE TDM
		-- 1. Incoming Trunk is A5
		-- 2. Outgoing Trunk is Retail TDM (E%)
		----------------------------------------------------------

		update tbl1
		set ErrorType = -9,
			ErrorDEscription = 'DISCARD RULE: ONE VOICE TDM'
		from #temp_CustomValidation tbl1
		where tbl1.INTrunk = 'A5'
		and tbl1.OUTTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : ONE VOICE IP
		-- 1. Incoming Trunk is A5
		-- 2. Outgoing Trunk is Retail IP (A%)
		----------------------------------------------------------

		update tbl1
		set ErrorType = -10,
			ErrorDEscription = 'DISCARD RULE: ONE VOICE IP'
		from #temp_CustomValidation tbl1
		where tbl1.INTrunk = 'A5'
		and tbl1.OUTTransmissionTypeID = 3 -- VOIP-Retail
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : SINGAPORE TOLL FREE
		-- 1. Incoming Trunk is A5
		-- 2. Outgoing Trunk is TDM Wholesale (E%)
		-- 3. INCalledNumber3 is NULL
		-- 4. OUTCalledNumber4 is NULL
		-- OR
		-- 1. Incoming Trunk is A5
		-- 2. Outgoing Trunk is Wholesale IP (A%)
		-- 3. INCalledNumber3 is NULL
		-- 4. OUTCalledNumber2 is NULL
		----------------------------------------------------------

		update tbl1
		set ErrorType = -11,
			ErrorDEscription = 'DISCARD RULE: SINGAPORE TOLL FREE'
		from #temp_CustomValidation tbl1
		where tbl1.INTrunk = 'A5'
		and tbl1.OUTTransmissionTypeID = 1 -- TDM
		and INCalledNumber3 is NULL
		and OUTCalledNumber4 is NULL
		and tbl1.ErrorDescription is NULL

		update tbl1
		set ErrorType = -11,
			ErrorDEscription = 'DISCARD RULE: SINGAPORE TOLL FREE'
		from #temp_CustomValidation tbl1
		where tbl1.INTrunk = 'A5'
		and tbl1.OUTTransmissionTypeID = 2 -- VOIP
		and INCalledNumber3 is NULL
		and OUTCalledNumber2 is NULL
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : CALL THROUGH ONE STAGE
		-- 1. IN TRUNK is a VOIP Retail trunk (A200...A299)
		-- 2. OUT TRUNK is a VOIP Retail Trunk for IPIVR account
		----------------------------------------------------------

		update tbl1
		set ErrorType = -12,
			ErrorDEscription = 'DISCARD RULE: CALL THROUGH ONE STAGE'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 4 -- VOIP-Retail
		and len(tbl1.INTrunk) = 4
		and convert(int ,substring(tbl1.INTrunk,2,3)) between 200 and 299
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OutAccountID = 157 -- IPIVR account
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : ONE VOICE INCOMING IP
		-- 1. Incoming Trunk is Retail IP (A%)
		-- 2. Outgoing Trunk is A5
		----------------------------------------------------------

		update tbl1
		set ErrorType = -13,
			ErrorDEscription = 'DISCARD RULE: ONE VOICE INCOMING IP'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OUTTrunk = 'A5'
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : ONE VOICE INCOMING TDM
		-- 1. Incoming Trunk is Retail TDM (E%)
		-- 2. Outgoing Trunk is A5
		----------------------------------------------------------

		update tbl1
		set ErrorType = -14,
			ErrorDEscription = 'DISCARD RULE: ONE VOICE INCOMING TDM'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID = 3 -- TDM-Retail
		and tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
		and tbl1.OUTTrunk = 'A5'
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : RETAIL TOLL FREE
		-- 1. Incoming Trunk is Retail IP (A%)
		-- 2. Outgoing Trunk is wholesale IP (A%)
		-- 3. The "Incoming Called Number 4" is NULL
		-- OR
		-- 1. Incoming Trunk is Wholesale IP (A%)
		-- 2. Outgoing Trunk is Retail IP (A%)
		-- 3. The "Incoming Called Number 4" is NULL
		----------------------------------------------------------

		update tbl1
		set ErrorType = -15,
			ErrorDEscription = 'DISCARD RULE: RETAIL TOLL FREE'
		from #temp_CustomValidation tbl1
		where
		 ( 
				 (
					tbl1.INTransmissionTypeID = 4 -- VOIP-Retail
				   and 
					 tbl1.OUTTransmissionTypeID = 2 -- VOIP-WholeSale
				 )
				 or
				 (
					tbl1.INTransmissionTypeID = 2 -- VOIP-Wholesale
				   and 
					 tbl1.OUTTransmissionTypeID = 4 -- VOIP-Retail
				 )
		 )
		and tbl1.INCalledNumber4 is NULL
		and tbl1.ErrorDescription is NULL

		---------------------------------------------------------
		-- Discard Type : RETAIL TRAFFIC
		-- 1. Incoming Trunk is Retail IP or TDM (A% or E%)
		-- 2. Outgoing Trunk is Retail IP or TDM (A% or E%)
		----------------------------------------------------------

		update tbl1
		set ErrorType = -16,
			ErrorDEscription = 'DISCARD RULE: RETAIL TRAFFIC'
		from #temp_CustomValidation tbl1
		where tbl1.INTransmissionTypeID in (3,4)-- TDM or VOIP Retail
		and tbl1.OUTTransmissionTypeID in (3,4) -- TDM or VOIP Retail
		and tbl1.ErrorDescription is NULL

End Try

Begin Catch


			set @ErrorDescription = 'ERROR !!! During Business specific discard custom validations.' + ERROR_MESSAGE()
  
			set @ErrorDescription = 'SP_BSMedFormatterBusinessDiscardCustomValidations : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + @ErrorDescription
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			set @ResultFlag = 1

			Return 1

End Catch

Return 0




GO
