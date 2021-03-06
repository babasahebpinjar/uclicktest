USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICustomerOfferStatusList]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UICustomerOfferStatusList]
(
	@OfferStatus varchar(100) = NULL
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)


if (( @OfferStatus is not Null ) and ( len(@OfferStatus) = 0 ) )
	set @OfferStatus = NULL


if ( ( @OfferStatus <> '_') and charindex('_' , @OfferStatus) <> -1 )
Begin

	set @OfferStatus = replace(@OfferStatus , '_' , '[_]')

End


----------------------------------------------------------
-- Prepare the dynamic SQL query for the search criteria
----------------------------------------------------------

set @SQLStr = 'Select tbl1.OfferstatusID as ID, tbl1.OfferStatus as Name  ' +
              ' from tb_Offerstatus tbl1 ' +
			  ' where tbl1.OffertypeID = -2 ' -- Customer Offer

-----------------------------------------------------
-- Prepare the extended clause for the search query	
-----------------------------------------------------

set @Clause1 = 
           Case
			   When (@OfferStatus is NULL) then ''
			   When (@OfferStatus = '_') then ' and tbl1.OfferStatus like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@OfferStatus) =  1 ) and ( @OfferStatus = '%') ) then ''
			   When ( right(@OfferStatus ,1) = '%' ) then ' and tbl1.OfferStatus like ' + '''' + substring(@OfferStatus,1 , len(@OfferStatus) - 1) + '%' + ''''
			   Else ' and tbl1.OfferStatus like ' + '''' + @OfferStatus + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1	

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.OfferStatusID' 

--print @SQLStr

Exec (@SQLStr)

Return
	  			  			  			   
GO
