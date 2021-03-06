USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICheckFormatFileNameAvailability]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICheckFormatFileNameAvailability]
(
    @FormatFileName varchar(200),
    @ResultFlag int output
)
--With Encryption
As

Declare @ParseConfigDirectory  varchar(500),
		@cmd varchar(2000),
		@SQLStr varchar(3000),
		@Clause1 varchar(2000)

set @ResultFlag = 0
		
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

       GOTO PROCESSEND
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
		GOTO PROCESSEND
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
-- Check if the file name passed in input exists
-- or not
---------------------------------------------------

if exists ( select 1 from #tempCommandoutput where commandoutput = @FormatFileName )
	set @ResultFlag = 1

--------------------------------------------------
-- Drop the temporary table post completion of
-- all the process
--------------------------------------------------

PROCESSEND:

drop table #tempCommandoutput
GO
