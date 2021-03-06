USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UISearchReferences]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UISearchReferences]
(
    @Reference varchar(60) = NULL,
    @Account varchar(100) = NULL
)
--With Encryption
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
	@Clause2 varchar(1000)

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl2.Accountid , tbl1.Account , tbl1.ReferenceID , tbl1.ReferenceNo '+
              ' From tb_VendorReferenceDetails tbl1 ' +
	      ' inner join vw_Accounts tbl2 on tbl1.Accountid = tbl2.Accountid '


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@Reference is NULL) then ''
		   When ( ( Len(@Reference) =  1 ) and ( @Reference = '%') ) then ''
		   When ( right(@Reference ,1) = '%' ) then ' and tbl1.ReferenceNo like ' + '''' + substring(@Reference,1 , len(@Reference) - 1) + '%' + ''''
		   Else ' and tbl1.ReferenceNo like ' + '''' + @Reference + '%' + ''''
	       End


set @Clause2 = 
               Case
		   When (@Account is NULL) then ''
		   When ( ( Len(@Account) =  1 ) and ( @Account = '%') ) then ''
		   When ( right(@Account ,1) = '%' ) then ' and tbl2.Account like ' + '''' + substring(@Account,1 , len(@Account) - 1) + '%' + ''''
		   Else ' and tbl2.Account like ' + '''' + @Account + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl2.account , tbl1.ReferenceNo' 

Exec (@SQLStr)

Return



GO
