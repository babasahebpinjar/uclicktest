USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkSearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UITechnicalTrunkSearch] 
(
   @Account varchar(60) = NULL,
    @TrunkName varchar(60) = NULL,
    @CDRMatch varchar(60) = NULL,
	@SwitchID int ,
	@StatusID int 
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000),
	@Clause3 varchar(1000)


if (( @Account is not Null ) and ( len(@Account) = 0 ) )
	set @Account = NULL

if (( @TrunkName is not Null ) and ( len(@TrunkName) = 0 ) )
	set @TrunkName = NULL

if (( @CDRMatch is not Null ) and ( len(@CDRMatch) = 0 ) )
	set @CDRMatch = NULL


if ( ( @Account <> '_') and charindex('_' , @Account) <> -1 )
Begin

	set @Account = replace(@Account , '_' , '[_]')

End

if ( ( @TrunkName <> '_') and charindex('_' , @TrunkName) <> -1 )
Begin

	set @TrunkName = replace(@TrunkName , '_' , '[_]')

End

if ( ( @CDRMatch <> '_') and charindex('_' , @CDRMatch) <> -1 )
Begin

	set @CDRMatch = replace(@CDRMatch , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl3.Switch ,tbl1.trunkID , tbl1.Trunk , tbl2.Account , tbl1.CDRMatch , 0 as ActivatedPorts , 0 as AvailablePorts , NULL as ActiveStatusID, NULL as ActiveStatus'+ CHAR(10) +
              ' From tb_trunk tbl1 ' +  CHAR(10) +
			  ' inner join tb_Account tbl2 on tbl1.AccountID = tbl2.AccountID ' + CHAR(10) +
			  ' inner join tb_Switch tbl3 on tbl1.switchID = tbl3.SwitchID ' + CHAR(10) +
			  ' where tbl1.Flag & 1 <> 1 '  + CHAR(10) +
			  ' and tbl1.trunktypeid <> 9 ' + CHAR(10) +
			  Case
			   When @SwitchID =  0 then ' and tbl3.switchtypeid <> 5 '
			   Else ' and tbl1.SwitchID = ' + convert(varchar(20) , @SwitchID) + ' and tbl3.switchtypeid <> 5 '
			  End --+ CHAR(10) +

	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@Account is NULL) then ''
		   When (@Account = '_') then ' and tbl2.Account like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@Account) =  1 ) and ( @Account = '%') ) then ''
		   When ( right(@Account ,1) = '%' ) then ' and tbl2.Account like ' + '''' + substring(@Account,1 , len(@Account) - 1) + '%' + ''''
		   Else ' and tbl2.Account like ' + '''' + @Account + '%' + ''''
	       End


set @Clause2 = 
               Case
		   When (@TrunkName is NULL) then ''
		   When (@TrunkName = '_') then ' and tbl1.Trunk like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@TrunkName) =  1 ) and ( @TrunkName = '%') ) then ''
		   When ( right(@TrunkName ,1) = '%' ) then ' and tbl1.Trunk like ' + '''' + substring(@TrunkName,1 , len(@TrunkName) - 1) + '%' + ''''
		   Else ' and tbl1.Trunk like ' + '''' + @TrunkName + '%' + ''''
	       End


set @Clause3 = 
               Case
		   When (@CDRMatch is NULL) then ''
		   When (@CDRMatch = '_') then ' and tbl1.CDRMatch like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@CDRMatch) =  1 ) and ( @CDRMatch = '%') ) then ''
		   When ( right(@CDRMatch ,1) = '%' ) then ' and tbl1.CDRMatch like ' + '''' + substring(@CDRMatch,1 , len(@CDRMatch) - 1) + '%' + ''''
		   Else ' and tbl1.CDRMatch like ' + '''' + @CDRMatch + '%' + ''''
	       End




-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2 + @Clause3

--print @SQLStr

--------------------------------------------
-- Create temporary table to hold records
--------------------------------------------

Create table #TempAllTechnicalTrunkRecords
(
	Switch  varchar(60),
	trunkID int , 
	Trunk varchar(60), 
	Account  varchar(60), 
	CDRMatch  varchar(60),
	ActivatedPorts int, 
	AvailablePorts int, 
	ActiveStatusID int,
	ActiveStatus varchar(60)
)

Insert into #TempAllTechnicalTrunkRecords
Exec (@SQLStr)

------------------------------------------------------------
-- Now populate the Active and Avaliable ports along with
-- active status for all the trunks
------------------------------------------------------------

------------------------
-- CURRENT DATED TRUNKS
------------------------
update tbl1
set tbl1.ActivatedPorts = tbl2.ActivatedPorts,
    tbl1.AvailablePorts = tbl2.AvailablePorts,
	tbl1.ActiveStatusID = tbl2.ActiveStatusID,
	tbl1.ActiveStatus = tbl3.ActiveStatus
from #TempAllTechnicalTrunkRecords tbl1
inner join tb_TrunkDetail tbl2 on tbl1.TrunkID = tbl2.TrunkID
inner join tb_ActiveStatus tbl3 on tbl2.ActiveStatusID = tbl3.ActiveStatusID
where tbl1.ActiveStatus is NULL
and tbl2.EffectiveDate = 
(
	Select max(EffectiveDate)
	from tb_TrunkDetail tbl4
	where tbl4.trunkID = tbl2.trunkID
	and effectivedate <= convert(date , getdate() )
)

----------------------------
-- FUTURE DATED TRUNKS
----------------------------

update tbl1
set tbl1.ActiveStatusID = tbl2.ActiveStatusID,
	tbl1.ActiveStatus = tbl3.ActiveStatus
from #TempAllTechnicalTrunkRecords tbl1
inner join tb_TrunkDetail tbl2 on tbl1.TrunkID = tbl2.TrunkID
inner join tb_ActiveStatus tbl3 on tbl2.ActiveStatusID = tbl3.ActiveStatusID
where tbl1.ActiveStatus is NULL
and tbl2.EffectiveDate = 
(
	Select min(EffectiveDate)
	from tb_TrunkDetail tbl4
	where tbl4.trunkID = tbl2.trunkID
	and effectivedate > convert(date , getdate() )
)


select Switch ,	trunkID , Trunk ,Account, CDRMatch, ActivatedPorts , 
	  AvailablePorts , ActiveStatus 
from #TempAllTechnicalTrunkRecords tbl1
where tbl1.ActiveStatusID = 
	Case
		When @StatusID = 0 Then tbl1.ActiveStatusID
		Else @StatusID
	End


Drop table #TempAllTechnicalTrunkRecords

Return
GO
