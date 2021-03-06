USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDestinationList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDestinationList]
(
    @DestinationName varchar(60) = NULL,
	@NumberPlanID int = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

set @DestinationName = rtrim(ltrim(@DestinationName))

if (( @DestinationName is not Null ) and ( len(@DestinationName) = 0 ) )
	set @DestinationName = NULL

if ( ( @DestinationName <> '_') and charindex('_' , @DestinationName) <> -1 )
Begin

	set @DestinationName = replace(@DestinationName , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.DestinationID as ID, ' +
'tbl1.Destination  + '' '' + ''('' +replace(CONVERT(varchar(10) , BeginDate , 120 ) , ''-'' , ''/'') + '' - ''+ 
							Case
									When EndDate is not NULL then replace(CONVERT(varchar(10) , EndDate , 120 ) , ''-'' , ''/'')
									Else ''Open''
							End  + '')'' as Name' +
              ' From tb_Destination tbl1 ' +
			  ' where tbl1.flag & 1 <> 1 ' +
			  Case
					When @NumberPlanID is Not NULL then ' and numberplanid =  ' +convert(varchar(10) , @NumberPlanID)
					Else ' and numberplanid = -1' -- By default return the list of Routing Destinations
			  End


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@DestinationName is NULL) then ''
				   When (@DestinationName = '_') then ' and tbl1.Destination like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@DestinationName) =  1 ) and ( @DestinationName = '%') ) then ''
				   When ( right(@DestinationName ,1) = '%' ) then ' and tbl1.Destination like ' + '''' + substring(@DestinationName,1 , len(@DestinationName) - 1) + '%' + ''''
				   Else ' and tbl1.Destination like ' + '''' + @DestinationName + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Destination ' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
