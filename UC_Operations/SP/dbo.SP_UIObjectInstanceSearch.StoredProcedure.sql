USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectInstanceSearch]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIObjectInstanceSearch]
(
	@ObjectInstance varchar(100),
	@BeginDate datetime,
	@EndDate datetime,
	@ObjectTypeID int,
	@ObjectID int,
	@StatusID int
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @ObjectInstance is not Null ) and ( len(@ObjectInstance) = 0 ) )
	set @ObjectInstance = NULL


if ( ( @ObjectInstance <> '_') and charindex('_' , @ObjectInstance) <> -1 )
Begin

	set @ObjectInstance = replace(@ObjectInstance , '_' , '[_]')

End

---------------------------------------------
-- Incase ObjectTypeID is NULL, set it to 0
---------------------------------------------

set @ObjectTypeID = ISNULL(@ObjectTypeID , 0)

---------------------------------------------
-- Incase ObjectID is NULL, set it to 0
---------------------------------------------

set @ObjectID = ISNULL(@ObjectID , 0)

---------------------------------------------
-- Incase StatusID is NULL, set it to 0
---------------------------------------------

set @StatusID = ISNULL(@StatusID , 0)

----------------------------------------------------------
-- Build the dynamic SQL command to extract the essential
-- data
----------------------------------------------------------

set @SQLStr = 'Select tbl1.ObjectInstanceID , tbl1.ObjectInstance , tbl2.ObjectID , tbl2.ObjectName, ' + char(10) +
              ' tbl3.StatusID , tbl3.StatusName , tbl5.StatusGroupID , tbl5.StatusGroupName ' + char(10) +
			  ' from tb_ObjectInstance tbl1 ' + char(10) +
			  ' inner join tb_Object tbl2 on tbl1.ObjectID = tbl2.ObjectID ' + char(10) +
			  ' inner join tb_Status tbl3 on tbl1.statusID = tbl3.StatusID ' + char(10) +
			  ' inner join tb_StatusGroupMapping tbl4 on tbl3.StatusID = tbl4.StatusID ' + char(10) +
			  ' inner join tb_StatusGroup tbl5 on tbl4.StatusGroupID = tbl5.StatusGroupID ' + char(10) +
			  ' inner join tb_ObjectType tbl6 on tbl2	.ObjectTypeID = tbl6.ObjectTypeID ' + char(10) +
			  ' where convert(date , tbl1.ProcessStartTime) between ' + '''' + convert(varchar(10) , @BeginDate , 120) + '''' +
			                         ' and ''' + convert(varchar(10) , @EndDate , 120) + '''' + char(10) +
			  Case
					When @ObjectTypeID = 0 then ''
					Else ' and tbl6.ObjectTypeID = ' + convert(varchar(10) , @ObjectTypeID) + char(10) 
			  End +
			  Case
					When @ObjectID = 0 then ''
					Else ' and tbl1.ObjectID = ' + convert(varchar(10) , @ObjectID) + char(10) 
			  End +
			  Case
					When @StatusID = 0 then ''
					Else ' and tbl5.StatusGroupID = ' + convert(varchar(10) , @StatusID) + char(10) 
			  End 


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
		   When (@ObjectInstance is NULL) then ''
		   When (@ObjectInstance = '_') then ' and tbl1.ObjectInstance like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@ObjectInstance) =  1 ) and ( @ObjectInstance = '%') ) then ''
		   When ( right(@ObjectInstance ,1) = '%' ) then ' and tbl1.ObjectInstance like ' + '''' + substring(@ObjectInstance,1 , len(@ObjectInstance) - 1) + '%' + ''''
		   Else ' and tbl1.ObjectInstance like ' + '''' + @ObjectInstance + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl2.ObjectName , tbl5.StatusGroupName , tbl1.ObjectInstance ' 

print @SQLStr

Exec (@SQLStr)

Return			  
GO
