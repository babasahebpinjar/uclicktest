USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateList]
(
	@RateDimensionTemplate varchar(100) =  NULL,
	@RateDimensionID int
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @RateDimensionTemplate is not Null ) and ( len(@RateDimensionTemplate) = 0 ) )
	set @RateDimensionTemplate = NULL

if ( ( @RateDimensionTemplate <> '_') and charindex('_' , @RateDimensionTemplate) <> -1 )
Begin

	set @RateDimensionTemplate = replace(@RateDimensionTemplate , '_' , '[_]')

End

if @RateDimensionID is NULL
	set @RateDimensionID = 0 -- All Rate Dimensions

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'select tbl1.RateDimensionTemplateID as ID, tbl1.RateDimensionTemplate as Name
			   from tb_RateDimensionTemplate tbl1
			   Right Join tb_RateDimension tbl2 on tbl1.RateDimensionID = tbl2.RateDimensionID ' +
			  ' where isnull(tbl1.flag,0) & 1 <> 1 ' +
			   		Case 
						When @RateDimensionID = 0 then ''
						Else ' and tbl2.RateDimensionID  = ' + convert(varchar(20) , @RateDimensionID)
					End 


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
			   When (@RateDimensionTemplate is NULL) then ''
			   When (@RateDimensionTemplate = '_') then ' and tbl1.RateDimensionTemplate like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@RateDimensionTemplate) =  1 ) and ( @RateDimensionTemplate = '%') ) then ''
			   When ( right(@RateDimensionTemplate ,1) = '%' ) then ' and tbl1.RateDimensionTemplate like ' + '''' + substring(@RateDimensionTemplate,1 , len(@RateDimensionTemplate) - 1) + '%' + ''''
			   Else ' and tbl1.RateDimensionTemplate like ' + '''' + @RateDimensionTemplate + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.RateDimensionTemplate' 

--print @SQLStr

Exec (@SQLStr)

Return 0
GO
