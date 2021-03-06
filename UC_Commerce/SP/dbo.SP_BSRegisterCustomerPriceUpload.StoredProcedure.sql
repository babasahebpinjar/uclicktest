USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRegisterCustomerPriceUpload]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRegisterCustomerPriceUpload]
(
	@CPUFileName varchar(500),
	@ExternalFileName varchar(500),
	@ListOfSources nvarchar(max),
	@UserID int,
	@ResultFlag int Output,
	@ErrorDescription varchar(2000) Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

---------------------------------------------------------
-- Get the working directory for Customer Price Upload
--------------------------------------------------------

Declare @AbsoluteFilePath varchar(1000),
		@CPUOfferDirectory varchar(500),
		@cmd varchar(2000)


Select @CPUOfferDirectory = ConfigValue
from UC_Admin.dbo.TB_Config
where Configname = 'CustomerPriceUploadWorkingDirectory'
and AccessScopeID = -6

if ( @CPUOfferDirectory is NULL )
Begin
	
	set @ResultFlag = 1
	set @ErrorDescription = 'ERROR !!!! The configuration for Customer Price Upload Path (CustomerPriceUploadWorkingDirectory) is missing'
	GOTO PROCESSEND 

End

if ( RIGHT(@CPUOfferDirectory , 1) <> '\' )
     set @CPUOfferDirectory = @CPUOfferDirectory + '\'

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @CPUOfferDirectory + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.',
					 'Access is denied.',
					 'File Not Found'
				       )								
          )		
Begin  

	set @ResultFlag = 1
	set @ErrorDescription = 'ERROR !!!! The Customer Price Upload Path : ( ' + @CPUOfferDirectory + ' )  is incorrect or does not exist'
	GOTO PROCESSEND 

End

-----------------------------------------------------------------------
-- Prepare the complet name of the file which needs to be exported
-- into database for format checks
-----------------------------------------------------------------------

set @AbsoluteFilePath = @CPUOfferDirectory + @CPUFileName

--------------------------------------------------------------------------
-- Prepare the table to store the contents of the CPU file into database
--------------------------------------------------------------------------

Declare @FieldTerminator varchar(10) = '\t',
        @RowTerminator varchar(10) = '\n',
		@SQLStr varchar(2000)

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCustomerPriceUploadData') )
	Drop table #tempCustomerPriceUploadData

create table #tempCustomerPriceUploadData
(
	Destination varchar(60),
	EffectiveDate datetime,
	RatingMethod varchar(100),
	Rate1 Decimal(19,6),
	Rate2 Decimal(19,6),
	Rate3 Decimal(19,6),
	Rate4 Decimal(19,6),
	Rate5 Decimal(19,6),
	Rate6 Decimal(19,6),
	Rate7 Decimal(19,6),
	Rate8 Decimal(19,6),
	Rate9 Decimal(19,6),
	Rate10 Decimal(19,6)
)

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRecordCount') )
	Drop table #TempRecordCount

create table #tempRecordCount ( DataRecord varchar(5000) )

--------------------------------------------------------------------------
-- Bulk insert the data into the temp table from the price upload file
--------------------------------------------------------------------------

