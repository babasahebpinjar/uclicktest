USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRExtractDisplayFieldList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICDRExtractDisplayFieldList]
(
    @DisplayFieldName varchar(60) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

set @DisplayFieldName = rtrim(ltrim(@DisplayFieldName))

if (( @DisplayFieldName is not Null ) and ( len(@DisplayFieldName) = 0 ) )
	set @DisplayFieldName = NULL

if ( ( @DisplayFieldName <> '_') and charindex('_' , @DisplayFieldName) <> -1 )
Begin

	set @DisplayFieldName = replace(@DisplayFieldName , '_' , '[_]')

End


----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select CDRExtractMasterReferenceID as ID, FieldName as Name' + char(10) +
              'from tb_CDRExtractMasterReference' + char(10) +
			  'where flag & 1 <> 1 '


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@DisplayFieldName is NULL) then ''
				   When (@DisplayFieldName = '_') then ' and FieldName like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@DisplayFieldName) =  1 ) and ( @DisplayFieldName = '%') ) then ''
				   When ( right(@DisplayFieldName ,1) = '%' ) then ' and FieldName like ' + '''' + substring(@DisplayFieldName,1 , len(@DisplayFieldName) - 1) + '%' + ''''
				   Else ' and FieldName like ' + '''' + @DisplayFieldName + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by FieldName ' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
