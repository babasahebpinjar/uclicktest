USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSGetExecutionScript]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSGetExecutionScript]
(
	@RatingMethodID int,
	@RateItemID int,
	@ExecutionExpression varchar(1000) Output
)
As


Declare @UIControlTypeID int,
        @ParamCount int,
		@ExecutionScript varchar(1000),
		@Param varchar(100),
		@RateStructureID int,
		@SQLStr nvarchar(2000)

Declare @Counter int = 0

Select @RateStructureID = RateStructureID
From tb_RatingMethod
where RatingMethodID = @RatingMethodID

Select @UIControlTypeID = UIControlTypeID,
       @ParamCount = ParamCount,
	   @ExecutionScript  = ExecutionScript
From tb_RateItemControlType
where RateItemID = @RateItemID

if  ( isnull(@UIControlTypeID , -1) in (-2, -3 ))
Begin
 
		set @Counter = 1

		set @ExecutionExpression = 'Exec ' + @ExecutionScript
		
		While ( @Counter <= isNULL(@ParamCount, 0) )
		Begin
			 
               set @SQLStr = 'SELECT @Param= Param'+convert(varchar(10) , @Counter)+' FROM tb_RateItemControlType where RateItemID = ' + convert(varchar(20) , @RateItemID)
				EXEC sp_executesql @SQLStr, 
					N'@Param varchar(100) OUTPUT',
					@Param OUTPUT

				set @ExecutionExpression = 
				    Case
							When @Param is NULL then @ExecutionExpression + ' NULL,'
							When @Param = 'RateStructureID' then @ExecutionExpression + ' ' + convert(varchar(20) , @RateStructureID) +  ',' 
							When @Param = 'RateItemID' then @ExecutionExpression  + ' ' +convert(varchar(20) , @RateItemID)  + ',' 
							Else NULL
					End
				
				set @Counter = @Counter + 1	
					     
		End		

End

if (( @ExecutionExpression is not NULL ) and (right(@ExecutionExpression ,1) = ',' ) )
Begin

	Select @ExecutionExpression = substring(@ExecutionExpression, 1 , len(@ExecutionExpression) - 1)

End


  

GO
