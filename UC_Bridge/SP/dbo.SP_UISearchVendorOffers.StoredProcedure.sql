USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UISearchVendorOffers]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UISearchVendorOffers] 
(
    @ReferenceNo varchar(100) = NULL,
    @StatusID int,
    @OfferTypeID int,
    @StartDate date,
    @EndDate date
)
--With Encryption
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

if (( @ReferenceNo is not Null ) and ( len(@ReferenceNo) = 0 ) )
	set @ReferenceNo = NULL

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.ReferenceID , tbl2.ReferenceNo , tbl1.VendorOfferID , tbl1.OfferFileName , tbl1.OfferReceiveDate , tbl1.OfferTypeID , tbl3.code as OfferType ,  tbl1.OfferStatusID ,tbl4.OfferStatus  '+
              ' From tb_vendorofferdetails tbl1 ' +
	      ' inner join tb_vendorReferenceDetails tbl2 on tbl1.ReferenceID = tbl2.ReferenceID ' +
	      ' inner join tbloffertype tbl3 on tbl1.offertypeid = tbl3.ID ' +
	      ' inner join tb_offerstatus tbl4 on tbl1.offerstatusid = tbl4.offerstatusid ' +
	      ' where convert(date , offerreceivedate) between ' + '''' + convert(varchar(20), @StartDate) + '''' + ' and ' + '''' + convert(varchar(20), @EndDate) + '''' 
	      
	      

if ( @OfferTypeID <> 0 )
	set @SQLStr =  @SQLStr + ' and tbl1.offertypeid = ' + convert(varchar(20) , @OfferTypeID)

if ( @StatusID <> 0 )
	set @SQLStr =  @SQLStr + ' and tbl1.offerstatusid = ' + convert(varchar(20) , @StatusID)

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@ReferenceNo is NULL) then ''
		   When ( ( Len(@ReferenceNo) =  1 ) and ( @ReferenceNo = '%') ) then ''
		   When ( right(@ReferenceNo ,1) = '%' ) then ' and tbl2.ReferenceNo like ' + '''' + substring(@ReferenceNo,1 , len(@ReferenceNo) - 1) + '%' + ''''
		   Else ' and tbl2.ReferenceNo like ' + '''' + @ReferenceNo + '%' + ''''
	       End



-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by ReferenceNo, OfferREceiveDate' 

--print @SQLStr

Exec (@SQLStr)

Return
GO
