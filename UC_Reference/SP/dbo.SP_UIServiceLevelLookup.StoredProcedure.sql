USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIServiceLevelLookup]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIServiceLevelLookup]
(
    @ServiceLevel varchar(60) = NULL,
	@DirectionID int = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

set @ServiceLevel = rtrim(ltrim(@ServiceLevel))

if (( @ServiceLevel is not Null ) and ( len(@ServiceLevel) = 0 ) )
	set @ServiceLevel = NULL

if ( ( @ServiceLevel <> '_') and charindex('_' , @ServiceLevel) <> -1 )
Begin

	set @ServiceLevel = replace(@ServiceLevel , '_' , '[_]')

End

if (@DirectionID is NULL )
	set @DirectionID = 0


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.ServiceLevelID as ID, ' + 
               Case
					When  @DirectionID = 0 then ' tbl1.ServiceLevel + ''-'' + ''(''+tbl2.Direction+'')'''
					Else ' tbl1.ServiceLevel'
			   End + ' as Name'+
              ' From tb_ServiceLevel tbl1 ' +
			  ' inner join tb_Direction tbl2 on tbl1.DirectionId = tbl2.DirectionID ' +
			  ' where tbl1.flag & 1 <> 1 ' +
			  ' and tbl1.DirectionID =  '+
			        Case 
						When @DirectionID = 0 then ' tbl1.DirectionID '
						Else convert(varchar(20) , @DirectionID )
					End 


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@ServiceLevel is NULL) then ''
				   When (@ServiceLevel = '_') then ' and tbl1.ServiceLevel like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@ServiceLevel) =  1 ) and ( @ServiceLevel = '%') ) then ''
				   When ( right(@ServiceLevel ,1) = '%' ) then ' and tbl1.ServiceLevel like ' + '''' + substring(@ServiceLevel,1 , len(@ServiceLevel) - 1) + '%' + ''''
				   Else ' and tbl1.ServiceLevel like ' + '''' + @ServiceLevel + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.ServiceLevel ' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
