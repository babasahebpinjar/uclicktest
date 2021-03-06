USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRExtractSearch]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICDRExtractSearch]
(
	@UserID int,
	@CDRExtractName varchar(500),
	@CDRExtractStatusID int	,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@Clause2 varchar(1000)

set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------
-- Check what CDR Extract status has been selected 
--------------------------------------------------

if  ( ( isnull(@CDRExtractStatusID, 0) <> 0 ) and not exists (select 1 from tb_CDRExtractStatus where CDRExtractStatusID = @CDRExtractStatusID ))
Begin

		set @ErrorDescription = 'ERROR !!!!! CDRExtract Status passed as parameter to Search is not valid'
		set @ResultFlag = 1
		Return 1

End

if ( isnull(@CDRExtractStatusID, 0) = 0 ) -- All status
	set @CDRExtractStatusID = NULL


---------------------------------------------------
-- Optimize the CDR Extract Name Regular Expression
---------------------------------------------------

set @CDRExtractName = rtrim(ltrim(@CDRExtractName))

if (( @CDRExtractName is not Null ) and ( len(@CDRExtractName) = 0 ) )
	set @CDRExtractName = NULL

if ( ( @CDRExtractName <> '_') and charindex('_' , @CDRExtractName) <> -1 )
Begin

	set @CDRExtractName = replace(@CDRExtractName , '_' , '[_]')

End

Begin Try

		----------------------------------------------------
		-- Build the dynamic SQL to display the result set
		----------------------------------------------------

		set @SQLStr = 
			 ' Select CDRExtractID , CDRExtractName , CDRExtractRequestDate ' + char(10) +
			 ' From tb_CDRExtract ' + char(10) +
			 ' where UserID = ' + convert(varchar(10) , @UserID) + char(10) +
			 Case
					When @CDRExtractStatusID is not NULL then ' and CDRExtractStatusID = ' + convert(varchar(10) , @CDRExtractStatusID) + char(10)
					Else ''
			 End

		set @Clause1 = 
				   Case
					   When (@CDRExtractName is NULL) then ''
					   When (@CDRExtractName = '_') then ' and CDRExtractName like '  + '''' + '%' + '[_]' + '%' + ''''
					   When ( ( Len(@CDRExtractName) =  1 ) and ( @CDRExtractName = '%') ) then ''
					   When ( right(@CDRExtractName ,1) = '%' ) then ' and CDRExtractName like ' + '''' + substring(@CDRExtractName,1 , len(@CDRExtractName) - 1) + '%' + ''''
					   Else ' and CDRExtractName like ' + '''' + @CDRExtractName + '%' + ''''
				   End

		set @SQLStr  = @SQLStr + @Clause1 + char(10) + 'Order by CDRExtractRequestDate'

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Searching for CDR Extract(s). ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch

Return 0
GO
