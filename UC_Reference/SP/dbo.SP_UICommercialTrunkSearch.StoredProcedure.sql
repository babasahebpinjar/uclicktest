USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommercialTrunkSearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICommercialTrunkSearch]
(
   @Account varchar(60) = NULL,
   @TrunkName varchar(60) = NULL,
   @SwitchID int  ,
   @StatusID int 
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000)


if (( @Account is not Null ) and ( len(@Account) = 0 ) )
	set @Account = NULL

if (( @TrunkName is not Null ) and ( len(@TrunkName) = 0 ) )
	set @TrunkName = NULL


if ( ( @Account <> '_') and charindex('_' , @Account) <> -1 )
Begin

	set @Account = replace(@Account , '_' , '[_]')

End

if ( ( @TrunkName <> '_') and charindex('_' , @TrunkName) <> -1 )
Begin

	set @TrunkName = replace(@TrunkName , '_' , '[_]')

End


--------------------------------------------------------------
-- Create temporary table to store the data befor displaying
--------------------------------------------------------------

Create table #TempAllCommercialTrunkData
(
	Switch varchar(60),
	TrunkID int,
	Trunk varchar(60),
	Account varchar(60),
	ActiveStatus varchar(60),
	AvailablePorts int,
	ActivatedPorts int
)


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl3.Switch ,tbl1.trunkID , tbl1.Trunk , tbl2.Account , tbl5.ActiveStatus , NULL , NULL'+ CHAR(10) +
              ' From tb_trunk tbl1 ' +
			  ' inner join tb_Account tbl2 on tbl1.AccountID = tbl2.AccountID ' + CHAR(10) +
			  ' inner join tb_Switch tbl3 on tbl1.switchID = tbl3.SwitchID ' + CHAR(10) +
			  ' inner join tb_trunkdetail tbl4 on tbl1.trunkid = tbl4.trunkid ' + CHAR(10) +
			  ' inner join tb_ActiveStatus tbl5 on tbl4.ActivestatusID = tbl5.ActiveStatusID ' + CHAR(10) +
			  ' where tbl1.Flag & 1 <> 1 '  + CHAR(10) +
			  ' and tbl1.trunktypeid = 9 ' + CHAR(10) +
			  ' and tbl4.EffectiveDate  = ' + CHAR(10) +
			  ' ( select max(EffectiveDate) from tb_trunkdetail tbl41 ' + CHAR(10) +
			  ' where tbl1.trunkid = tbl41.trunkid ' + CHAR(10) +
			  ' and tbl41.flag & 1 <> 1 ) ' + CHAR(10) +
			  Case
			   When @SwitchID =  0 then ' and tbl3.switchtypeid = 5 '
			   Else ' and tbl1.SwitchID = ' + convert(varchar(20) , @SwitchID) + ' and tbl3.switchtypeid = 5 '
			  End + CHAR(10) +
			  Case
				When @StatusID = 0 then ''
				Else ' and tbl4.ActiveStatusID = ' + CONVERT(varchar(10) , @StatusID )
			  End
			  
	      
	      

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




-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl3.Switch ,tbl1.Trunk , tbl2.Account ' 

--print @SQLStr

insert into #TempAllCommercialTrunkData
Exec (@SQLStr)

-----------------------------------------------------------
-- Start a cursor on each of the commercial trunk to get 
-- the activated and available ports
-----------------------------------------------------------

Declare @ActivatedPorts int,
        @AvailablePorts int,
        @CommercialTrunkID int
        
Declare Get_AllPorts_Cur Cursor For
Select trunkID
from  #TempAllCommercialTrunkData   

Open Get_AllPorts_Cur
Fetch Next From Get_AllPorts_Cur Into @CommercialTrunkID

While @@FETCH_STATUS = 0
Begin

        Exec SP_UIGetAssociatedTechnicalTrunks @CommercialTrunkID , 0 , @AvailablePorts output ,@ActivatedPorts output
        
        update #TempAllCommercialTrunkData
        set AvailablePorts = @AvailablePorts,
            ActivatedPorts = @ActivatedPorts
        where TrunkID =  @CommercialTrunkID          

		Fetch Next From Get_AllPorts_Cur Into @CommercialTrunkID
		
End
 
Close Get_AllPorts_Cur
DeAllocate Get_AllPorts_Cur

select *
from #TempAllCommercialTrunkData
order by switch , Trunk , Account

-----------------------------------------------------
-- Drop all temp tables created during the processing
-----------------------------------------------------

Drop table #TempAllCommercialTrunkData

Return
GO
