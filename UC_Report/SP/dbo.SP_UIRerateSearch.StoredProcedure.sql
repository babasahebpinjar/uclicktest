USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRerateSearch]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRerateSearch]
(
	@UserID int,
	@RerateName varchar(500),
	@RerateStatusID int	,
	@BeginDate datetime,
	@EndDate datetime,
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
-- Check what Rerate Job status has been selected 
--------------------------------------------------

if  ( ( isnull(@RerateStatusID, 0) <> 0 ) and not exists (select 1 from tb_RerateStatus where RerateStatusID = @RerateStatusID ))
Begin

		set @ErrorDescription = 'ERROR !!!!! Rerate Status passed as parameter to Search is not valid'
		set @ResultFlag = 1
		Return 1

End

if ( isnull(@RerateStatusID, 0) = 0 ) -- All status
	set @RerateStatusID = NULL

if ( isnull(@UserID, 0) = 0 ) -- All Users
	set @UserID = NULL


---------------------------------------------------
-- Optimize the Rerate Job Name Regular Expression
---------------------------------------------------

set @RerateName = rtrim(ltrim(@RerateName))

if (( @RerateName is not Null ) and ( len(@RerateName) = 0 ) )
	set @RerateName = NULL

if ( ( @RerateName <> '_') and charindex('_' , @RerateName) <> -1 )
Begin

	set @RerateName = replace(@RerateName , '_' , '[_]')

End


----------------------------------------------------------------
-- Check to ensure that Begin Date is smaller than End Date
----------------------------------------------------------------

if (@BeginDate > @EndDate)
Begin

		set @ErrorDescription = 'ERROR !!!!! Begin Date cannot be greater than the EndDate'
		set @ResultFlag = 1
		Return 1

End

Begin Try

		----------------------------------------------------
		-- Build the dynamic SQL to display the result set
		----------------------------------------------------

		set @SQLStr = 
			 ' Select RerateID , RerateName , RerateRequestDate ' + char(10) +
			 ' From tb_Rerate ' + char(10) +
			 ' Where convert(date , RerateRequestDate) between ''' + convert(varchar(10) , @BeginDate , 120) + ''' and ''' + convert(varchar(10) , @EndDate , 120) + '''' + char(10)+
			 Case
					When @RerateStatusID is not NULL then ' and RerateStatusID = ' + convert(varchar(10) , @RerateStatusID) + char(10)
					Else ''
			 End + char(10) +
			 Case
					When @UserID is not NULL then ' and UserID = ' + convert(varchar(10) , @UserID) + char(10)
					Else ''
			 End

		set @Clause1 = 
				   Case
					   When (@RerateName is NULL) then ''
					   When (@RerateName = '_') then ' and RerateName like '  + '''' + '%' + '[_]' + '%' + ''''
					   When ( ( Len(@RerateName) =  1 ) and ( @RerateName = '%') ) then ''
					   When ( right(@RerateName ,1) = '%' ) then ' and RerateName like ' + '''' + substring(@RerateName,1 , len(@RerateName) - 1) + '%' + ''''
					   Else ' and RerateName like ' + '''' + @RerateName + '%' + ''''
				   End

		set @SQLStr  = @SQLStr + @Clause1 + char(10) + 'Order by RerateRequestDate'

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!!! Searching for Rerate job(s). ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch

Return 0
GO
