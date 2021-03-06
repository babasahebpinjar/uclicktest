USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetOfferTemplateList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetOfferTemplateList]
(
    @OfferTemplateName varchar(100) = NULL
)
--With Encryption
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select OfferTemplateID , OfferTemplateName from vw_OfferTemplate '


--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------


set @Clause1 = 
               Case
		   When (@OfferTemplateName is NULL) then ''
		   When ( ( Len(@OfferTemplateName) =  1 ) and ( @OfferTemplateName = '%') ) then ''
		   When ( right(@OfferTemplateName ,1) = '%' ) then ' Where OfferTemplateName like ' + '''' + substring(@OfferTemplateName,1 , len(@OfferTemplateName) - 1) + '%' + ''''
		   Else ' Where OfferTemplateName like ' + '''' + @OfferTemplateName + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by OfferTemplateName' 

Exec (@SQLStr)

Return



GO
