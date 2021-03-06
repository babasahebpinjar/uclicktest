USE [UC_Facilitate]
GO
/****** Object:  User [uclickfacilitate]    Script Date: 5/2/2020 6:48:55 PM ******/
CREATE USER [uclickfacilitate] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_securityadmin] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_datareader] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_denydatareader] ADD MEMBER [uclickfacilitate]
GO
ALTER ROLE [db_denydatawriter] ADD MEMBER [uclickfacilitate]
GO
