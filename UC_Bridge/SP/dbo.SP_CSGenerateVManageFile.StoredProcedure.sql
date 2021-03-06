USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_CSGenerateVManageFile]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_CSGenerateVManageFile]
(
    @WorkingDirectory varchar(1000),
	@VManageOutputFileName varchar(1000),
	@VendorOfferID int,
	@OfferLogFileName varchar(1000)

)
As

Declare @ReferenceID int,
		@ReferenceNo varchar(100),
        @TKGID int,
		@ErrorMsgStr varchar(2000),
		@FileExists int,
		@cmd varchar(2000)

----------------------------------------------------
-- Get the Vendor Offer Reference ID for fetching
-- other details
----------------------------------------------------

Select @ReferenceID = ReferenceID
from TB_VendorOfferDetails
where VendorOfferID = @VendorOfferID

select @ReferenceNo = ReferenceNo
from TB_VendorReferenceDetails
where ReferenceID = @ReferenceID

---------------------------------------------------
-- Get the associated TKG ID for the reference
---------------------------------------------------

Select @TKGID = TKGID
from TB_TempTKGReferenceMapping
where referenceID = @ReferenceID

------------------------------------------------------------
-- Raise a warning in the log file indicating that the
-- VManage file not generated due to missing mapping
-- for ReferenceNO and TKGID
------------------------------------------------------------

if (@TKGID is NULL)
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName

	set @ErrorMsgStr = '================================================'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	WARNING !!! Mapping of TKG missing in the custom configuration for REFERENCE : ' + @ReferenceNo
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	File not generated automatically from system'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '============================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Return 0

End



if (
		(
			select count(*)
			from TB_TempTKGReferenceMapping
			where ReferenceID = @ReferenceID
		) > 1
   )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName

	set @ErrorMsgStr = '================================================'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	WARNING !!! Multiple Mapping of TKG in custom configuration for REFERENCE : ' + @ReferenceNo
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	File not generated automatically from system'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '============================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Return 0

End

--------------------------------------------------
-- Generate the essential file from the system
--------------------------------------------------

--------------------------------------------------
-- Delete any previous instance of the file, 
-- as this is a fresh run.
--------------------------------------------------


set @FileExists = 0

Exec master..xp_fileexist @VManageOutputFileName , @FileExists output  

if ( @FileExists = 1 )
Begin

   set @cmd = 'del ' + '"' + @VManageOutputFileName + '"'
   Exec master..xp_cmdshell @cmd

End 

------------------------------------------------------------
-- Build the header and record files with unique names
------------------------------------------------------------


----------------------------------------------------------
-- Create a random number to be associated header and
-- record files for uniqueness
----------------------------------------------------------

DECLARE @Random INT
DECLARE @Upper INT
DECLARE @Lower INT

SET @Lower = 1 ---- The lowest random number
SET @Upper = 999999 ---- The highest random number
SELECT @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)

Declare @ProcessLogID int
set @ProcessLogID = @Random 

Declare @HeaderFile varchar(500),
	@RecordFile varchar(500),
	@datestring varchar(100),
	@bcpCommand varchar(5000),
	@QualifiedTableName varchar(500),
	@OutputTableName varchar(500)
              
set @HeaderFile = @WorkingDirectory + 'HeaderFile_'+convert(varchar(10) , @ProcessLogID) 
set @RecordFile = @WorkingDirectory + 'RecordFile_'+convert(varchar(10) , @ProcessLogID)

-------------------------------------------
-- Build the Header file for the extract
------------------------------------------

set @bcpCommand = 'echo Direction^,Term Country^,Prefix Code^,Rate^,TKG^,START_DATE^,END_DATE^,FIRST_BLOCK^,FOLLOWON_BLOCK^,START_TOD^,END_TOD^,START_DOW^,END_DOW >' + '"'+ @HeaderFile + '"'

Begin Try

	EXEC master..xp_cmdshell @bcpCommand

End Try

