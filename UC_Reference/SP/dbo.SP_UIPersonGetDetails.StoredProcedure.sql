USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPersonGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIPersonGetDetails]
(
	@PersonID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


if ( @PersonID is null )
Begin

		set @ErrorDescription = 'ERROR !!! PersonID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_person where personid = @PersonID )
Begin

		set @ErrorDescription = 'ERROR !!! Individual does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------
-- Display the details for the person
--------------------------------------

select  tbl1.PersonID,
		tbl2.PersonTypeID,
        tbl2.PersonType,
		LastName ,
		MI ,
		FirstName ,
		Address1 ,
		Address2 ,
		City ,
		State ,
		Zip ,
		Country ,
		WorkPhone ,
		HomePhone ,
		CellPhone ,
	    Pager ,
		WorkFax ,
		HomeFax ,
		EmailAddress ,
		Salutation ,
		Company ,
	    Title ,
		CreatedDate ,
		UC_Admin.dbo.FN_GetUserName(CreatedByID) as CreatedByUser ,
		tbl1.ModifiedDate,
		UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
from tb_Person tbl1
inner join tb_PersonType tbl2 on tbl1.Persontypeid = tbl2.PersonTypeID
where tbl1.PersonID = @PersonID
and tbl1.flag & 1 <> 1

Return 0
GO
