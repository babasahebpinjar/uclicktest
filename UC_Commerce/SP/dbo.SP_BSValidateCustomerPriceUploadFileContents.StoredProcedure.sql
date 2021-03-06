USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSValidateCustomerPriceUploadFileContents]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSValidateCustomerPriceUploadFileContents]
As


-------------------------------------------------------------------------------------
-- Check if the destination exist in reference plan for the mentioned effective date
-------------------------------------------------------------------------------------

update tbl1
set Remarks = 'Destination : ' + tbl1.Destination + ' does not exist in Inbound Reference Numbering Plan for effective date : ' + 
              convert(varchar(10) , tbl1.EffectiveDate , 120)
from #tempCustomerPriceUploadData tbl1
left join UC_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination
where tbl2.NumberPlanID = -2
and tbl1.EffectiveDate between tbl2.BeginDate and ISNULL(tbl2.EndDate , tbl1.EffectiveDate)
and tbl1.Remarks is NULL
and tbl2.DestinationID is NULL


-----------------------------------------------------------
-- Check to see that the rating methods exist in the system
-----------------------------------------------------------

update tbl1
set Remarks = 'Rating method : ' + tbl1.RatingMethod + ' defined for the rate records does not exist in the system'
from #tempCustomerPriceUploadData tbl1
left join UC_Reference.dbo.tb_RatingMethod tbl2 on  tbl1.RatingMethod = tbl2.RatingMethod
where tbl1.Remarks is NULL
and  tbl2.RatingMethodID is NULL


-------------------------------------------------------------------------------
-- Check to see for duplicate rate records per destination and Effective date
-------------------------------------------------------------------------------

update tbl1
set remarks = 'Multiple rate entries exist for Destination : ' + tbl1.Destination + ' and  Begin Date : ' + 
              convert(varchar(10) , tbl1.EffectiveDate , 120)
from  #tempCustomerPriceUploadData tbl1
inner join
(
	select count(*) as TOTAL_RECORDS ,  Destination , EffectiveDate 
    from #tempCustomerPriceUploadData
	group by  Destination , EffectiveDate 
    having count(1) > 1
) tbl2 on
  tbl1.Destination = tbl2.Destination
  and
  tbl1.EffectiveDate = tbl2.EffectiveDate
  and
  tbl1.Remarks is NULL

GO
