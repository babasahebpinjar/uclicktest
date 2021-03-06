USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferSearch]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorOfferSearch]
( 
    @AccountID int,
	@SourceID int,
	@OfferStatusID int,
	@OfferStartDate datetime,
	@OfferEndDate datetime,
	@OfferContent varchar(50)
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


-------------------------------------------------------------------------
-- Set AccountID / SourceID / Offer StatusID to NULL in case value is 0
-------------------------------------------------------------------------

if ( @AccountID = 0 )
	set @AccountID = NULL

if ( @SourceID = 0 )
	set @SourceID = NULL

if ( @OfferStatusID = 0 )
	set @OfferStatusID = NULL

if ( @OfferContent = 'All' )
	set @OfferContent = NULL

----------------------------------------------------------
-- Prepare the dynamic SQL query for the search criteria
----------------------------------------------------------

set @SQLStr  = ' select tbl1.OfferID , tbl1.OfferFileName , tbl1.offerDate , tbl1.OfferContent ,tbl2.SourceID , tbl2.Source ' +
			   ' from tb_offer tbl1 '+
			   ' inner join tb_Source tbl2 on tbl1.SourceID = tbl2.SourceID ' +
			   ' where tbl1.offertypeID = -1 ' +
			   ' and convert(date ,tbl1.OfferDate) between ''' + convert(varchar(30) , @OfferStartDate ) + '''' + 
			   ' and ''' + convert(varchar(30) , @OfferEndDate ) + '''' + 
			  Case 
				When @SourceID is NULL then ''
				Else ' and tbl1.SourceID = '  + convert(varchar(20) , @SourceID)
			  End + 
			  Case 
				When @AccountID is NULL then ''
				Else ' and tbl2.ExternalCode = '  + convert(varchar(20) , @AccountID)
			  End + 
			  Case 
				When @OfferStatusID is NULL then ''
				Else ' and dbo.FN_GetVendorOfferCurrentStatus(tbl1.OfferID) = '  + convert(varchar(20) , @OfferStatusID)
			  End +
			  Case 
				When @OfferContent is NULL then ''
				Else ' and tbl1.OfferContent = '''  + @OfferContent + ''''
			  End

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl2.Source asc , tbl1.OfferDate desc' 

print @SQLStr

Exec (@SQLStr)

Return
	  			  			  			   
GO
