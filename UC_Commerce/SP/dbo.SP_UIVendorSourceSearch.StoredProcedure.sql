USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorSourceSearch]    Script Date: 5/2/2020 6:18:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorSourceSearch]
(
	@Source varchar(100) = NULL,
	@AccountID int ,
	@CallTypeID int,
	@RatePlanID int,
	@StatusID  int
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @Source is not Null ) and ( len(@Source) = 0 ) )
	set @Source = NULL


if ( ( @Source <> '_') and charindex('_' , @Source) <> -1 )
Begin

	set @Source = replace(@Source , '_' , '[_]')

End


--------------------------------------------------------
-- Set Account/Call Type/Rate Plan/Status to NULL in case
-- value is 0
---------------------------------------------------------

if ( @AccountID = 0 )
	set @AccountID = NULL


if ( @RatePlanID = 0 )
	set @RatePlanID = NULL


if ( @CallTypeID = 0 )
	set @CallTypeID = NULL


if ( @StatusID = 0 )
	set @StatusID = NULL

----------------------------------------------------------
-- Prepare the dynamic SQL query for the search criteria
----------------------------------------------------------

set @SQLStr = 'Select tbl1.SourceID , tbl1.Source  , tbl2.AccountID , tbl2.Account ' +
              ' from tb_Source tbl1 ' +
			  ' left join uc_reference.dbo.tb_Account tbl2 on tbl1.ExternalCode = tbl2.AccountID ' +
			  ' where tbl1.SourcetypeID = -1 ' +
			  Case 
				When @AccountID is NULL then ''
				Else ' and tbl1.ExternalCode = '  + convert(varchar(20) , @AccountID)
			  End + 
			  Case 
				When @RatePlanID is NULL then ''
				Else ' and tbl1.RatePlanID = '  + convert(varchar(20) , @RatePlanID)
			  End + 
			  Case 
				When @CallTypeID is NULL then ''
				Else ' and tbl1.CalltypeID = '  + convert(varchar(20) , @CallTypeID)
			  End + 
			  Case 
				When @StatusID is NULL then ''
				Else ' and tbl1.ActiveStatusID = '  + convert(varchar(20) , @StatusID)
			  End 

-----------------------------------------------------
-- Prepare the extended clause for the search query	
-----------------------------------------------------

set @Clause1 = 
           Case
			   When (@Source is NULL) then ''
			   When (@Source = '_') then ' and tbl1.Source like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@Source) =  1 ) and ( @Source = '%') ) then ''
			   When ( right(@Source ,1) = '%' ) then ' and tbl1.Source like ' + '''' + substring(@Source,1 , len(@Source) - 1) + '%' + ''''
			   Else ' and tbl1.Source like ' + '''' + @Source + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1	

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl2.Account , tbl1.Source' 

--print @SQLStr

Exec (@SQLStr)

Return
	  			  			  			   
GO
