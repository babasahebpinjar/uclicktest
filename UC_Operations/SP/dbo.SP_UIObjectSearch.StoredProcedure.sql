USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectSearch]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIObjectSearch] 
(
    @ObjectName varchar(100) = NULL,
    @ObjectTypeID int
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @ObjectName is not Null ) and ( len(@ObjectName) = 0 ) )
	set @ObjectName = NULL


if ( ( @ObjectName <> '_') and charindex('_' , @ObjectName) <> -1 )
Begin

	set @ObjectName = replace(@ObjectName , '_' , '[_]')

End

---------------------------------------------
-- Incase ObjectTypeID is NULL, set it to 0
---------------------------------------------

set @ObjectTypeID = ISNULL(@ObjectTypeID , 0)

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.ObjectID , tbl1.ObjectName, tbl2.ObjectTypeID , tbl2.ObjectTypeName '+
              ' From tb_Object tbl1 ' +
	      ' inner join tb_Objecttype tbl2 on tbl1.ObjectTypeID = tbl2.ObjectTypeID ' +
	      ' where tbl1.Flag & 1 <> 1 '  +
	      Case
		   When @ObjectTypeID <>  0 then ' and tbl1.ObjectTypeID = ' + convert(varchar(10) , @ObjectTypeID)
		   Else ''
	      End
	      
	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
		   When (@ObjectName is NULL) then ''
		   When (@ObjectName = '_') then ' and tbl1.ObjectName like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@ObjectName) =  1 ) and ( @ObjectName = '%') ) then ''
		   When ( right(@ObjectName ,1) = '%' ) then ' and tbl1.ObjectName like ' + '''' + substring(@ObjectName,1 , len(@ObjectName) - 1) + '%' + ''''
		   Else ' and tbl1.ObjectName like ' + '''' + @ObjectName + '%' + ''''
	       End




-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl2.ObjectTypeName , tbl1.ObjectName' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
