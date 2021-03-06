USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCorrelatePublishExceptionRecords]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[SP_BSMedCorrelatePublishExceptionRecords]
(
	@AbsoluteLogFilePath varchar(1000)
)

As

Declare @VarCDRFileName varchar(200),
        @VarBERID int,
		@ErrorDescription varchar(2000)

DECLARE db_populate_Exception_Rec CURSOR FOR 
select tbl2.CDRFileName , tbl1.O_BERID as BERID
from
(
	select count(*) as TotalRecords , O_CDRFileID , O_BERID 
	from #temp_MedCorrelateMapBER
	group by O_CDRFileID , O_BERID
	having count(1) > 1
) tbl1
inner join tb_MedCorrelateStatistics tbl2 on tbl1.O_CDRFileID = tbl2.CDRFileID


OPEN db_populate_Exception_Rec   
FETCH NEXT FROM db_populate_Exception_Rec
INTO @VarCDRFileName  , @VarBERID 

WHILE @@FETCH_STATUS = 0   
BEGIN 

       set @ErrorDescription = '	CDR File Name : ' + @VarCDRFileName + ' Record ID : ' + convert(int , @VarBERID)
	   Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	   FETCH NEXT FROM db_populate_Exception_Rec
	   INTO @VarCDRFileName  , @VarBERID 
 
END   

CLOSE db_populate_Exception_Rec  
DEALLOCATE db_populate_Exception_Rec

 
GO