Begin Try

	Select	@SQLStr = 'Bulk Insert  #tempCustomerPriceUploadData '+ ' From ' 
				  + '''' + @AbsoluteFilePath +'''' + ' WITH (
				  MAXERRORS = 0, FIRSTROW = 2, FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
			  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

	--print @SQLStr
	Exec (@SQLStr)

	--------------------------------------------------------
	-- Buld upload records into Temp table to make sure
	-- all records have been uploaded
	--------------------------------------------------------

	Select	@SQLStr = 'Bulk Insert  #tempRecordCount '+ ' From ' 
				  + '''' + @AbsoluteFilePath +'''' + ' WITH ( '+				 
			  'MAXERRORS = 0, FIRSTROW = 2, ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

	--print @SQLStr
	Exec (@SQLStr)

End Try

Begin Catch

	set  @ErrorDescription = 'ERROR !!! Bulk upload of customer price upload file into database failed.' + ERROR_MESSAGE()
	set @ResultFlag = 1

	GOTO PROCESSEND

End Catch

if ( 
	(  select count(*)  from #tempRecordCount) <>
	(  select count(*)  from #tempCustomerPriceUploadData )
   )
Begin 

	set @ErrorDescription = 'ERROR !!! All records have not been exported into schema due to soem exception in format of one or more records'
    set @ResultFlag = 1

	GOTO PROCESSEND

End   

-----------------------------------------------------------
-- Alter the table to add Remarks Columns for validation
-- results
-----------------------------------------------------------

Alter table #tempCustomerPriceUploadData Add Remarks Varchar(2000)

---------------------------------------------------------
-- Parse the list of customer sources for which we need 
-- upload the file
--------------------------------------------------------

Declare @CustomerSourceIDTable table (CustomerSourceID varchar(100) )


insert into @CustomerSourceIDTable
select * from UC_Reference.dbo.FN_ParseValueList ( @ListOfSources ) 

---------------------------------------------------------------------------
-- Check to ensure that all the sources exist in the customer sources
-- reference
---------------------------------------------------------------------------

if exists (
				Select 1 from @CustomerSourceIDTable
				where CustomerSourceID not in
				(
					Select sourceID
					from tb_Source
					where sourcetypeid = -3 -- Customer Source
					and flag & 1 <> 1
				)
          )
Begin

	set  @ErrorDescription = 'ERROR !!! One or more customer sources passed for price upload are invalid or do not exist in the system'
	set @ResultFlag = 1
	GOTO PROCESSEND

End

--------------------------------------------------------------------------------
-- Ensure to see that all the customer sources have rate plans attached to the
-- INBOUND REFERENCE NUMBER PLAN. 
-- In case of Customer Specific Number Plan
-- the functionality will throw an exception because customer sources of different
-- number plan could be associated to the file upload
--------------------------------------------------------------------------------

if exists (
				select 1
				from @CustomerSourceIDTable cs
				inner join tb_Source src on cs.CustomerSourceID = src.SourceID
				inner join UC_Reference.dbo.tb_RatePlan rp on src.RatePlanID = rp.RatePlanID
				where rp.DirectionID = 1 -- Inbound
				and rp.ProductCataLogID <> -2  -- Reference Based Rate Plan
		  )
Begin

	set  @ErrorDescription = 'ERROR !!! The system has customer specific numbering plan enabled.'+
	                         ' Customer Price Upload functionality does not support customer specific numbering plan.' +
	                         ' Please use Customer Price Change for uploading exception rates.'
	set @ResultFlag = 1
	GOTO PROCESSEND

End

----------------------------------------------------------------------------------
-- Perform validation on data to ensure that information passed for upload is 
-- correct
----------------------------------------------------------------------------------

set @ResultFlag = 0
set @ErrorDescription = NULL

Begin Try

		Exec SP_BSValidateCustomerPriceUploadFileContents

		if exists (select 1 from #tempCustomerPriceUploadData where Remarks is not NULL) 
		Begin

		    set @ErrorDescription = 'ERROR !!! Validation failures for records in the price upload file'
			set @ResultFlag = 1
			GOTO PROCESSEND

		End

End Try

Begin Catch

	set  @ErrorDescription = 'ERROR !!! During validation of customer price upload file contents.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO PROCESSEND

End Catch

-------------------------------------------------------------------------------------
-- Register the Customer Price Upload in the system by inserting records in the
-- approrpiate tables
-------------------------------------------------------------------------------------

Declare @CustomerPriceUploadID int

Begin Transaction ins_customerpriceupload

Begin Try

		---------------------------------------------------
		-- Insert record in the table tb_CustomerPriceUpload
		---------------------------------------------------

		insert into tb_CustomerPriceUpload
		(
			PriceUploadDate,
			ExternalFileName,
			CustomerPriceFileName,
			OfferstatusID,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Values
		(
			getdate(),
			@ExternalFileName,
			@CPUFileName,
			71, -- Created
			Getdate(),
			@UserID,
			-1
		)

		set @CustomerPriceUploadID = @@IDENTITY

		-------------------------------------------------
		-- Insert data into tb_CustomerPriceUploadSource
		-------------------------------------------------

		insert into tb_CustomerPriceUploadSource
		( CustomerPriceUploadID , SourceID , ModifiedDate , ModifiedByID , Flag )
		Select @CustomerPriceUploadID , CustomerSourceID , getdate() , @UserID , 0
		from @CustomerSourceIDTable

		----------------------------------------------------
		-- Insert data into tb_CustomerPriceUploadDetails
		----------------------------------------------------

		insert into tb_CustomerPriceUploadDetails
		(
			 CustomerPriceUploadID , DestinationID , RatingMethodID , Rate1 , Rate2 , Rate3,
			 Rate4 , Rate5 , Rate6 , Rate7 , Rate8 , Rate9 , Rate10 , ModifiedDate , ModifiedByID,
			 Flag
		 )
		select @CustomerPriceUploadID , RefDest.DestinationID , RM.RatingMethodID ,
		       Dest.Rate1 , Dest.Rate2 , Dest.Rate3 , Dest.Rate4 , Dest.Rate5,
			   Dest.Rate6 , Dest.Rate7 , Dest.Rate8 , Dest.Rate9 , Dest.Rate10,
			   getdate() ,  @UserID , 0
		from UC_Reference.dbo.tb_Destination RefDest
		inner join #tempCustomerPriceUploadData Dest on RefDest.Destination = Dest.Destination
		inner join UC_Reference.dbo.tb_RatingMethod RM on Dest.RatingMethod = RM.RatingMethod
		where RefDest.Numberplanid = -1 -- Inbound Reference Number Plan
		and Dest.EffectiveDate between RefDest.BeginDate and ISNULL(RefDest.EndDate , Dest.EffectiveDate)

End Try

Begin Catch

	set  @ErrorDescription = 'ERROR !!! Inserting Records for customer price upload in database.' + ERROR_MESSAGE()
	set @ResultFlag = 1

	Rollback transaction ins_customerpriceupload

	GOTO PROCESSEND

End Catch

commit transaction ins_customerpriceupload


PROCESSEND:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCustomerPriceUploadData') )
	Drop table #tempCustomerPriceUploadData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempRecordCount') )
	Drop table #tempRecordCount
GO
