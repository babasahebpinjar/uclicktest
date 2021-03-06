USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkSearchByName]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UITechnicalTrunkSearchByName] 
(
    @TrunkName varchar(60) = NULL
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000),
	@Clause3 varchar(1000)



if ( ( @TrunkName <> '_') and charindex('_' , @TrunkName) <> -1 )
Begin

	set @TrunkName = replace(@TrunkName , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.trunkID as ID , tbl1.Trunk  as Name '+ CHAR(10) +
              ' From tb_trunk tbl1 ' +  CHAR(10) +
			  ' where tbl1.Flag & 1 <> 1 '  + CHAR(10) +
			  ' and tbl1.trunktypeid <> 9 '

	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------


set @Clause1 = 
           Case
		   When (@TrunkName is NULL) then ''
		   When (@TrunkName = '_') then ' and tbl1.Trunk like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@TrunkName) =  1 ) and ( @TrunkName = '%') ) then ''
		   When ( right(@TrunkName ,1) = '%' ) then ' and tbl1.Trunk like ' + '''' + substring(@TrunkName,1 , len(@TrunkName) - 1) + '%' + ''''
		   Else ' and tbl1.Trunk like ' + '''' + @TrunkName + '%' + ''''
	       End



-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--print @SQLStr

Exec (@SQLStr)

Return
GO
