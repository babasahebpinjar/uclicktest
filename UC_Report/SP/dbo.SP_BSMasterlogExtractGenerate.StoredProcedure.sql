USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogExtractGenerate]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSMasterlogExtractGenerate]
(
    @CallID nvarchar(max),
    @CallingNumber nvarchar(max),
    @CalledNumber nvarchar(max),
	@RowsCount int Output,
	@MasterlogExtractFileName varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As 

set @ErrorDescription = NULL
set @ResultFlag = 0


declare @cmd varchar(8000)
declare @finalFile varchar(8000)
declare @path varchar(8000)
declare @first int
declare @countVal  int
declare @logDate varchar(8000)
declare @name varchar(8000)
declare @rowCount  int
declare @Extractpath varchar(8000)
declare @ParsedPath varchar(8000)


select @Extractpath = ConfigValue 
from ReferenceServer.UC_Admin.dbo.tb_Config
where ConfigName = 'MasterLogExtractPath'
and AccessScopeID = -8 -- BI Reporting


select @ParsedPath = ConfigValue 
from ReferenceServer.UC_Admin.dbo.tb_Config
where ConfigName = 'MasterLogParsedPath'
and AccessScopeID = -8 -- BI Reporting

--set @path = ( select ConfigValue from ReferenceServer.UC_Admin.dbo.Tb_Config where Configname = 'MasterlogParsedFilesPath')

--set @path = 'C:\Deployment\data\parsedfiles'


print @path

set @finalFile = 'tb_MasterlogExtract_'+ format(getdate(),'yyyyMMddHHmmss') + '.txt'

/*
if not exists ( select 1 from ReferenceServer.UC_Admin.dbo.tb_Users where UserID = @UserID and USerstatusID = 1 )
Begin

		set @ErrorDescription = 'ERROR !!!! User ID passed for extract creation does not exist or is inactive'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End
*/



Declare @SQLStr nvarchar(max),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000),
	@Clause3 varchar(1000),
	@Remarks varchar(1000)


Declare @SQLCompare nvarchar(max)
Declare @OAM_A int
Declare @OAM_B int
Declare @ServerName varchar(100)


--set @starttime = convert(varchar, getdate(), 120)

/*
if (( @CallID is not Null ) and ( len(@CallID) = 0 ) )
Begin
	set @CallID = NULL
End

if (( @CallingNumber is not Null ) and ( len(@CallingNumber) = 0 ) )
Begin	
	set @CallingNumber = NULL
End

if (( @CalledNumber is not Null ) and ( len(@CalledNumber) = 0 ) )
Begin	
	set @CalledNumber = NULL
End

if ( ( @CallID <> '_') and charindex('_' , @CallID) <> -1 )
Begin

	set @CallID = replace(@CallID , '_' , '[_]')

End

if ( ( @CallingNumber <> '_') and charindex('_' , @CallingNumber) <> -1 )
Begin

	set @CallingNumber = replace(@CallingNumber , '_' , '[_]')

End

if ( ( @CalledNumber <> '_') and charindex('_' , @CalledNumber) <> -1 )
Begin

	set @CalledNumber = replace(@CalledNumber , '_' , '[_]')

End
*/

set @SQLStr = 'Select convert(varchar,tbl1.LogDate,112),tbl1.LogFilename' + 
              ' From tb_LogEntries tbl1 ' +
			  'where 1 = 1 ' 
	      
	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@CallID is NULL) then ''
		   When (@CallID = '_') then ' and tbl1.CallID like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@CallID) =  1 ) and ( @CallID = '%') ) then ''
		   When ( right(@CallID ,1) = '%' ) then ' and tbl1.CallID like ' + '''' + substring(@CallID,1 , len(@CallID) - 1) + '%' + ''''
		   Else ' and tbl1.CallID like ' + '''' + @CallID + '%' + ''''
	       End


set @Clause2 = 
               Case
		   When (@CallingNumber is NULL) then ''
		   When (@CallingNumber = '_') then ' and tbl1.CallingNumber like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@CallingNumber) =  1 ) and ( @CallingNumber = '%') ) then ''
		   When ( right(@CallingNumber ,1) = '%' ) then ' and tbl1.CallingNumber like ' + '''' + substring(@CallingNumber,1 , len(@CallingNumber) - 1) + '%' + ''''
		   Else ' and tbl1.CallingNumber like ' + '''' + @CallingNumber + '%' + ''''
	       End


set @Clause3 = 
               Case
		   When (@CalledNumber is NULL) then ''
		   When (@CalledNumber = '_') then ' and tbl1.CalledNumber like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@CalledNumber) =  1 ) and ( @CalledNumber = '%') ) then ''
		   When ( right(@CalledNumber ,1) = '%' ) then ' and tbl1.CalledNumber like ' + '''' + substring(@CalledNumber,1 , len(@CalledNumber) - 1) + '%' + ''''
		   Else ' and tbl1.CalledNumber like ' + '''' + @CalledNumber + '%' + ''''
	       End


