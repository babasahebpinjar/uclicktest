USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepaidMartRefreshInitiateWrapper]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_BSPrepaidMartRefreshInitiateWrapper]
(
    @LoadBalanceOffset int,
	@RangeValue int
)
As

Declare   @ErrorDescription varchar(2000) ,
	      @ResultFlag int 

set @ErrorDescription = NULL
set @ResultFlag = 0

Begin Try

		Exec REFERENCESERVER.UC_Operations.dbo.SP_BSPrepaidMartRefreshInitiate @LoadBalanceOffset , @RangeValue , 
		                                                                 -1, -- Default USER ID
		                                                                 @ErrorDescription Output,
																		 @ResultFlag Output

        if (@ResultFlag = 1)
		Begin

				set @ErrorDescription = 'ERROR !!! During Pepaid Traffic Mart Refresh. ' + @ErrorDescription
				set @ResultFlag = 1
				RaisError('%s' , 1,16 , @ErrorDescription)
				Return 1

		End
		 
End Try

Begin Catch

				set @ErrorDescription = 'ERROR !!! During Pepaid Traffic Mart Refresh. ' + ERROR_MESSAGE()
				set @ResultFlag = 1
				RaisError('%s' , 1,16 , @ErrorDescription)
				Return 1

End Catch

Return 0

GO
