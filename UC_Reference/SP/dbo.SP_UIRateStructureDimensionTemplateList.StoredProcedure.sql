USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateStructureDimensionTemplateList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateStructureDimensionTemplateList]
(
	@RateDimensionTemplate varchar(100) =  NULL,
	@RateStructureID int,
	@RateItemID int
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@RateDimensionID int

--------------------------------------------------------
-- Select the Rate Dimension associated with the rate
-- structure
--------------------------------------------------------

select @RateDimensionID = (tbl2.RateItemID - 300)
from tb_RateStructureRateItem tbl1
inner join tb_RateItem tbl2 on tbl1.RateItemID = tbl2.RateItemID
where tbl1.RateStructureID = @RateStructureID
and tbl1.RateItemID = @RateItemID
and tbl2.RateItemTypeID = 3 -- Dimension Rate Item Type

if (( @RateDimensionTemplate is not Null ) and ( len(@RateDimensionTemplate) = 0 ) )
	set @RateDimensionTemplate = NULL

if ( ( @RateDimensionTemplate <> '_') and charindex('_' , @RateDimensionTemplate) <> -1 )
Begin

	set @RateDimensionTemplate = replace(@RateDimensionTemplate , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'select tbl1.RateDimensionTemplateID as ID , tbl1.RateDimensionTemplate as Name
			   from tb_RateDimensionTemplate tbl1 ' +
			   ' where tbl1.flag & 1 <> 1 ' +
			   ' and tbl1.RateDimensionID  = ' + convert(varchar(20) , isnull(@RateDimensionID, 0))

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
