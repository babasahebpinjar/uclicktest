USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedGetFormatterRejectDetailsSearchMonthly]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedGetFormatterRejectDetailsSearchMonthly]
(
    @SelectDate date = NULL,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @Clause1 varchar(1000),
        @CurrentYear int = Year(getdate()),
		@CurrentMonth int = Month(GetDate())


----------------------------------------------------------------------
-- If the select date is not NULL then set the year and month according
-- to passed date
-----------------------------------------------------------------------

if ( @SelectDate is not NULL )
Begin

		set  @CurrentYear  = Year(@SelectDate)
		set  @CurrentMonth = Month(@SelectDate)

End

-------------------------------------------------------------
-- Store the name of the DISCARD fields in a temporary table
-------------------------------------------------------------


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_ErrorFieldNames') )
	Drop table #temp_ErrorFieldNames

select convert(int ,substring(tbl2.Name , 7 ,len(tbl2.Name))) as ID ,tbl2.name as FieldName
into #temp_ErrorFieldNames
from sysobjects tbl1
inner join syscolumns tbl2 on tbl1.ID = tbl2.ID
where tbl1.name = 'tb_MedFormatterOutputRejectDetails'
and tbl1.xtype = 'U'
and tbl2.name like 'Error_%'
order by convert(int ,substring(tbl2.Name , 7 ,len(tbl2.Name)))

------------------------------------------------
-- Open a cursor to prepare dynmaic SQL query
------------------------------------------------

Declare @FieldName varchar(100),
        @FieldAlias varchar(1000),
		@SQLStr nvarchar(max)

set @SQLStr = 'Select ' + Char(10)

DECLARE db_Create_Dynamic_Query CURSOR FOR 
select tbl1.FieldName , tbl2.ErrorName
from #temp_ErrorFieldNames tbl1
inner join tb_FormatterErrorRules tbl2 on tbl1.ID = tbl2.ErrorID
order by tbl1.ID

OPEN db_Create_Dynamic_Query   
FETCH NEXT FROM db_Create_Dynamic_Query
INTO @FieldName, @FieldAlias

WHILE @@FETCH_STATUS = 0   
BEGIN  

       set @SQLStr = @SQLStr + 'sum('+@FieldName + ') ' + ' as ' + '''' + @FieldAlias + '''' + ',' + Char(10)

	   FETCH NEXT FROM db_Create_Dynamic_Query
	   INTO @FieldName, @FieldAlias
 
END   

CLOSE db_Create_Dynamic_Query  
DEALLOCATE db_Create_Dynamic_Query

set @SQLStr = SUBSTRING(@SQLStr , 1 , len(@SQLStr) -2 ) + Char(10)

set @SQLStr = @SQLStr + 'From tb_MedFormatterOutputRejectDetails tbl1 ' + Char(10) +
			 ' inner join tb_MedFormatterOutput tbl2 on tbl1.CDRFileID = tbl2.CDRFileID ' + Char(10)
                        
set @Clause1 = ' where month(convert(date , substring(tbl2.cdrfilename , 11,8))) = ' + Convert(varchar(2) ,@CurrentMonth) + Char(10) +
               ' and Year(convert(date , substring(tbl2.cdrfilename , 11,8))) = ' + convert(varchar(4) , @CurrentYear)

set @SQLStr = @SQLStr + @Clause1
		
print @SQLStr

----------------------------------------------------------
-- Execute the prepared Dynamic SQL String for result set
----------------------------------------------------------

Begin Try

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While executing the query for fetching reject details. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_ErrorFieldNames') )
	Drop table #temp_ErrorFieldNames
GO
