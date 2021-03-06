USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetVendorSourceList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create Procedure [dbo].[SP_UIGetVendorSourceList]
(
    @Source varchar(100) = NULL,
    @AccountID int = NULL
)
--With Encryption 
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if ( @AccountID is NULL )
	set @AccountID = -99999

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select SourceId , Source from vw_VendorSource '+
              ' where AccountID = ' +
			  Case
				When @AccountID = -99999 then ' AccountID'
				Else convert(varchar(20) , @AccountID)
			  End


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------


set @Clause1 = 
               Case
		   When (@Source is NULL) then ''
		   When ( ( Len(@Source) =  1 ) and ( @Source = '%') ) then ''
		   When ( right(@Source ,1) = '%' ) then ' and Source like ' + '''' + substring(@Source,1 , len(@Source) - 1) + '%' + ''''
		   Else ' and Source like ' + '''' + @Source + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by Source' 

print @SQLStr

Exec (@SQLStr)

Return



GO
