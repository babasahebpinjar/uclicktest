USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedGetFormatterDiscardDetailsSearch]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedGetFormatterDiscardDetailsSearch]
(
	@FileName varchar(200) = NULL,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @Clause1 varchar(1000)


if (( @FileName is not Null ) and ( len(@FileName) = 0 ) )
	set @FileName = NULL


if ( ( @FileName <> '_') and charindex('_' , @FileName) <> -1 )
Begin

	set @FileName = replace(@FileName , '_' , '[_]')

End

-------------------------------------------------------------
-- Store the name of the DISCARD fields in a temporary table
-------------------------------------------------------------


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_DiscardFieldNames') )
	Drop table #temp_DiscardFieldNames

select convert(int ,substring(tbl2.Name , 9 ,len(tbl2.Name))) as ID ,tbl2.name as FieldName
into #temp_DiscardFieldNames
from sysobjects tbl1
inner join syscolumns tbl2 on tbl1.ID = tbl2.ID
where tbl1.name = 'tb_MedFormatterOutputDiscardDetails'
and tbl1.xtype = 'U'
and tbl2.name like 'Discard_%'
order by convert(int ,substring(tbl2.Name , 9 ,len(tbl2.Name)))

------------------------------------------------
-- Open a cursor to prepare dynmaic SQL query
------------------------------------------------

Declare @FieldName varchar(100),
        @FieldAlias varchar(1000),
		@SQLStr nvarchar(max)

set @SQLStr = 'Select tbl1.CDRFileID, tbl2.CDRFileName,' + Char(10)

DECLARE db_Create_Dynamic_Query CURSOR FOR 
select tbl1.FieldName , tbl2.DiscardName
from #temp_DiscardFieldNames tbl1
inner join tb_FormatterDiscardRules tbl2 on tbl1.ID = tbl2.DiscardID
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

set @SQLStr = @SQLStr + 'From tb_MedFormatterOutputDiscardDetails tbl1 ' + Char(10) +
                        ' inner join tb_MedFormatterOutput tbl2 on tbl1.CDRFileID = tbl2.CDRFileID ' + Char(10) 
                        
set @Clause1 = 
           Case
				   When (@FileName is NULL) then ''
				   When (@FileName = '_') then ' where tbl2.CDRFileName like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@FileName) =  1 ) and ( @FileName = '%') ) then ''
				   When ( right(@FileName ,1) = '%' ) then ' where  tbl2.CDRFileName like ' + '''' + substring(@FileName,1 , len(@FileName) - 1) + '%' + ''''
				   Else ' where tbl2.CDRFileName like ' + '''' + @FileName + '%' + ''''
	       End

set @SQLStr = @SQLStr + @Clause1
		
--print @SQLStr

----------------------------------------------------------
-- Execute the prepared Dynamic SQL String for result set
----------------------------------------------------------

Begin Try

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While executing the query for fetching discard details. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_DiscardFieldNames') )
	Drop table #temp_DiscardFieldNames
GO