----------------------------------------

-- Logic to Compare between the OAMs

-----------------------------------------


DECLARE @ParmDefinition NVARCHAR(500)
SET @ParmDefinition = N'@OAM_A_OUT INT OUTPUT'

--- EXECUTE sp_executesql @SQLCompare, @ParmDefinition, @OAM_A_OUT=@OAM_A OUTPUT 

set @SQLCompare = 'select @OAM_A_OUT = ISNULL(sum(RecordsCount),0)' +
  'from tb_LogEntries tbl1'+  ' where 1 = 1 '

set @SQLCompare = @SQLCompare + @Clause1 + @Clause2 + @Clause3

set @SQLCompare = @SQLCompare + ' and ServerName = ''' + 'OAM_A''' 


print @SQLCompare
--EXEC sp_executesql  @SQLCompare
EXECUTE sp_executesql @SQLCompare, @ParmDefinition, @OAM_A_OUT=@OAM_A OUTPUT

print @OAM_A

SET @ParmDefinition = N'@OAM_B_OUT INT OUTPUT'

set @SQLCompare = 'select @OAM_B_OUT = ISNULL(sum(RecordsCount),0)' +
  'from tb_LogEntries tbl1'+   ' where 1 = 1 '

set @SQLCompare = @SQLCompare + @Clause1 + @Clause2 + @Clause3

set @SQLCompare = @SQLCompare + ' and ServerName = ''' + 'OAM_B''' 

print @SQLCompare
--EXEC sp_executesql  @SQLCompare
EXECUTE sp_executesql @SQLCompare, @ParmDefinition, @OAM_B_OUT=@OAM_B OUTPUT

print @OAM_B




IF @OAM_A >= @OAM_B
BEGIN
set @ServerName = 'OAM_A'
set @rowCount = @OAM_A 
END

ELSE
BEGIN
set @ServerName = 'OAM_B'
set @rowCount = @OAM_B
END




-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2 + @Clause3

-- Adding the Servername clause

set @SQLStr = @SQLStr + ' and ServerName = ''' + @ServerName + '''' 
--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------



set @SQLStr = @SQLStr  + ' order by tbl1.logDate' 

print @SQLStr

create table #MyTable (
    logdate varchar(500),
	logfilename varchar(500) 
)


INSERT INTO #MyTable EXEC sp_executesql  @SQLStr  



--set @rowCount = convert(int,(select sum(Record) from #MyTable))


IF (@rowCount > 0)

BEGIN 
	set @countVal = 0

	--set @path = 'C:\New\ParsedFiles\20190202\'
	SET @first = 1

	DECLARE db_cursor CURSOR FOR 

	SELECT * from #MyTable

	OPEN db_cursor  

	FETCH NEXT FROM db_cursor INTO @logDate, @name  

	SELECT @@CURSOR_ROWS

	WHILE @@FETCH_STATUS = 0  

	BEGIN  

		set @countVal = @countVal + 1
			if @first = 1
			begin
			--select  @name + '.txt'
			set @cmd = 'copy ' + @ParsedPath +  '\' + @logDate + '\' + @ServerName + '\' + @name + '.txt ' + @Extractpath +  '\' +  @finalFile + ' /B /Y' 
			--select @cmd
			exec master..xp_cmdshell @cmd,no_output
			--select @name
			set @first = 0
			end
			else
			--select  @name + '.txt'
			set @cmd = 'copy ' +  @Extractpath +  '\' + @finalFile + ' + ' + @ParsedPath +  '\' + @logDate + '\' + @ServerName + '\' + @name + '.txt ' + @Extractpath +  '\' + @finalFile +   ' /B /Y' 
			--select @cmd
			exec master..xp_cmdshell @cmd,no_output

	FETCH NEXT FROM db_cursor INTO @logDate,@name
	END


	CLOSE db_cursor  



	DEALLOCATE db_cursor

	--set @endtime = convert(varchar, getdate(), 120)


	--set @Remarks = 'Total Number of Records '+ CAST(@rowCount AS VARCHAR)

	set @MasterlogExtractFileName = @finalFile
	set @Remarks = @rowCount
	set @RowsCount = convert(int,@rowCount)
	/*
	INSERT INTO dbo.tb_MasterlogExtract VALUES(
						@MasterlogExtractName,
						@ExtractDescription,
						@finalFile,
						@CallID,
						@CallingNumber,
						@CalledNumber,
						@starttime,
						@endtime,
						1,
						@Remarks,
						@UserID)
	*/
	set @ResultFlag = 0
	GOTO ENDPROCESS
END
ELSE 

	Begin

		set @ErrorDescription = 'Error !!! MasterLog Extract Export file with No Records'
		set @ResultFlag = 1
		set @RowsCount = 0
		GOTO ENDPROCESS

	End 



ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#MyTable') )
		Drop table #MyTable

return 0


/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogExtracMain]    Script Date: 03-05-2019 17:07:08 ******/
SET ANSI_NULLS ON
GO
