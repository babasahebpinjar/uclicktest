USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[DashBoardIncomingMails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[DashBoardIncomingMails]     

(    

@BeginDate smalldatetime,    
@EndDate smalldatetime    

)    

AS    

   

Declare @AllRelevantStats table    

(    

    StatsType varchar(30),    
    StatusDescription varchar(100),    
    TotalRecords int,    
    TotalPercent decimal(19,2)    

)    

    

-----------------------------------------    

-- Insert dummy records into the tables    

-- for relevant status    

-----------------------------------------    

    

------------------------------------    

-- All Received Emails    

-- 1. Under Process    

-- 2. Processed    

-- 3. Rejected    

-- 4. Delivery Failure    

-- 5. Out of office    

------------------------------------    

    

insert into @AllRelevantStats    

select 'Email' ,description , 0 , 0    
from tblStatusMaster    
where ID in (1,2,3,4,5)    

    

    

-----------------------------------    

-- All Documents    

-- 1. Under Process    

-- 2. Delivery Successful    

-- 3. Partial Processed    

-- 4. Rejected    

-----------------------------------    

    

insert into @AllRelevantStats    
select 'Documents' ,description , 0 , 0    
from tblStatusMaster    
where ID in (1,8,9,10)    

    

    

---------------------------------------------------------    

-- Extract Records from the tblMailMaster for all the    

-- emails received by the system    

---------------------------------------------------------    

    

select tbl1.ID , tbl1.CreatedDate , tbl1.statusid , tbl2.Description as StatusDescription    
into #TempAllReceivedEmails    
from tblMailMaster tbl1    
inner join tblStatusMaster tbl2 on tbl1.StatusID = tbl2.ID    
where convert(date  ,tbl1.CreatedDate ) between @BeginDate and @EndDate    

   

-----------------------------------------------------    

-- For all the processed emails extract information    
-- regarding offer upload from tblDocuments    

-----------------------------------------------------    

    

select tbl3.Description as StatusDescription , COUNT(*) as TotalRecords    
into #TempAllDocuments    
from tbldocuments tbl1    
inner join #TempAllReceivedEmails tbl2 on tbl1.EmailID = tbl2.ID    
inner join tblStatusMaster tbl3 on tbl1.StatusID = tbl3.ID    
where tbl2.statusid = 2    
Group by tbl3.Description     

    

    

Declare @TotalDocuments int,    
        @TotalMails int    

    

    

select @TotalDocuments = count(*)    
from tbldocuments tbl1    
inner join #TempAllReceivedEmails tbl2 on tbl1.EmailID = tbl2.ID    
inner join tblStatusMaster tbl3 on tbl1.StatusID = tbl3.ID    
where tbl2.statusid = 2    

    

select @TotalMails = count(*)    
from #TempAllReceivedEmails    

    

----------------------------------------------------------    

-- Update the Result Sets with the appropriate statistics    

----------------------------------------------------------    

    

update tbl1    
set tbl1.TotalRecords = tbl2.TotalRecords,    
    tbl1.TotalPercent = (tbl2.TotalRecords * 100)/(@TotalMails * 1.0)    
from @AllRelevantStats tbl1    
inner join    
(    
 select StatusDescription , COUNT(*) as TotalRecords    
 from #TempAllReceivedEmails    
 group by StatusDescription    
) tbl2 on tbl1.StatusDescription = tbl2.StatusDescription    
where tbl1.statstype = 'Email'    

    

update tbl1    
set tbl1.TotalRecords = tbl2.TotalRecords,    
    tbl1.TotalPercent = (tbl2.TotalRecords *100)/(@TotalDocuments * 1.0)    
from @AllRelevantStats tbl1    
inner join #TempAllDocuments tbl2 on tbl1.StatusDescription = tbl2.StatusDescription     
where tbl1.statstype = 'Documents'    
   

----------------------------    
-- Drop all Temp Tables    
----------------------------    

Drop table #TempAllReceivedEmails    
Drop table #TempAllDocuments    
    

select *    
from @AllRelevantStats where statsType = 'Email'    
order by StatusDescription    

    
Return
GO
