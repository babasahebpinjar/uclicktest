USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepareDDRangeMaster_Old]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSPrepareDDRangeMaster_Old]
(
	@ProcessCountryCode varchar(15)
)
As

Declare @VarDialedDigits varchar(15),
        @VarRefDestinationID int,
		@VarVendorDestinationID int,
		@VarDDLength int,
		@FirstTimeFlag int = 1

Declare @CurrFromDD varchar(15)

Declare @PrevDialedDigits varchar(15),
        @PrevRefDestionationID int,
		@PrevVendorDestinationID int,
		@PrevDDLength int,
		@PatternChangeRecorded int


---------------------------------------------
-- Initialize variables before calling the
-- cursor for processing
---------------------------------------------

set @PrevDialedDigits = ''
set @CurrFromDD = ''
set @PrevRefDestionationID = 0
set @PrevVendorDestinationID = 0
set @PrevDDLength = 0
set @FirstTimeFlag = 1
set @PatternChangeRecorded = 0

------------------------------------------------------
-- Open cursor for populating the DD Range Master
------------------------------------------------------

DECLARE db_populate_DDRange_Master CURSOR FOR  
select DialedDigits , DDLength , ReferenceDestinationID , VendorDestinationID
from #TempAllDDRange
order by substring(Dialeddigits , len(@ProcessCountryCode) + 1 , 1) , DialedDigits  --  Very important for sorting the records


OPEN db_populate_DDRange_Master   
FETCH NEXT FROM db_populate_DDRange_Master
INTO @VarDialedDigits , @VarDDLength , @VarRefDestinationID , @VarVendorDestinationID 

WHILE @@FETCH_STATUS = 0   
BEGIN  

       if  (
	         (
				@VarDDLength <> @PrevDDLength
				or
				isnull(@VarRefDestinationID, 0) <> @PrevRefDestionationID
				or
				isnull(@VarVendorDestinationID, 0) <> @PrevVendorDestinationID
				or
				(convert(Numeric ,@VarDialedDigits) <> (convert(Numeric ,@PrevDialedDigits) + 1) )
			  )
			  and
			  @FirstTimeFlag <> 1
	       )
		Begin

              ---------------------------------------------------------
			  -- This is an indication of change in pattern , hence we
			  -- need to insert data in the Master range table
			  ---------------------------------------------------------

				Insert into #TempDDRangeMaster
				(
					FromDD , 
					ToDD,
					DDLength,
					ReferenceDestinationID,
					VendorDestinationID

				)
				Values
				(
					@CurrFromDD,
					@PrevDialedDigits,
					@PrevDDLength,
					@PrevRefDestionationID,
					@PrevVendorDestinationID				
				)

				---------------------------------------------------
				-- Change the data set to the new pattern that is
				-- fetched from the cursor
				---------------------------------------------------

				set @CurrFromDD = @VarDialedDigits

				set @PatternChangeRecorded = 1 -- This is to establis that pattern change has been inserted

		End

		if ( @FirstTimeFlag = 1 )
		Begin

				set @FirstTimeFlag = 0
				set @CurrFromDD = @VarDialedDigits

		End

		set @PrevDialedDigits = @VarDialedDigits
		set @PrevDDLength = @VarDDLength
		set @PrevRefDestionationID = @VarRefDestinationID
		set @PrevVendorDestinationID = @VarVendorDestinationID

		if ( @PatternChangeRecorded = 1 )
			set @PatternChangeRecorded = 0

	   FETCH NEXT FROM db_populate_DDRange_Master
	   INTO @VarDialedDigits , @VarDDLength , @VarRefDestinationID , @VarVendorDestinationID 
 
END   

CLOSE db_populate_DDRange_Master  
DEALLOCATE db_populate_DDRange_Master

if ( @PatternChangeRecorded = 0 )
Begin

              ---------------------------------------------------------
			  -- TThis indicates that all the dial code range is over
			  -- and pattern did not change so we need to record the
			  -- same
			  ---------------------------------------------------------

				Insert into #TempDDRangeMaster
				(
					FromDD , 
					ToDD,
					DDLength,
					ReferenceDestinationID,
					VendorDestinationID

				)
				Values
				(
					@CurrFromDD,
					@PrevDialedDigits,
					@PrevDDLength,
					@PrevRefDestionationID,
					@PrevVendorDestinationID				
				)


End

Return 0
GO
