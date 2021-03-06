USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMasterlogExtractSearch]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIMasterlogExtractSearch] 
(
    @UserID int,
	@ExtractName varchar(500) = NULL,
	@MasterlogExtractStatusID int	,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)

AS


if (( @ExtractName is not Null ) and ( len(@ExtractName) = 0 ) )
Begin
	set @ExtractName = NULL
End


Declare @SQLStr nvarchar(max),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000),
	    @Clause3 varchar(1000)

set @ErrorDescription = NULL
set @ResultFlag = 0

if ( isnull(@MasterlogExtractStatusID, 0) = 0 ) -- All status
	set @MasterlogExtractStatusID = NULL


Begin Try

	set @SQLStr = 'Select tbl1.MasterlogExtractId, tbl1.MasterlogExtractName ' + 
				  'From tb_MasterlogExtract tbl1 ' +
				   ' where UserID = ' + convert(varchar(10) , @UserID) + char(10) +
				Case
					When @MasterlogExtractStatusID is not NULL then ' and MasterlogExtractStatusID = ' + convert(varchar(10) , @MasterlogExtractStatusID) + char(10)
					Else ''
			    End

	set @Clause1 = 
				   Case
			   When (@ExtractName is NULL) then ''
			   When (@ExtractName = '_') then ' and tbl1.MasterlogExtractName like '  + '''' + '%' + '[_]' + '%' + ''''
			   When (( Len(@ExtractName) =  1 ) and ( @ExtractName = '%') ) then ''
			   When (right(@ExtractName ,1) = '%' ) then ' and tbl1.MasterlogExtractName like ' + '''' + substring(@ExtractName,1 , len(@ExtractName) - 1) + '%' + ''''
			   Else ' and tbl1.MasterlogExtractName like ' + '''' + @ExtractName + '%' + ''''
			   End


	set @SQLStr = @SQLStr + @Clause1 

	set @SQLStr = @SQLStr  + ' order by tbl1.MasterlogExtractRequestDate' 


	print @SQLStr

	EXEC(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Searching for Masterlog Extract(s). ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch

Return 0
GO
