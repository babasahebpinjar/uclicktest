USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRProcessingRuleSearch_Old]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICDRProcessingRuleSearch_Old] 
(
    @Prefix varchar(100) = NULL,
	@TrunkID int ,
	@DirectionID int,
	@ServiceLevelID int,
	@StatusID int
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000),
	    @Clause3 varchar(1000)


if (( @Prefix is not Null ) and ( len(@Prefix) = 0 ) )
	set @Prefix = NULL


if ( ( @Prefix <> '_') and charindex('_' , @Prefix) <> -1 )
Begin

	set @Prefix = replace(@Prefix , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.CDRProcessingRuleID ,tbl1.RuleOrder , tbl1.PrefixCode , tbl2.Trunk , tbl3.Direction , tbl4.ServiceLevel, tbl1.BeginDate , tbl1.EndDate'+ CHAR(10) +
              ' From tb_CDRProcessingRule tbl1 ' +  CHAR(10) +
			  ' inner join tb_Trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID ' + CHAR(10) +
			  ' inner join tb_Direction tbl3 on tbl1.DirectionID = tbl3.DirectionID ' + CHAR(10) +
			  ' inner join tb_ServiceLevel tbl4 on tbl1.ServiceLevelID = tbl4.ServiceLevelID ' +  CHAR(10) +
			  ' where tbl2.Flag & 1 <> 1 '  + CHAR(10) +
			  Case
				   When @TrunkID =  0 then ''
				   Else ' and tbl1.TrunkID = ' + convert(varchar(20) , @TrunkID) 
			  End + CHAR(10) +
			  Case
				   When @DirectionID in (0,3) then ''
				   Else ' and tbl1.DirectionID = ' + convert(varchar(20) , @DirectionID) 
			  End + CHAR(10) +
			  Case
				   When @StatusID =  0 then ''
				   When @StatusID =  1 then ' and ( ( convert(date , getdate()) between tbl1.BeginDate and isnull(tbl1.EndDate , convert(date , getdate())) ) or (tbl1.BeginDate > convert(date , getdate())) ) '
				   When @StatusID =  2 then ' and tbl1.EndDate is Not Null and tbl1.EndDate < convert(date , getdate()) '
			  End + CHAR(10) +
			  Case
				   When @ServiceLevelID =  0 then ''
				   Else ' and tbl1.ServiceLevelID = ' + convert(varchar(20) , @ServiceLevelID) 
			  End
			        

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				When (@Prefix is NULL) then ''
				When (@Prefix = '_') then ' and tbl1.PrefixCode like '  + '''' + '%' + '[_]' + '%' + ''''
				When ( ( Len(@Prefix) =  1 ) and ( @Prefix = '%') ) then ''
				When ( right(@Prefix ,1) = '%' ) then ' and tbl1.PrefixCode like ' + '''' + substring(@Prefix,1 , len(@Prefix) - 1) + '%' + ''''
				Else ' and tbl1.PrefixCode like ' + '''' + @Prefix + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

set @SQLStr = @SQLStr + ' order by tbl2.Trunk , tbl3.Direction , convert(int ,tbl1.RuleOrder) ,tbl4.ServiceLevel'

print @SQLStr

Exec (@SQLStr)

Return
GO
