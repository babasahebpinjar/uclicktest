USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedCorrelateSearch]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedCorrelateSearch] 
(
    @FileName varchar(200) = NULL,
	@FileStatus varchar(200) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @FileName is not Null ) and ( len(@FileName) = 0 ) )
	set @FileName = NULL


if ( ( @FileName <> '_') and charindex('_' , @FileName) <> -1 )
Begin

	set @FileName = replace(@FileName , '_' , '[_]')

End

----------------------------------------------------
-- In case File Status is NULL or an empty string
-- then set it to 'All'
----------------------------------------------------

if (( @FileStatus is not Null ) and ( len(@FileStatus) = 0 ) )
	set @FileStatus = 'All'

if ( @FileStatus is NULL )
	set @FileStatus = 'All'

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select CDRFileID ,CDRFileName, TotalRecords, I_TypeRecords ,O_TypeRecords , '+
			  'Z_TypeRecords, DiscardRecords , FileStatus, Remarks '+
              ' From tb_MedCorrelateStatistics tbl1 ' +
		      ' where tbl1.FileStatus = '  +
			  Case
			   When @FileStatus =  'All' then ' tbl1.FileStatus '
			   Else '''' + @FileStatus + ''''
			  End
	      
print @SQLStr	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
				   When (@FileName is NULL) then ''
				   When (@FileName = '_') then ' and tbl1.CDRFileName like '  + '''' + '%' + '[_]' + '%' + ''''
				   When ( ( Len(@FileName) =  1 ) and ( @FileName = '%') ) then ''
				   When ( right(@FileName ,1) = '%' ) then ' and tbl1.CDRFileName like ' + '''' + substring(@FileName,1 , len(@FileName) - 1) + '%' + ''''
				   Else ' and tbl1.CDRFileName like ' + '''' + @FileName + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.CDRFileID Desc' 

print @SQLStr

Exec (@SQLStr)

Return
GO
