USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedGetFormatterFileRejectRecords]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedGetFormatterFileRejectRecords]
(
	@CDRFileID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------------
-- Check to ensure that the CDR File ID exists in the system
---------------------------------------------------------------

if not exists ( Select 1 from tb_MedFormatterOutput where CDRFileID = @CDRFileID )
Begin

		set @ErrorDescription = 'ERROR !!!! There is no Formatter output file for the CDR File ID provided'
		set @ResultFlag = 1

		GOTO ENDPROCESS

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

set @SQLStr = 'Select CDRFileID,' + Char(10)

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

       set @SQLStr = @SQLStr + @FieldName + ' as ' + '''' + @FieldAlias + '''' + ',' + Char(10)

	   FETCH NEXT FROM db_Create_Dynamic_Query
	   INTO @FieldName, @FieldAlias
 
END   

CLOSE db_Create_Dynamic_Query  
DEALLOCATE db_Create_Dynamic_Query

set @SQLStr = SUBSTRING(@SQLStr , 1 , len(@SQLStr) -2 ) + Char(10)

set @SQLStr = @SQLStr + 'From tb_MedFormatterOutputRejectDetails ' + Char(10) +
                        'where CDRFileID = ' + convert(varchar(100) , @CDRFileID)
		
--print @SQLStr

----------------------------------------------------------
-- Execute the prepared Dynamic SQL String for result set
----------------------------------------------------------

Begin Try

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While executing the query for fetching reject records. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_ErrorFieldNames') )
	Drop table #temp_ErrorFieldNames
GO
