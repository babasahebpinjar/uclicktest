USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountryGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICountryGetDetails]
(
	@CountryID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

if ( @CountryID is null )
Begin

		set @ErrorDescription = 'ERROR !!! CountryID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_Country where CountryID = @CountryID )
Begin

		set @ErrorDescription = 'ERROR !!! Country does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

----------------------------------
-- Display details of the Country
----------------------------------

Select tbl1.CountryID , tbl1.Country , 
       tbl1.CountryAbbrv , tbl1.CountryCode ,
       tbl2.CountryTypeID , tbl2.CountryType , tbl1.ModifiedDate , 
	   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
From tb_country tbl1
inner join tb_countrytype tbl2 on tbl1.countrytypeid = tbl2.countrytypeid
where tbl1.flag & 1 <> 1 
and tbl1.countryid = @CountryID
GO
