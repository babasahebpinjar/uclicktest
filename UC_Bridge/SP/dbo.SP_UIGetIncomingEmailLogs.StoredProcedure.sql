USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetIncomingEmailLogs]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetIncomingEmailLogs]
(
     @StartDate Date,
     @EndDate Date,
     @StatusID int,
     @FromAddress varchar(300) = NULL,
     @OrderBy int = NULL,
     @SortOrder int = NULL
 )
 --With Encryption
 As


 Declare @SQLStr varchar(2000),
         @Clause1 varchar(1000),
	 @Clause2 varchar(1000),
	 @Clause3 varchar(1000)


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


set @SQLStr = 
		 'select tbl1.FromAddress , tbl1.CC , tbl1.BCC , tbl1.Subject , tbl1.DateReceived , tbl2.Description ' +
		 ' from tblMailMaster tbl1 ' + 
		 ' inner join tblStatusMaster tbl2 on tbl1.statusid = tbl2.ID ' +
		 ' where convert(date , tbl1.DateReceived) between ' + '''' + convert(varchar(20), @StartDate) + '''' + ' and ' + '''' + convert(varchar(20), @EndDate) + '''' +
		 ' and tbl1.statusid = 
				    case 
				       when ' + convert(varchar(10) , @StatusID ) + ' = 0 then tbl1.statusid ' +
				       ' Else ' + convert(varchar(10) , @StatusID ) +
				    ' End '




set @Clause1 = 
               Case
		   When (@FromAddress is NULL) then ''
		   When ( ( Len(@FromAddress) =  1 ) and ( @FromAddress = '%') ) then ''
		   When ( right(@FromAddress ,1) = '%' ) then ' and tbl1.FromAddress like ' + '''' + substring(@FromAddress,1 , len(@FromAddress) - 1) + '%' + ''''
		   Else ' and tbl1.FromAddress like ' + '''' + @FromAddress + '%' + ''''
	       End


 set @Clause2 =
          Case
	      when @OrderBy > 0 then ' order by ' + convert(varchar(10) , @OrderBy)
	      Else ' order by DateReceived'
          End


 set @Clause3 =
          Case
	      when @SortOrder = 1 then ' desc'
	      Else ' asc'
          End


set @SQLStr = @SQLStr + @Clause1 + @Clause2 + @Clause3

Exec (@SQLStr)
GO
