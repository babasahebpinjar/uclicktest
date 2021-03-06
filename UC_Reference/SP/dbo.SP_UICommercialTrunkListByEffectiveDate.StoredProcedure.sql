USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommercialTrunkListByEffectiveDate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICommercialTrunkListByEffectiveDate]
(
    @CommercialTrunk varchar(60) = NULL,
	@AccountID int = NULL,
	@EffectiveDate Datetime
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@Clause2 varchar(1000)

set @CommercialTrunk = rtrim(ltrim(@CommercialTrunk))

if (( @CommercialTrunk is not Null ) and ( len(@CommercialTrunk) = 0 ) )
	set @CommercialTrunk = NULL

if ( ( @CommercialTrunk <> '_') and charindex('_' , @CommercialTrunk) <> -1 )
Begin

	set @CommercialTrunk = replace(@CommercialTrunk , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.TrunkID as ID, tbl1.Trunk as Name'+
              ' From tb_trunk tbl1 ' +
			  ' inner join tb_trunkDetail tbl2  on tbl1.trunkid = tbl2.trunkid ' +
			  ' where tbl1.flag & 1 <> 1 ' +
			  ' and tbl1.trunktypeid = 9' +
			  Case
					When @AccountID is Not NULL then ' and accountid =  ' +convert(varchar(10) , @AccountID)
					Else ''
			  End


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@CommercialTrunk is NULL) then ''
				   When (@CommercialTrunk = '_') then ' and tbl1.Trunk like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@CommercialTrunk) =  1 ) and ( @CommercialTrunk = '%') ) then ''
				   When ( right(@CommercialTrunk ,1) = '%' ) then ' and tbl1.Trunk like ' + '''' + substring(@CommercialTrunk,1 , len(@CommercialTrunk) - 1) + '%' + ''''
				   Else ' and tbl1.Trunk like ' + '''' + @CommercialTrunk + '%' + ''''
	       End

set @Clause2 = 
           ' and tbl2.EffectiveDate = ' +
		   ' ( ' +
		   '	select Max(EffectiveDate) ' +
		   '	from tb_trunkDetail tbl22 ' +
		   '	where tbl2.trunkID = tbl22.trunkID ' +
		   '	and tbl22.EffectiveDate <= ''' + convert(varchar(20) , @EffectiveDate , 120) + '''' +
		   ' ) ' 



-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Trunk ' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
