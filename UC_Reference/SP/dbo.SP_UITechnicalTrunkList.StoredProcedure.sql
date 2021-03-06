USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UITechnicalTrunkList]
(
    @TechnicalTrunk varchar(60) = NULL,
	@AccountIDList nvarchar(max),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@AllAccountFlag int = 0

set @TechnicalTrunk = rtrim(ltrim(@TechnicalTrunk))

if (( @TechnicalTrunk is not Null ) and ( len(@TechnicalTrunk) = 0 ) )
	set @TechnicalTrunk = NULL

if ( ( @TechnicalTrunk <> '_') and charindex('_' , @TechnicalTrunk) <> -1 )
Begin

	set @TechnicalTrunk = replace(@TechnicalTrunk , '_' , '[_]')

End

Begin Try

		-----------------------------------------------------------------
		-- Create table for list of selected Accounts from the parameter
		-- passed
		-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
			Drop table #TempAccountIDTable

		Create Table #TempAccountIDTable (AccountID varchar(100) )


		insert into #TempAccountIDTable
		select * from FN_ParseValueList ( @AccountIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempAccountIDTable where ISNUMERIC(AccountID) = 0 )
		Begin

		set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain a non numeric value'
		set @ResultFlag = 1
		GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
					select 1 
					from #TempAccountIDTable 
					where AccountID = 0
				)
		Begin

				set @AllAccountFlag = 1
				GOTO GENERATESCRIPT
				  
		End
		
		-----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
					select 1 
					from #TempAccountIDTable 
					where AccountID not in
					(
						Select AccountID
						from ReferenceServer.UC_Reference.dbo.tb_Account
						where flag & 1 <> 1
					)
				)
		Begin

		set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain value(s) which are not valid or do not exist'
		set @ResultFlag = 1
		GOTO ENDPROCESS

		End

GENERATESCRIPT:


		----------------------------------------
		-- Construct the initial part of the
		-- Dynamic Search SQL
		----------------------------------------

		set @SQLStr = 'Select tbl1.TrunkID as ID, tbl1.Trunk + ''/'' + tbl2.Switch as Name'+
					  ' From tb_trunk tbl1 ' +
					  ' inner join tb_Switch tbl2 on tbl1.SwitchID = tbl2.SwitchID ' + char(10) +
						Case
							When @AllAccountFlag = 1 then ''
							Else ' inner join #TempAccountIDTable tbl3 on tbl1.AccountID = tbl3.AccountID ' + char(10) 
						End + 
					  ' where tbl1.flag & 1 <> 1 ' +
					  ' and trunktypeid <> 9'  -- Not a Commercial Trunk !!!!!
			 			  


		--------------------------------------------
		-- Check the input parameters to decide on
		-- the conditional clause for the search
		--------------------------------------------

		set @Clause1 = 
				   Case
						   When (@TechnicalTrunk is NULL) then ''
						   When (@TechnicalTrunk = '_') then ' and tbl1.Trunk like '  + '''' + '%' + '[_]' + '%' + ''''
						   When ( ( Len(@TechnicalTrunk) =  1 ) and ( @TechnicalTrunk = '%') ) then ''
						   When ( right(@TechnicalTrunk ,1) = '%' ) then ' and tbl1.Trunk like ' + '''' + substring(@TechnicalTrunk,1 , len(@TechnicalTrunk) - 1) + '%' + ''''
						   Else ' and tbl1.Trunk like ' + '''' + @TechnicalTrunk + '%' + ''''
				   End


		-------------------------------------------------
		-- Prepare the complete dynamic search query
		-- and execute
		-------------------------------------------------

		set @SQLStr = @SQLStr + @Clause1 

		--------------------------------------------
		-- Add the sorting clause to the resut set
		--------------------------------------------

		set @SQLStr = @SQLStr  + ' order by tbl1.Trunk ' 

		--print @SQLStr

		Exec (@SQLStr)


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While Listing Technical Trunks. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
		Drop table #TempAccountIDTable

Return
GO
