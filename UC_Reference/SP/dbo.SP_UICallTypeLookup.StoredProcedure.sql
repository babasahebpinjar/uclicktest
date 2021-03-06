USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICallTypeLookup]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICallTypeLookup]
(
    @Calltype varchar(60) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


set @Calltype = rtrim(ltrim(@Calltype))

if (( @Calltype is not Null ) and ( len(@Calltype) = 0 ) )
	set @Calltype = NULL

if ( ( @Calltype <> '_') and charindex('_' , @Calltype) <> -1 )
Begin

	set @Calltype = replace(@Calltype , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.CallTypeID as ID, tbl1.Calltype as Name'+
              ' From tb_CallType tbl1 ' +
			  ' where tbl1.flag & 1 <> 1 ' +
			  ' and UseFlag & 64 = 64 ' --- Use Call Type for rating


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@Calltype is NULL) then ''
				   When (@Calltype = '_') then ' and tbl1.CallType like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@Calltype) =  1 ) and ( @Calltype = '%') ) then ''
				   When ( right(@Calltype ,1) = '%' ) then ' and tbl1.CallType like ' + '''' + substring(@Calltype,1 , len(@Calltype) - 1) + '%' + ''''
				   Else ' and tbl1.CallType like ' + '''' + @Calltype + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.CallType ' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
