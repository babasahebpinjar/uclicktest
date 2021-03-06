USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardDataOfferType]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashboardDataOfferType]
(
   @StartDate date,
   @EndDate date,
   @TopCntr int = NULL
)
--With Encryption
As

Declare @SQLStr varchar(2000)

if ( ( @TopCntr is NULL ) or ( @TopCntr <= 0 ) )
	set @TopCntr = 5 -- Default Value

set @SQLStr = 
'select convert(date, OfferReceiveDate) as OfferDate , tbl2.Code as OfferType , Count(*) as TotalOffers '+
'from tb_vendorOfferDetails tbl1 '+
'inner join tbloffertype tbl2 on tbl1.OfferTypeID = tbl2.id '+
'where convert(date, OfferReceiveDate) in '+
'( '+
'	select top ' + convert(varchar(10) , @TopCntr) + ' OfferDate '+
'	from '+
'	( '+
'			select distinct convert(date, OfferReceiveDate) as OfferDate , count(*) as TotalOffers '+
'			from tb_vendorOfferDetails '+ 
'			where convert(date, OfferReceiveDate) between '''+ convert(varchar(30), @StartDate) +''' and ''' + convert(varchar(30) , @EndDate) + ''' '+ 
'           group by convert(date, OfferReceiveDate) ' +
'	) as tbl2 '+
'	order by TotalOffers desc '+
') '+
'group by convert(date, OfferReceiveDate) , tbl2.Code '+
'Order by 1, 2 '

--print (@SQLStr)

Exec (@SQLStr)
GO
