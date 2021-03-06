USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAutoCreateAccountModePeriod]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSAutoCreateAccountModePeriod]
(
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @VarAccountID int,
		@VarBeginDate datetime,
		@VarInitialPeriod int,
		@VarFinalPeriod int

--------------------------------------------------------------
-- Create a temp table to get all the records for accounts 
-- and their respective periods
--------------------------------------------------------------
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountModePeriod') )
	Drop table #TempAccountModePeriod

Create Table #TempAccountModePeriod
(
	AccountID int,
	Period int
)


---------------------------------------------------
-- Create temp table to store the period range 
-- for each account when traversing
----------------------------------------------------
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempPeriodRange') )
	Drop table #TempPeriodRange

Create table #TempPeriodRange (Period int)


----------------------------------------------------------------------------------------------------
-- Declare a cursor to go through each account and see how many period records need to be created
----------------------------------------------------------------------------------------------------
DECLARE db_Account_Period_Cur CURSOR FOR
select AccountID , min(BeginDate)
from tb_Agreement
where flag &1 = 0
group by AccountID

OPEN db_Account_Period_Cur   
FETCH NEXT FROM db_Account_Period_Cur
INTO @VarAccountID , @VarBeginDate

WHILE @@FETCH_STATUS = 0   
BEGIN
		Begin Try

			--------------------------------------------------------------------------------------------
			-- If there are no records existing for the account in the AccountMode table, then we will
			-- insert records in the range from the minimum agreement date to current date 
			--------------------------------------------------------------------------------------------

			if ((select count(*) from tb_AccountMode where AccountID = @VarAccountID) = 0)
			Begin

					set @VarInitialPeriod = convert(int ,
														convert(varchar(4) ,year(@VarBeginDate)) + 
														right( '0' + convert(varchar(2) ,month(@VarBeginDate)) ,2)
													)

			End


			--------------------------------------------------------------------------------------------
			-- Else insert records in the range from maximum period + 1 in Account Mode to current date 
			--------------------------------------------------------------------------------------------

			else
			Begin

					select @VarInitialPeriod = 
							Case
								When substring(convert(varchar(6) , max(Period) ) , 5,2) = 12 Then
										 convert(varchar(4) ,convert(int ,substring(convert(varchar(6) ,  max(Period)) , 1,4)) + 1) + '01'
								Else max(Period) + 1
							End
					from tb_AccountMode
					where AccountID = @VarAccountID


			End

			set @VarFinalPeriod = convert(int ,
												convert(varchar(4) ,year(dateadd(mm,1,getdate()))) + 
												right( '0' + convert(varchar(2) ,month(dateadd(mm,1,getdate()))) ,2)
											)

			Delete from #TempPeriodRange

			While (@VarInitialPeriod <= @VarFinalPeriod)
			Begin

					insert into #TempPeriodRange values (@VarInitialPeriod)

					if (substring(convert(varchar(6) , @VarInitialPeriod ) , 5,2) = 12)
					Begin

						set @VarInitialPeriod = convert(varchar(4) ,convert(int ,substring(convert(varchar(6) , @VarInitialPeriod ) , 1,4)) + 1) + '01'

					End

					else
					Begin

						set @VarInitialPeriod = @VarInitialPeriod + 1

					End
			End

			----------------------------------------------------
			-- Insert records into the Account Mode temp table
			-- for the account, based on the period range
			-----------------------------------------------------

			Insert into #TempAccountModePeriod (AccountID , Period)
			select @VarAccountID , Period 
			from #TempPeriodRange
			

		End Try

		Begin Catch

			set @ErrorDescription = 'ERROR!!! While traversing through Account(s) for establishing Account Mode Period. '+ ERROR_MESSAGE()
			set @ResultFlag = 1

			CLOSE db_Account_Period_Cur  
			DEALLOCATE db_Account_Period_Cur 

			GOTO ENDPROCESS

		End Catch


		FETCH NEXT FROM db_Account_Period_Cur
		INTO  @VarAccountID , @VarBeginDate

END   

CLOSE db_Account_Period_Cur  
DEALLOCATE db_Account_Period_Cur 

--------------------------------------------------------------------------------
-- Insert all data at once into the Account Mode schema for all the accounts.
-- We will do a direct insert instead of calling the API, because it will
-- not impact perfromance, if we have large number of records to insert
--------------------------------------------------------------------------------

if ((select count(*) from #TempAccountModePeriod) = 0 )
	GOTO ENDPROCESS --  Skip the insert process if there are no records

Begin Try

	Insert into tb_AccountMode
	(
		AccountID,
		AccountModeTypeID,
		[Period],
		Comment,
		ModifiedDate,
		ModifiedByID		
	)
	Select AccountID,
		   -1, -- Default value Post Paid
		   [Period],
		   'Created Automatically By System',
		   getdate(),
		   -1
	from #TempAccountModePeriod 

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! During insertion of new Account Mode Period records.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	
	GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountModePeriod') )
	Drop table #TempAccountModePeriod

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempPeriodRange') )
	Drop table #TempPeriodRange

  


GO
