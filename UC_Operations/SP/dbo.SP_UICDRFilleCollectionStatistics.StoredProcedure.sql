USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRFilleCollectionStatistics]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICDRFilleCollectionStatistics]
(
	@CDRFileName varchar(100),
	@BeginDate datetime,
	@EndDate datetime,
	@CollectionProcess varchar(100),
	@CDRObjectID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@Clause2 varchar(1000)

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------
-- Check to ensure that begin date is less than equal to 
-- End Date
------------------------------------------------------------

if  ( @BeginDate > @EndDate )
Begin

		set @ErrorDescription = 'ERROR !!!!! Begin Date cannot be greater than End Date'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

---------------------------------------------------
-- Optimize the CDR File Name Regular Expression
---------------------------------------------------

set @CDRFileName = rtrim(ltrim(@CDRFileName))

if (( @CDRFileName is not Null ) and ( len(@CDRFileName) = 0 ) )
	set @CDRFileName = NULL

if ( ( @CDRFileName <> '_') and charindex('_' , @CDRFileName) <> -1 )
Begin

	set @CDRFileName = replace(@CDRFileName , '_' , '[_]')

End


---------------------------------------------------------------
-- Optimize the Collection Process Name to  Regular Expression
---------------------------------------------------------------

set @CollectionProcess = rtrim(ltrim(@CollectionProcess))

if (( @CollectionProcess is not Null ) and ( len(@CollectionProcess) = 0 ) )
	set @CollectionProcess = NULL

if ( ( @CollectionProcess <> '_') and charindex('_' , @CollectionProcess) <> -1 )
Begin

	set @CollectionProcess = replace(@CollectionProcess , '_' , '[_]')

End

--------------------------------------------------
-- Check what CDR file status has been seleected 
--------------------------------------------------

if  ( ( isnull(@CDRObjectID, 0) <> 0 ) and not exists ( select 1 from tb_Object where ObjectID =  @CDRObjectID and ObjectTypeID = 100))
Begin

		set @ErrorDescription = 'ERROR !!!!! CDR Load Object ID passed as parameter is not valid '
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

if ( isnull(@CDRObjectID, 0) = 0 ) -- All status
	set @CDRObjectID = NULL


Begin Try


		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileList') )
				Drop table #TempCDRFileList

		select tbl1.CDRFileName , tbl1.FileCollectDate , tbl1.OriginalFileSizeInKB,
			   tbl1.CollectFileSizeInKB , tbl2.ObjectInstance as CollectionProcess,
			   tbl3.ObjectName as CDRLoadObject
        into #TempCDRFileList
		from tb_CDRFileCollectionStatistics tbl1
		inner join tb_ObjectInstance tbl2 on tbl1.CDRCollectionProcessInstanceID = tbl2.ObjectInstanceID
		inner join tb_Object tbl3 on tbl1.CDRLoadObjectID = tbl3.ObjectID
		Where convert(date , tbl1.FileCollectDate) between @BeginDate and @EndDate
		and tbl1.CDRLoadObjectID = 
			Case
				When @CDRObjectID is NULL then tbl1.CDRLoadObjectID
				Else @CDRObjectID
			End

		----------------------------------------------------
		-- Build the dynamic SQL to display the result set
		----------------------------------------------------

		set @SQLStr = 
			 ' Select  CDRFileName , FileCollectDate , OriginalFileSizeInKB , CollectFileSizeInKB , CollectionProcess , CDRLoadObject ' + char(10) +
			 ' from #TempCDRFileList ' + char(10)

		set @Clause1 = 
				   Case
					   When (@CDRFileName is NULL) then ''
					   When (@CDRFileName = '_') then ' where CDRFileName like '  + '''' + '%' + '[_]' + '%' + ''''
					   When ( ( Len(@CDRFileName) =  1 ) and ( @CDRFileName = '%') ) then ''
					   When ( right(@CDRFileName ,1) = '%' ) then ' where CDRFileName like ' + '''' + substring(@CDRFileName,1 , len(@CDRFileName) - 1) + '%' + ''''
					   Else ' where CDRFileName like ' + '''' + @CDRFileName + '%' + ''''
				   End

        if (@CDRFileName is NULL)
		Begin

				set @Clause2 = 
						   Case
							   When (@CollectionProcess is NULL) then ''
							   When (@CollectionProcess = '_') then ' where CollectionProcess like '  + '''' + '%' + '[_]' + '%' + ''''
							   When ( ( Len(@CollectionProcess) =  1 ) and ( @CollectionProcess = '%') ) then ''
							   When ( right(@CollectionProcess ,1) = '%' ) then ' where CollectionProcess like ' + '''' + substring(@CollectionProcess,1 , len(@CollectionProcess) - 1) + '%' + ''''
							   Else ' where CollectionProcess like ' + '''' + @CollectionProcess + '%' + ''''
						   End

		End

		Else
		Begin

				set @Clause2 = 
						   Case
							   When (@CollectionProcess is NULL) then ''
							   When (@CollectionProcess = '_') then ' and CollectionProcess like '  + '''' + '%' + '[_]' + '%' + ''''
							   When ( ( Len(@CollectionProcess) =  1 ) and ( @CollectionProcess = '%') ) then ''
							   When ( right(@CollectionProcess ,1) = '%' ) then ' and CollectionProcess like ' + '''' + substring(@CollectionProcess,1 , len(@CollectionProcess) - 1) + '%' + ''''
							   Else ' and CollectionProcess like ' + '''' + @CollectionProcess + '%' + ''''
						   End

		End

		set @SQLStr  = @SQLStr + @Clause1 + @Clause2

		--print @SQLStr

		Exec(@SQLStr)


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Extracting CDR File Collection Statistics. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileList') )
		Drop table #TempCDRFileList

Return 0
GO
