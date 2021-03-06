USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectParamGetDetails]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIObjectParamGetDetails]
(
	@ObjectID int
)
As

select prm.ParameterName , pt.ParameterType , op.ObjectParamValue as ParameterValue,
       op.ModifiedDate , usr.Name as ModifiedBy
from tb_ObjectParam op
inner join tb_Object o on op.ObjectID = o.ObjectID
inner join tb_ObjectTypeParam otp on op.ObjectTypeParamID = otp.ObjectTypeParamID
                                  and o.ObjectTypeID = otp.ObjectTypeID
inner join tb_Parameter prm on otp.ParameterID = prm.ParameterID
inner join Tb_ParameterType pt on prm.ParameterTypeID = pt.ParameterTypeID
inner join UC_Admin.dbo.tb_Users usr on op.ModifiedByID = usr.UserID
where op.ObjectID = @ObjectID
order by prm.ParameterName

Return 0
GO
