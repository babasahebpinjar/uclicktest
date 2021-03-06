USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIReferencePriceList]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIReferencePriceList]
(
	@ReferencePriceList varchar(100) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @ReferencePriceList is not Null ) and ( len(@ReferencePriceList) = 0 ) )
	set @ReferencePriceList = NULL


if ( ( @ReferencePriceList <> '_') and charindex('_' , @ReferencePriceList) <> -1 )
Begin

	set @ReferencePriceList = replace(@ReferencePriceList , '_' , '[_]')

End


----------------------------------------------------------
-- Prepare the dynamic SQL query for the search criteria
----------------------------------------------------------

set @SQLStr = 'Select tbl1.SourceID as ID, tbl1.Source as Name  ' +
              ' from tb_Source tbl1 ' +
			  ' where tbl1.SourcetypeID = -7 ' -- Reference Price List
			 

-----------------------------------------------------
-- Prepare the extended clause for the search query	
-----------------------------------------------------

set @Clause1 = 
           Case
			   When (@ReferencePriceList is NULL) then ''
			   When (@ReferencePriceList = '_') then ' and tbl1.Source like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@ReferencePriceList) =  1 ) and ( @ReferencePriceList = '%') ) then ''
			   When ( right(@ReferencePriceList ,1) = '%' ) then ' and tbl1.Source like ' + '''' + substring(@ReferencePriceList,1 , len(@ReferencePriceList) - 1) + '%' + ''''
			   Else ' and tbl1.Source like ' + '''' + @ReferencePriceList + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1	

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Source' 

--print @SQLStr

Exec (@SQLStr)

Return
	  			  			  			   
GO
