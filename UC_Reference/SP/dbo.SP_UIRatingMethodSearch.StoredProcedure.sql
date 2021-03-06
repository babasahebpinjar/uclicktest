USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodSearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodSearch]
(
	@RatingMethod varchar(100) =  NULL,
	@RateStructureID int
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @RatingMethod is not Null ) and ( len(@RatingMethod) = 0 ) )
	set @RatingMethod = NULL

if ( ( @RatingMethod <> '_') and charindex('_' , @RatingMethod) <> -1 )
Begin

	set @RatingMethod = replace(@RatingMethod , '_' , '[_]')

End

if @RateStructureID is NULL
	set @RateStructureID = 0 -- All Rate Structures

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'select tbl2.RateStructureID , tbl2.RateStructure,
			   tbl1.RatingMethodID , tbl1.RatingMethod
			   from tb_RatingMethod tbl1
			   Right join tb_RateStructure tbl2 on tbl1.RateStructureID = tbl2.RateStructureID ' +
			  ' where isnull(tbl1.flag, 0) & 1 <> 1 ' +
			   		Case 
						When @RateStructureID = 0 then ''
						Else ' and tbl2.RateStructureID  = ' + convert(varchar(20) , @RateStructureID)
					End 


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
			   When (@RatingMethod is NULL) then ''
			   When (@RatingMethod = '_') then ' and tbl1.RatingMethod like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@RatingMethod) =  1 ) and ( @RatingMethod = '%') ) then ''
			   When ( right(@RatingMethod ,1) = '%' ) then ' and tbl1.RatingMethod like ' + '''' + substring(@RatingMethod,1 , len(@RatingMethod) - 1) + '%' + ''''
			   Else ' and tbl1.RatingMethod like ' + '''' + @RatingMethod + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl2.RateStructure , tbl1.RatingMethod' 

--print @SQLStr

Exec (@SQLStr)

Return 0
GO
