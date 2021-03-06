USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepareDDRangeMaster_Ver2]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSPrepareDDRangeMaster_Ver2]
As

Declare @VarReferenceDestinationID int,
		@VarVendorDestinationID int,
		@VarDDLength int

--------------------------------------------------
-- Create temporary table for the purpose of
-- processing data
--------------------------------------------------

Create Table #TempProcessing
(
	DialedDigits numeric,
	ReferenceDestinationID int,
	VendorDEstinationID int
)

Create Table #TempDDRange
(
	FromDD varchar(15),
	ToDD varchar(15),
	DDLength int,
	ReferenceDestinationID int,
	VendorDestinationID int
)

----------------------------------------------------
-- Open cursor for populating the DD Range Master
------------------------------------------------------

Declare @MinValue Numeric,
        @MaxValue Numeric,
		@MiddleValue Numeric,
		@CurrDDFrom Numeric,
		@PrevMinValue Numeric

DECLARE db_populate_DDRange_Master CURSOR FOR  
select Distinct DDLength , ReferenceDestinationID , VendorDestinationID
from #TempAllDDRange
order by DDLength


OPEN db_populate_DDRange_Master   
FETCH NEXT FROM db_populate_DDRange_Master
INTO @VarDDLength  , @VarReferenceDestinationID , @VarVendorDestinationID

WHILE @@FETCH_STATUS = 0   
BEGIN  

       delete from #TempProcessing
	   delete from #TempDDRange

	   insert into #TempProcessing
	   (DialedDigits , ReferenceDestinationID , VendorDestinationID )
	   select DialedDigits , ReferenceDestinationID , VendorDestinationID
	   from #TempAllDDRange
	   where DDLength = @VarDDLength
	   and ReferenceDestinationID = @VarReferenceDestinationID
	   and VendorDestinationID = @VarVendorDestinationID

	   --select 'Data Subset' ,*
	   --from #TempProcessing

		Select @CurrDDFrom = min(DialedDigits) 
		from #TempProcessing

		if ( (select count(*) from #TempProcessing ) = 1 )
		Begin

				set @MinValue = @CurrDDFrom

		End

		Delete 
		from #TempProcessing
		where DialedDigits = @CurrDDFrom

		set @PrevMinValue = @CurrDDFrom
	  
	   while exists ( select 1 from #TempProcessing)
	   Begin
				Select @MinValue = Min(DialedDigits) 
				from #TempProcessing

				if ( @MinValue <> ( @PrevMinValue + 1 ) ) 
				Begin
                     
					        --select 'Pushi..'  , @CurrDDFrom as DDFrom , @PrevMinValue as ToDD , @MinValue as MinValue
							 
							Insert into #TempDDRange
							( FromDD , ToDD , DDLength , ReferenceDestinationID , VendorDestinationID )
							Values
							(
								convert(varchar(15) ,@CurrDDFrom), 
								convert(varchar(15) ,@PrevMinValue) , 
								@VarDDLength ,
								@VarReferenceDestinationID , 
								@VarVendorDestinationID
						    )


							set @CurrDDFrom = @MinValue
							
				End

				Delete from #TempProcessing
				where DialedDigits = @MinValue 
				
				set @PrevMinValue = @MinValue             		 

	   End

	   --------------------------------------------------------------
	   -- Post exiting if we find a record still pending the update
	   -- of ToDD, then populate the last MinValue extracted
	   --------------------------------------------------------------

	   if exists ( select 1 from #TempDDRange where ToDD is NULL )
	   Begin

				Update #TempDDRange
				set ToDD = @MinValue
				where ToDD is NULL

	   End

	   -----------------------------------------------------------------
	   -- This is a scenario where all records have there ToDD value
	   -- populated , hence we need to create a new entry for the last
	   -- MinValue and CurFromDD
	   -----------------------------------------------------------------

	   Else
	   Begin

				Insert into #TempDDRange
				( FromDD , ToDD , DDLength , ReferenceDestinationID , VendorDestinationID )
				Values
				(
					convert(varchar(15) ,@CurrDDFrom), 
					convert(varchar(15) ,@MinValue) , 
					@VarDDLength ,
					@VarReferenceDestinationID , 
					@VarVendorDestinationID
				)


	   End

	   ----------------------------------------------------------
	   -- Insertt the records into the final DD range table
	   -----------------------------------------------------------

	   Insert into #TempDDRangeMaster
	   ( FromDD , ToDD , DDLength , ReferenceDestinationID , VendorDestinationID )
	   Select FromDD , ToDD , DDLength , ReferenceDestinationID , VendorDestinationID
	   from #TempDDRange
	   

	   FETCH NEXT FROM db_populate_DDRange_Master
	   INTO @VarDDLength  , @VarReferenceDestinationID , @VarVendorDestinationID 
 
END   

CLOSE db_populate_DDRange_Master  
DEALLOCATE db_populate_DDRange_Master


-------------------------------------------
-- Drop table post processing of DD range
-------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempProcessing') )
	Drop table #TempProcessing

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDDRange') )
	Drop table #TempDDRange


Return 0
GO
