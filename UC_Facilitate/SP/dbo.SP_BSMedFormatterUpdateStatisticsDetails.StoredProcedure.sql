USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterUpdateStatisticsDetails]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterUpdateStatisticsDetails]
(
    @OutCDRFileID int,
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

Declare @Error_1 int = 0,
		@Error_2 int = 0,
		@Error_3 int = 0,
		@Error_4 int = 0,
		@Error_5 int = 0,
		@Error_6 int = 0,
		@Error_7 int = 0,
		@Discard_1 int = 0,
		@Discard_2 int = 0,
		@Discard_3 int = 0,
		@Discard_4 int = 0,
		@Discard_5 int = 0,
		@Discard_6 int = 0,
		@Discard_7 int = 0,
		@Discard_8 int = 0,
		@Discard_9 int = 0,
		@Discard_10 int = 0,
		@Discard_11 int = 0,
		@Discard_12 int = 0,
		@Discard_13 int = 0,
		@Discard_14 int = 0,
		@Discard_15 int = 0,
		@Discard_16 int = 0

Begin Try

   --------------------------------------------------------
   -- ERROR 1 : Incoming Route not present for Call Date
   --------------------------------------------------------

	Select @Error_1 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = 1

   --------------------------------------------------------
   -- ERROR 2 : Outgoing Route not present for Call Date
   --------------------------------------------------------

	Select @Error_2 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = 2

   --------------------------------------------------------
   -- ERROR 3 : Outgoing route set as Inbound
   --------------------------------------------------------

	Select @Error_3 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = 3

   --------------------------------------------------------
   -- ERROR 4 : Incoming route set as Outbound
   --------------------------------------------------------

	Select @Error_4 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = 4

   --------------------------------------------------------
   -- ERROR 5 : Outgoing route Transmission type not defined
   --------------------------------------------------------

	Select @Error_5 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = 5

   --------------------------------------------------------
   -- ERROR 6 : Incoming route Transmission type not defined
   --------------------------------------------------------

	Select @Error_6 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = 6

   --------------------------------------------------------
   -- ERROR 7 : CDR Scenario Cannot be resolved
   --------------------------------------------------------

	Select @Error_7 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = 7

	-----------------------------------------------
	-- Insert staistics for the Rejection details 
	-----------------------------------------------

	insert into tb_MedFormatterOutputRejectDetails
	Select @OutCDRFileID , isnull(@Error_1 , 0) ,  isnull(@Error_2 , 0) ,  isnull(@Error_3 , 0) , 
	        isnull(@Error_4 , 0) ,  isnull(@Error_5 , 0) , isnull(@Error_6 , 0), isnull(@Error_7 , 0)


   --------------------------------------------------------
   -- Discard 1 : Release Cause for CDR is CAU_SIP_MTMP
   --------------------------------------------------------

	Select @Discard_1 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -1

   ---------------------------------------------------------------------------
   -- Discard 2 : CALLBACK TRIGGER
   ---------------------------------------------------------------------------

	Select @Discard_2 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -2

   -------------------------------------------------------------------------------
   -- Discard 3 : CALL THROUGH ONE STAGE
   -------------------------------------------------------------------------------

	Select @Discard_3 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -3

   -------------------------------------------------------------------------------
   -- Discard 4 : CALLBACK SECOND STAGE TRIGGER
   -------------------------------------------------------------------------------

	Select @Discard_4 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -4

   -------------------------------------------------------------------------------
   -- Discard 5 : CALL THROUGH 2 STAGE
   -------------------------------------------------------------------------------

	Select @Discard_5 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -5

   -------------------------------------------------------------------------------
   -- Discard 6 : CALL FORWARDING
   -------------------------------------------------------------------------------

	Select @Discard_6 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -6

   -------------------------------------------------------------------------------
   -- Discard 7 : 3157 PREFIX
   -------------------------------------------------------------------------------

	Select @Discard_7 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -7

   -------------------------------------------------------------------------------
   -- Discard 8 : ONE VOICE
   -------------------------------------------------------------------------------

	Select @Discard_8 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -8

   -------------------------------------------------------------------------------
   -- Discard 9 : ONE VOICE TDM
   -------------------------------------------------------------------------------

	Select @Discard_9 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -9

   -------------------------------------------------------------------------------
   -- Discard 10 : ONE VOICE IP
   -------------------------------------------------------------------------------

	Select @Discard_10 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -10

   -------------------------------------------------------------------------------
   -- Discard 11 : SINGAPORE TOLL FREE
   -------------------------------------------------------------------------------

	Select @Discard_11 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -11

   -------------------------------------------------------------------------------
   -- Discard 12 : CALL THROUGH ONE STAGE
   -------------------------------------------------------------------------------

	Select @Discard_12 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -12

   -------------------------------------------------------------------------------
   -- Discard 13 : ONE VOICE INCOMING IP
   -------------------------------------------------------------------------------

	Select @Discard_13 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -13

   -------------------------------------------------------------------------------
   -- Discard 14 : ONE VOICE INCOMING TDM
   -------------------------------------------------------------------------------

	Select @Discard_14 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -14

   -------------------------------------------------------------------------------
   -- Discard 15 : RETAIL TOLL FREE
   -------------------------------------------------------------------------------

	Select @Discard_15 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -15

   -------------------------------------------------------------------------------
   -- Discard 15 : RETAIL TRAFFIC
   -------------------------------------------------------------------------------

	Select @Discard_16 = count(*)
	from ##temp_MedFormatterRecords
	where Errortype = -16

	-----------------------------------------------
	-- Insert staistics for the Discard details 
	-----------------------------------------------

	insert into tb_MedFormatterOutputDiscardDetails
	Select @OutCDRFileID , isnull(@Discard_1 , 0) ,  isnull(@Discard_2 , 0) ,  isnull(@Discard_3 , 0) , 
	        isnull(@Discard_4 , 0) ,  isnull(@Discard_5 , 0) ,  isnull(@Discard_6 , 0), isnull(@Discard_7 , 0),
			isnull(@Discard_8 , 0), isnull(@Discard_9 , 0) ,  isnull(@Discard_10 , 0) ,  isnull(@Discard_11 , 0) , 
	        isnull(@Discard_12 , 0) ,  isnull(@Discard_13 , 0) ,  isnull(@Discard_14 , 0), isnull(@Discard_15 , 0),
			isnull(@Discard_16 , 0)


End Try

Begin Catch


			set @ErrorDescription = 'ERROR !!! During Update of statistics for rejection and discard' + ERROR_MESSAGE()
  
			set @ErrorDescription = 'SP_BSMedFormatterUpdateStatisticsDetails : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + @ErrorDescription
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			set @ResultFlag = 1

			Return 1

End Catch

Return 0
GO
