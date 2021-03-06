USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_TempCallFailByReleaseCause]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_TempCallFailByReleaseCause]
(
	@INAccount varchar(100) = NULL,
	@OUTAccount varchar(100) = NULL,
	@Country varchar(100) = NULL,
	@BeginDate date,
	@EndDate date
)
As


Declare @SQLStr varchar(max),
        @ErrorMsgStr varchar(2000)

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCallFailByReleaseCause') )
		Drop table #TempCallFailByReleaseCause

Create table #TempCallFailByReleaseCause
(
	CallDate date,
	ReleaseCause int,
	TotalCalls int
)

Begin Try

		-- Extract the data using the dynamic Query

		set @SQLStr = 'Insert into #TempCallFailByReleaseCause ' + char(10) +
					  'Select CallDate , ReleaseCause , count(*) ' + char(10)+
					  'from tb_CDRFileDataAnalyzed ' + char(10)+
					  'where CallDate between ''' + convert(varchar(10), @BeginDate,120) + ''' and ''' + convert(varchar(10), @EndDate,120) + '''' + char(10)+
					  Case
							When @INAccount is not NULL then 'and INAccount = ''' + @INAccount + '''' + char(10)
							Else ''
					  End +

					  Case
							When @OutAccount is not NULL then 'and OUTAccount = ''' + @OutAccount + '''' + char(10)
							Else ''
					  End +

					  Case
							When @Country is not NULL then 'and Country = ''' + @Country + '''' + char(10)
							Else ''
					  End +
					  'Group by CallDate , ReleaseCause'

		--print @SQLStr

		Exec(@SQLStr)

End Try

Begin Catch
		
			set @ErrorMsgStr = 'Error !!! While extracting data.' + ERROR_MESSAGE()
			RaisError('%s' , 16 ,1 , @ErrorMsgStr)
			GOTO ENDPROCESS

End Catch

if not exists (select 1 from #TempCallFailByReleaseCause)
Begin

		Select 'No Data for Provided condition clause' as Result
		GOTO ENDPROCESS

End

-- Aggregate the data by Transpose along the Release Cause

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllReleaseCause') )
		Drop table #TempAllReleaseCause

select distinct ReleaseCause
into #TempAllReleaseCause
from #TempCallFailByReleaseCause
order by ReleaseCause

Alter table #TempAllReleaseCause Add RecordId int identity(1,1)

-- Build the dynamic Query for extracting the final results

Declare @Cntr int = 1,
		@MaxRec int,
		@SQLStr1 varchar(max),
		@SQLStr2 varchar(max),
		@SQLStr3 varchar(max),
		@VarReleaseCause int

select @MaxRec = Max(RecordID)
from #TempAllReleaseCause

Begin Try

		set @SQLStr1 = 'Select CallDate ' 
		set @SQLStr3 = 'Select CallDate ' 
		set @SQLStr2 = 'Sum(TotalCalls) ' + char(10) +
					   'For ReleaseCause IN ' +  char(10) +
					   '(' + char(10)

		While ( @Cntr <= @MaxRec )
		Begin

				select @VarReleaseCause = Releasecause
				from #TempAllReleaseCause
				where RecordID = @Cntr

				set @SQLStr1 = @SQLStr1 + ', ['+convert(varchar(10) , @VarReleaseCause) + ']'
				set @SQLStr3 = @SQLStr3 + ', isnull(['+convert(varchar(10) , @VarReleaseCause) + '],0) as '''+convert(varchar(10) , @VarReleaseCause) + '''' + char(10)
				set @SQLStr2 = @SQLStr2 + '['+convert(varchar(10) , @VarReleaseCause) + '],'

				set @Cntr = @Cntr + 1

		End

		set @SQLStr1 = @SQLStr1 + char(10) + 'From #TempCallFailByReleaseCause' + char(10) + 'PIVOT' + char(10)
		set @SQLStr2 = '(' + char(10) + substring(@SQLStr2 , 1 , len(@SQLStr2) -1)+  char(10) + ')' + char(10) + ') as PivotTable'
		set @SQLStr3 = @SQLStr3 + char(10) + 'From' + char(10) + '(' + char(10)
		set @SQLStr = @SQLStr3 + @SQLStr1 + @SQLStr2 + ') as Tbl1'

		--print @SQLStr

		Exec(@SQLStr)

End Try

Begin Catch
		
			set @ErrorMsgStr = 'Error !!! While Transposing the data across Release Cause.' + ERROR_MESSAGE()
			RaisError('%s' , 16 ,1 , @ErrorMsgStr)
			GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCallFailByReleaseCause') )
		Drop table #TempCallFailByReleaseCause

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllReleaseCause') )
		Drop table #TempAllReleaseCause
GO
