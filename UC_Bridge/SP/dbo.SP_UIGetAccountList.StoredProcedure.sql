USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAccountList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create Procedure [dbo].[SP_UIGetAccountList]
(
    @Account varchar(100) = NULL
)
--With Encryption

As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @Account is not Null ) and ( len(@Account) = 0 ) )
	set @Account = NULL

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select AccountID , Account from vw_Accounts '


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------


set @Clause1 = 
               Case
		   When (@Account is NULL) then ''
		   When ( ( Len(@Account) =  1 ) and ( @Account = '%') ) then ''
		   When ( right(@Account ,1) = '%' ) then ' where Account like ' + '''' + substring(@Account,1 , len(@Account) - 1) + '%' + ''''
		   Else ' where Account like ' + '''' + @Account + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by Account' 

Exec (@SQLStr)

Return



GO
