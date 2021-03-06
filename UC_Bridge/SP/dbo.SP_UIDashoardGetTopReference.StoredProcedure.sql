USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashoardGetTopReference]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashoardGetTopReference]
(
   @StartDate date,
   @EndDate date,
   @TopCntr int= NULL
	
)
--With Encryption
As

Declare @SQLStr varchar(2000)

if ( ( @TopCntr is NULL ) or ( @TopCntr <= 0 ) )
	set @TopCntr = 5 -- Default Value

set @SQLStr = ' select top ' + convert(varchar(20) , @TopCntr) + ' ReferenceNo , Totaloffers '+
	      ' from ( ' +
	      'select count(*) as TotalOffers , tbl2.ReferenceNo '+
	      'from tb_vendorOfferDetails tbl1 '+
	      'inner join tb_VendorReferenceDetails tbl2 on tbl1.ReferenceID = tbl2.ReferenceID '+
	      'where convert(date , tbl1.OfferReceiveDate ) between '''+ convert(varchar(30) , @StartDate) + ''' and ''' + convert(varchar(30) , @EndDate) + ''' '+
	      'Group by  tbl2.ReferenceNo '+
	      ' ) as TempOffers' +
	      ' order by TotalOffers Desc '


--print @SQLStr

Exec (@SQLStr)      





GO
