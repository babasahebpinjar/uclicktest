USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepaidThresholdCheckMain]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_BSPrepaidThresholdCheckMain]
AS 

Declare @ErrorDescription varchar(2000) ,
		@ResultFlag int 

set @ResultFlag = 0
set @ErrorDescription = NULL

------------------------------------------------------
-- Find the period based on which we will extract 
-- list of Prepaid accounts
------------------------------------------------------

Declare @CurrPeriod int
set @CurrPeriod = convert(int,replace(convert(varchar(7) , getdate() , 120), '-' , ''))

---------------------------------------------------------------------------
-- Open a cursor to perform prepaid threshold check for qualified accounts
---------------------------------------------------------------------------

Declare @VarAccountID int

DECLARE db_Check_Threshold_Cur CURSOR FOR
select AccountID 
from Tb_AccountMode
where period = @CurrPeriod

OPEN db_Check_Threshold_Cur
FETCH NEXT FROM db_Check_Threshold_Cur
INTO @VarAccountID 

While @@FETCH_STATUS = 0
BEGIN

		Begin Try

				set @ResultFlag = 0
				set @ErrorDescription = NULL

				Exec SP_BSPrepaidThresholdCheck @VarAccountID , @ErrorDescription Output , @ResultFlag Output

				if (@ResultFlag = 1 )
				Begin

					set @ErrorDescription = 'ERROR !!!! While performing Threshold check for prepaid account. ' + @ErrorDescription
					set @ResultFlag = 1
					RaisError('%s' , 1,16 , @ErrorDescription)

					CLOSE db_Check_Threshold_Cur
					DEALLOCATE db_Check_Threshold_Cur

					GOTO ENDPROCESS

				End

		End Try

		Begin Catch

				set @ErrorDescription = 'ERROR !!!! While performing Threshold check for prepaid account. ' + ERROR_MESSAGE()
				set @ResultFlag = 1
				RaisError('%s' , 1,16 , @ErrorDescription)

				CLOSE db_Check_Threshold_Cur
				DEALLOCATE db_Check_Threshold_Cur

				GOTO ENDPROCESS

		End Catch

		FETCH NEXT FROM db_Check_Threshold_Cur
		INTO @VarAccountID   		 

END

CLOSE db_Check_Threshold_Cur
DEALLOCATE db_Check_Threshold_Cur

ENDPROCESS:

if @ResultFlag = 1 
	Return 1
Else
	Return 0


		
GO
