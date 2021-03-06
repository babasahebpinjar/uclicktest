USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityNameList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIEntityNameList]
(
 @ListofIDs nvarchar(max),
 @EntityTypeID int, --- Valied values are 1 ( Account) , 2 (Country) , 3 (Destination), 4 (Service Level), 5 (Commercial Trunk), 6 (Technical Trunk)
 @ErrorDescription varchar(2000) Output,
 @ResultFlag int Output
)
As

Declare @EntityType varchar(100)

------------------------------------------------
-- Check to ensure that Entity Type is 1-6 
------------------------------------------------

if ( isnull(@EntityTypeID , -9999) not in (1,2,3,4,5,6) )
Begin

 set @ErrorDescription = 'ERROR !!! Entity ID value is not correct. Valid values range is 1-6'
 set @ResultFlag = 1
 Return 1

End

set @EntityType = 
      Case
   When @EntityTypeID = 1 then 'Account'
   When @EntityTypeID = 2 then 'Country'
   When @EntityTypeID = 3 then 'Destination'
   When @EntityTypeID = 4 then 'ServiceLevel'
   When @EntityTypeID = 5 then 'CommercialTrunk'
   When @EntityTypeID = 6 then 'TechnicalTrunk'
   End

----------------------------------------------------
-- Parse the List of IDs and store them in a temp
-- table
----------------------------------------------------

Declare @EntityIDTable table (EntityID varchar(100) )

insert into @EntityIDTable
select * from FN_ParseValueList ( @ListofIDs )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from @EntityIDTable where ISNUMERIC(EntityID) = 0 )
Begin

 set @ErrorDescription = 'ERROR !!! List of ' + @EntityType + ' IDs passed contain a non numeric value'
 set @ResultFlag = 1
 Return 1

End

----------------------------------------------------
-- Get the result Set from the appropriate entity
----------------------------------------------------

if (@EntityTypeID  = 1 )
Begin

  Select Account as Name
  from tb_Account tbl1
  inner join @EntityIDTable tbl2 on tbl1.AccountID = tbl2.EntityID
  where tbl1.Flag & 32  <> 32
  order by Account

End


if (@EntityTypeID  = 2 )
Begin

  Select Country as Name
  from tb_Country tbl1
  inner join @EntityIDTable tbl2 on tbl1.CountryID = tbl2.EntityID
  where tbl1.Flag & 1  <> 1
  order by Country

End


if (@EntityTypeID  = 3 )
Begin

  Select Destination as Name
  from tb_Destination tbl1
  inner join @EntityIDTable tbl2 on tbl1.DestinationID = tbl2.EntityID
  where tbl1.Flag & 1  <> 1
  order by Destination

End

if (@EntityTypeID  = 4 )
Begin

  Select ServiceLevel as Name
  from tb_ServiceLevel tbl1
  inner join @EntityIDTable tbl2 on tbl1.ServiceLevelID = tbl2.EntityID
  where tbl1.Flag & 1  <> 1
  order by ServiceLevel

End


if (@EntityTypeID  = 5)
Begin

  Select Trunk as Name
  from tb_Trunk tbl1
  inner join @EntityIDTable tbl2 on tbl1.TrunkID = tbl2.EntityID
  where tbl1.Flag & 1  <> 1
  order by Trunk

End


if (@EntityTypeID  = 6)
Begin

  Select Trunk + '/' + tbl3.Switch as Name
  from tb_Trunk tbl1
  inner join @EntityIDTable tbl2 on tbl1.TrunkID = tbl2.EntityID
  inner join tb_Switch tbl3 on tbl1.SwitchID = tbl3.SwitchID
  where tbl1.Flag & 1  <> 1
  order by Trunk

End
GO
