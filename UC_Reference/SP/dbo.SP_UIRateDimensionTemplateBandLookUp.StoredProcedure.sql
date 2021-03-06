USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateBandLookUp]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateBandLookUp]
(
	@RateDimensionBand varchar(100) =  NULL,
	@RateDimensionTemplateID int
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

--------------------------------------------------------
-- Select the Rate Dimension associated with the rate
-- structure
--------------------------------------------------------

if (( @RateDimensionBand is not Null ) and ( len(@RateDimensionBand) = 0 ) )
	set @RateDimensionBand = NULL

if ( ( @RateDimensionBand <> '_') and charindex('_' , @RateDimensionBand) <> -1 )
Begin

	set @RateDimensionBand = replace(@RateDimensionBand , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'select tbl1.RateDimensionBandID as ID , ''('' + tbl2.RateDimensionTemplate + '')'' + ''--->'' + ''('' + tbl1.RateDimensionBand + '')'' as Name
			   from tb_RateDimensionBand tbl1 ' +
			   ' inner join tb_RateDimensionTemplate tbl2 on tbl1.RateDimensionTemplateID = tbl2.RateDimensionTemplateID ' +
			   ' where tbl1.flag & 1 <> 1  and tbl2.flag & 1 <> 1' +
			   ' and tbl1.RateDimensionTemplateID  = ' + convert(varchar(20) , isnull(@RateDimensionTemplateID, 0))

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
			   When (@RateDimensionBand is NULL) then ''
			   When (@RateDimensionBand = '_') then ' and tbl1.RateDimensionBand like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@RateDimensionBand) =  1 ) and ( @RateDimensionBand = '%') ) then ''
			   When ( right(@RateDimensionBand ,1) = '%' ) then ' and tbl1.RateDimensionBand like ' + '''' + substring(@RateDimensionBand,1 , len(@RateDimensionBand) - 1) + '%' + ''''
			   Else ' and tbl1.RateDimensionBand like ' + '''' + @RateDimensionBand + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.RateDimensionBand' 

--print @SQLStr

Exec (@SQLStr)

Return 0
GO
