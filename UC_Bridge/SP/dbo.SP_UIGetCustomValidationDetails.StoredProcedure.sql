USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCustomValidationDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIGetCustomValidationDetails]
(
    @ReferenceNo varchar(30) = NULL,
    @RuleName varchar(100) = NULL,
    @ValidationStatusID int
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

set @SQLStr = 'Select tbl1.ValidationRuleID , tbl1.RuleName , tbl1.ReferenceID , tbl2.ReferenceNo , tbl1.RuleSequence , tbl1.ActionScript , tbl1.ValidationStatusid , tbl3.ValidationStatus '+
              ' From tb_validationrules tbl1 ' +
	      ' inner join tb_vendorreferencedetails tbl2 on tbl1.referenceID = tbl2.ReferenceID ' +
	      ' inner join tb_ValidationStatus tbl3 on tbl1.ValidationStatusID = tbl3.ValidationStatusID '

if ( @ValidationStatusID <> 0 )
Begin
	      set @SQLStr =  @SQLStr + ' where tbl1.ValidationStatusID = ' + convert(varchar(20) , @ValidationStatusID)

End

Else
Begin

	      set @SQLStr =  @SQLStr + ' where tbl1.ValidationStatusID = tbl1.ValidationStatusID '
End


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@ReferenceNo is NULL) then ''
		   When ( ( Len(@ReferenceNo) =  1 ) and ( @ReferenceNo = '%') ) then ''
		   When ( right(@ReferenceNo ,1) = '%' ) then ' and tbl2.ReferenceNo like ' + '''' + substring(@ReferenceNo,1 , len(@ReferenceNo) - 1) + '%' + ''''
		   Else ' and tbl2.ReferenceNo like ' + '''' + @ReferenceNo + '%' + ''''
	       End


set @Clause2 = 
               Case
		   When (@RuleName is NULL) then ''
		   When ( ( Len(@RuleName) =  1 ) and ( @RuleName = '%') ) then ''
		   When ( right(@RuleName ,1) = '%' ) then ' and tbl1.RuleName like ' + '''' + substring(@RuleName,1 , len(@RuleName) - 1) + '%' + ''''
		   Else ' and tbl1.RuleName like ' + '''' + @RuleName + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by ReferenceNo , RuleName , ValidationStatus' 

print @SQLStr

Exec (@SQLStr)

Return



GO
