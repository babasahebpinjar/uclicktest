USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIConfigSearch]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIConfigSearch] 
(
    @ConfigName varchar(200) = NULL,
    @AccessScopeID int = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @ConfigName is not Null ) and ( len(@ConfigName) = 0 ) )
	set @ConfigName = NULL


if ( ( @ConfigName <> '_') and charindex('_' , @ConfigName) <> -1 )
Begin

	set @ConfigName = replace(@ConfigName , '_' , '[_]')

End

----------------------------------------------
-- Check the Access Scope ID and set it to 0
-- in case the value passed is NULL
----------------------------------------------

if (@AccessScopeID is NULL) 
	set @AccessScopeID = 0

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.ConfigName , tbl2.ConfigDataType , tbl1.AccessScopeID , tbl3.AccessScopeName as Module , tbl1.ConfigValue '+
              ' From tb_Config tbl1 ' +
	      ' inner join tb_ConfigDataType tbl2 on tbl1.ConfigDataTypeID = tbl2.ConfigDataTypeID ' +
	      ' inner join tb_AccessScope tbl3 on tbl1.AccessScopeID = tbl3.AccessScopeID ' +
	      ' where tbl1.AccessScopeID = '  +
	      Case
		   When @AccessScopeID =  0 then ' tbl1.AccessScopeID '
		   Else convert(varchar(100) , @AccessScopeID)
	      End
	      
print @SQLStr	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@ConfigName is NULL) then ''
				   When (@ConfigName = '_') then ' and tbl1.ConfigName like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@ConfigName) =  1 ) and ( @ConfigName = '%') ) then ''
				   When ( right(@ConfigName ,1) = '%' ) then ' and tbl1.ConfigName like ' + '''' + substring(@ConfigName,1 , len(@ConfigName) - 1) + '%' + ''''
				   Else ' and tbl1.ConfigName like ' + '''' + @ConfigName + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl3.AccessScopeName ,tbl1.ConfigName' 

print @SQLStr

Exec (@SQLStr)

Return
GO