Begin Catch

	Exec SP_LogMessage NULL , @OfferLogFileName

	set @ErrorMsgStr = '================================================'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	WARNING !!! Error encountered while creating header file for VManage extract file' + ERROR_MESSAGE()
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	File not generated automatically from system'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '============================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Return 0

End Catch

set @FileExists = 0

Exec master..xp_fileexist  @HeaderFile, @FileExists output  

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName

	set @ErrorMsgStr = '================================================'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	WARNING !!! Exception encountered while creating header file for VManage extract file'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	File not generated automatically from system'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '============================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Return 0


End 

-------------------------------------------------
-- Build the Record File for the VManage Extract
------------------------------------------------

set @OutputTableName = 'TB_VManage_'+ convert(varchar(20), @VendorOfferID) + '_' + convert(varchar(10) , @ProcessLogID)
Set @QualifiedTableName = db_name() + '.dbo.' + @OutputTableName

if exists ( select 1 from sysobjects where name = @OutputTableName and xtype = 'U' )
	Exec('Drop table ' + @OutputTableName )

Exec ('select * into ' + @OutputTableName + ' from #TempVendorOfferData')
Exec ('Update ' + @OutputTableName + ' set Destination = ''"''+ Destination + ''"'' where charindex('','' , Destination) <> 0')

SET @cmd = 'bcp "SELECT 1, Destination , DialedDigit , Rate , ' + convert(varchar(20) , @TKGID) + ', convert(date ,EffectiveDate) , NULL , 1,1,0,23,0,6 from ' + @QualifiedTableName + ' order by Destination ' +'" queryout ' + '"' + ltrim(rtrim(@RecordFile)) + '"' + ' -c -t "," -r"\n" -T -S '+ @@servername
--print @cmd

Begin Try 

	exec master..xp_cmdshell @cmd

End Try

Begin Catch

	Exec SP_LogMessage NULL , @OfferLogFileName

	set @ErrorMsgStr = '================================================'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	WARNING !!! Exception encountered while creating record file for VManage extract file .' + ERROR_MESSAGE()
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	File not generated automatically from system'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '============================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Return 0


End Catch

set @FileExists = 0

Exec master..xp_fileexist  @RecordFile, @FileExists output  

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName

	set @ErrorMsgStr = '================================================'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	WARNING !!! Exception encountered while creating record file for VManage extract file'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	File not generated automatically from system'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '============================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Return 0


End 

------------------------------------------------
-- Build the main file for the VManage Extract 
------------------------------------------------

set @bcpCommand = 'copy '+ '"'+ @HeaderFile + '"' + ' + ' + '"' +  @RecordFile + '"' +' '+ '"'+ @VManageOutputFileName + '"' + ' /B'
--print @bcpCommand 
EXEC master..xp_cmdshell @bcpCommand 

--------------------------------------------------
-- Remove the temporary header and record file
--------------------------------------------------

set @bcpCommand = 'del '+ '"'+@HeaderFile+'"'
EXEC master..xp_cmdshell @bcpCommand 

set @bcpCommand = 'del '+ '"'+ @RecordFile + '"'
EXEC master..xp_cmdshell @bcpCommand 

------------------------------------------------------
-- Check if the VManageExtract file has been created 
-- or not
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @VManageOutputFileName  , @FileExists output 

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName

	set @ErrorMsgStr = '================================================'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	WARNING !!! Exception encountered while creating VManage extract file'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '	File not generated automatically from system'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorMsgStr = '============================================================='
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Return 0

End

--------------------------------------------
-- Upon successful execution of the script
--------------------------------------------

Exec SP_LogMessage NULL , @OfferLogFileName

set @ErrorMsgStr = '================================================'
Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '******** VMANAGE FILE GENERATION STATUS *******'
Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '================================================='
Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '	VManage Format Extract file generated successfully'
Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName
	
set @ErrorMsgStr = '============================================================='
Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName


if exists ( select 1 from sysobjects where name = @OutputTableName and xtype = 'U' )
	Exec('Drop table ' + @OutputTableName )


Return 0















GO
