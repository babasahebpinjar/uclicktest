USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetOutgoingEmailLogs]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetOutgoingEmailLogs]
(
     @StartDate Date,
     @EndDate Date,
     @Status varchar(50),
     @ValidateType varchar(50),
     @ToAddress varchar(300) = NULL,
     @OrderBy int = NULL,
     @SortOrder int = NULL
 )
 --With Encryption
 As

 Declare @SQLStr varchar(2000),
         @Clause1 varchar(1000),
	 @Clause2 varchar(1000),
         @Clause3 varchar(1000),
	 @Clause4 varchar(1000)


 set @OrderBy = 
		Case
			When @OrderBy is Null then 0
			When @OrderBy > 6 then 0
			When @OrderBy < 0 then 0
			Else @OrderBy
		End


 set @SortOrder = 
		Case
			When @SortOrder is Null then 0
			When @SortOrder not in (0,1) then 0
			Else @SortOrder
		End


if ( @Status = 'Sent Emails')
Begin

         set @SQLStr = 'select ValidateType, ToAddress , CC ,BCC , Subject , SentDate ' +
			' from HistoryMailSender ' +
			' where convert(date, sentdate) between ' + '''' + convert(varchar(20), @StartDate) + '''' + ' and ' + '''' + convert(varchar(20), @EndDate) + ''''

 
 End

if ( @Status = 'Pending Emails')
Begin

         set @SQLStr = 'select ValidateType, ToAddress , CC ,BCC , Subject , SentDate ' +
			' from tblmailSender ' +
			' where convert(date, sentdate) between ' + '''' + convert(varchar(20), @StartDate) + '''' + ' and ' + '''' + convert(varchar(20), @EndDate) + ''''
	 
 
 End


set @Clause1 = ''

if ( @ValidateType <> 'All')
Begin

set @Clause1 = ' and ValidateType = '''+ @ValidateType  + ''''


End


set @Clause2 = 
               Case
		   When (@ToAddress  is NULL) then ''
		   When ( ( Len(@ToAddress ) =  1 ) and ( @ToAddress = '%') ) then ''
		   When ( right(@ToAddress  ,1) = '%' ) then ' and ToAddress like ' + '''' + substring(@ToAddress,1 , len(@ToAddress) - 1) + '%' + ''''
		   Else ' and ToAddress like ' + '''' + @ToAddress + '%' + ''''
	       End



 set @Clause3 =
          Case
	      when @OrderBy > 0 then ' order by ' + convert(varchar(10) , @OrderBy)
	      Else ' order by SentDate'
          End

 set @Clause4 =
          Case
	      when @SortOrder = 1 then ' desc'
	      Else ' asc'
          End



set @SQLStr = @SQLStr + @Clause1 + @Clause2 + @Clause3 + @Clause4 

Exec (@SQLStr)
GO
