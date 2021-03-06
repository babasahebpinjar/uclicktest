USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAuthorizedSenderdetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetAuthorizedSenderdetails] 
(
    @ReferenceNo varchar(100) = NULL,
    @EmailID varchar(100) = NULL
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

set @SQLStr = 'Select tbl1.ID , tbl1.ReferenceID , tbl2.ReferenceNo , tbl1.Name , tbl1.Company, tbl1.EmailAddress '+
              ' From tblAuthorizedEmails tbl1 ' +
	      ' inner join tb_VendorReferenceDetails tbl2 on tbl1.ReferenceID = tbl2.ReferenceID '


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@ReferenceNo is NULL) then ''
		   When ( ( Len(@ReferenceNo) =  1 ) and ( @ReferenceNo = '%') ) then ''
		   When ( right(@ReferenceNo ,1) = '%' ) then ' where tbl2.ReferenceNo like ' + '''' + substring(@ReferenceNo,1 , len(@ReferenceNo) - 1) + '%' + ''''
		   Else ' where tbl2.ReferenceNo like ' + '''' + @ReferenceNo + '%' + ''''
	       End


set @Clause2 = 
               Case
		   When (@EmailID is NULL) then ''
		   When ( ( Len(@EmailID) =  1 ) and ( @EmailID = '%') ) then ''
		   When ( right(@EmailID ,1) = '%' ) then
		       Case
			  When (@ReferenceNo is NULL) then ' where tbl1.EmailAddress like ' + '''' + substring(@EmailID,1 , len(@EmailID) - 1) + '%' + ''''
			  When ( ( Len(@ReferenceNo) =  1 ) and ( @ReferenceNo = '%') ) then ' where tbl1.EmailAddress like ' + '''' + substring(@EmailID,1 , len(@EmailID) - 1) + '%' + ''''
			  Else ' and tbl1.EmailAddress like ' + '''' + substring(@EmailID,1 , len(@EmailID) - 1) + '%' + ''''
		       End		   
		   Else
		       Case
			  When (@ReferenceNo is NULL) then ' where tbl1.EmailAddress like ' + '''' + @EmailID + '%' + ''''
			  When ( ( Len(@ReferenceNo) =  1 ) and ( @ReferenceNo = '%') ) then ' where tbl1.EmailAddress like ' + '''' + @EmailID + '%' + ''''
			  Else ' and tbl1.EmailAddress like ' + '''' + @EmailID + '%' + ''''
		       End		   
		   		   
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by ReferenceNo , Name, EmailAddress' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
