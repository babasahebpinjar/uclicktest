USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetFormatFileList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetFormatFileList]
(
    @FormatFileName varchar(200) = NULL
)
--With Encryption
As

Declare @ParseConfigDirectory  varchar(500),
		@cmd varchar(2000),
		@SQLStr varchar(3000),
		@Clause1 varchar(2000)
		
---------------------------------------------
-- Create Temporary Table to hold the data
---------------------------------------------

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)		

Select @ParseConfigDirectory  = ConfigValue
from TB_Config
where Configname = 'ParseConfigDirectory'

if ( @ParseConfigDirectory  is NULL )
Begin

       GOTO DATACLAUSE
End

if ( RIGHT(@ParseConfigDirectory  , 1) <> '\' )
     set @ParseConfigDirectory  = @ParseConfigDirectory  + '\'

set @cmd = 'dir ' + '"' + @ParseConfigDirectory  + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.'
				       )								
          )		
Begin  
		GOTO DATACLAUSE
End

----------------------------------------------
-- Remove NULL records as well as records 
-- which are not names of Format files
----------------------------------------------

delete from #tempCommandoutput
where commandoutput is NULL

delete from #tempCommandoutput
where SUBSTRING( CommandOutput , len(commandoutput) - 3 , 4) <> '.Fmt'

------------------------------------------------------
-- Update the records to only display the name of the 
-- format file and not its extension
------------------------------------------------------

update #tempCommandoutput
set CommandOutput = SUBSTRING(CommandOutput , 1, len(commandoutput) - 4)

---------------------------------------------------
-- Only display records which qualify as per the
-- search criteria
---------------------------------------------------

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

DATACLAUSE:

set @SQLStr = 'Select commandoutput as FormatFileName from #tempCommandoutput '

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------


set @Clause1 = 
           Case
			   When (@FormatFileName is NULL) then ''
			   When ( ( Len(@FormatFileName) =  1 ) and ( @FormatFileName = '%') ) then ''
			   When ( right(@FormatFileName ,1) = '%' ) then ' where commandoutput like ' + '''' + substring(@FormatFileName,1 , len(@FormatFileName) - 1) + '%' + ''''
			   Else ' where commandoutput like ' + '''' + @FormatFileName + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by 1' 

Exec (@SQLStr)

--------------------------------------------------
-- Drop the temporary table post completion of
-- all the process
--------------------------------------------------

drop table #tempCommandoutput
GO
