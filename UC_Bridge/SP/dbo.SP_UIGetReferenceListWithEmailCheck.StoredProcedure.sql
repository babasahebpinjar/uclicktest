USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetReferenceListWithEmailCheck]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetReferenceListWithEmailCheck]
(
    @Reference varchar(100) = NULL
)
--With Encryption
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select ReferenceID , ReferenceNo
from tb_vendorreferencedetails '

-------------------------------------------------------------
-- Commented this on 28th Jan 2013 as part of workflow change
-- for authorized sender configuration
-------------------------------------------------------------

--where EnableEmailCheck = 1 '


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------


set @Clause1 = 
               Case
		   When (@Reference is NULL) then ''
		   When ( ( Len(@Reference) =  1 ) and ( @Reference = '%') ) then ''
		   When ( right(@Reference ,1) = '%' ) then ' Where ReferenceNo like ' + '''' + substring(@Reference,1 , len(@Reference) - 1) + '%' + ''''
		   Else ' where ReferenceNo like ' + '''' + @Reference + '%' + ''''
-------------------------------------------------------------
-- Commented this on 28th Jan 2013 as part of workflow change
-- for authorized sender configuration
-------------------------------------------------------------

		  -- When ( right(@Reference ,1) = '%' ) then ' AND ReferenceNo like ' + '''' + substring(@Reference,1 , len(@Reference) - 1) + '%' + ''''
		  -- Else ' AND ReferenceNo like ' + '''' + @Reference + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by ReferenceNo' 

print @SQLStr

Exec (@SQLStr)

Return
GO
