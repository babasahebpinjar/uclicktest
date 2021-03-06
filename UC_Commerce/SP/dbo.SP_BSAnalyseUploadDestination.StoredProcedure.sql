USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAnalyseUploadDestination]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSAnalyseUploadDestination]
(
	@NumberplanID int,
	@UserID int
)
as

---------------------------------
-- Mark all the new destinations
---------------------------------

update tbl1
set tbl1.Flag = 64
from #TempUploadDestination tbl1
left join uc_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.NumberPlanID = @NumberPlanID
where tbl2.Destination is NUll

-------------------------------------------------------------------------
-- Update the DESTINATIONID in the upload table for all the destinations
-- which exist in the reference
-------------------------------------------------------------------------

update tbl1
set tbl1.DestinationID = tbl2.DestinationID
from #TempUploadDestination tbl1
left join uc_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination
where tbl2.NumberPlanID = @NumberPlanID
and (
		tbl1.Effectivedate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.EffectiveDate)
		or
		tbl2.BeginDate > tbl1.EffectiveDate -- Destination exists in reference but has a begin date in future as compared to Effective date in offer
	)
and tbl2.Destination is not NULL
and tbl2.Flag & 1 <> 1

------------------------------------------------------------------------------------
-- Update the Reference center destination begin date to Effective date in offer
-- for all the destinations which have future begin date
------------------------------------------------------------------------------------

update tbl2
set tbl2.Begindate = tbl1.EffectiveDate
from #TempUploadDestination tbl1
left join uc_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination
where tbl2.NumberPlanID = @NumberPlanID
and tbl2.BeginDate > tbl1.EffectiveDate -- Destination exists in reference but has a begin date in future as compared to Effective date in offer
and tbl2.Destination is not NULL
and tbl2.Flag & 1 <> 1

---------------------------------------------------
-- Create a temporary table to hold data for new
-- destinations, that will be created in the system
----------------------------------------------------

CREATE TABLE #TempNewDestinations
(
	[Destination] [varchar](60) NOT NULL,
	[DestinationAbbrv] [varchar](20) NOT NULL,
	[DestinationTypeID] [int] NOT NULL,
	[InternalCode] [varchar](10) NULL,
	[ExternalCode] [varchar](10) NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[NumberPlanID] [int] NOT NULL,
	[CountryID] [int] NOT NULL
)

---------------------------------------------------------------
-- Store all distinct combinations of upload destination and
-- country codes in a temporary table
---------------------------------------------------------------

select distinct tbl1.Destination , tbl2.CountryCode 
into #TempDestinationCountryCode
from #TempUploadDestination tbl1
inner join #TempUploadBreakout tbl2 on tbl1.UploadDestinationID = tbl2.UploadDestinationID

---------------------------------------------------
-- Create a temporary table for all the country
-- codes and IDs
---------------------------------------------------

create table #TempAllCountryCode ( CountryId int,CountryCode varchar(20) )

Declare @VarCountryCode varchar(20),
        @VarCountryID int,
		@TempCountryCodeStr varchar(100)

Declare GetAllCountryCode_Cur Cursor For
select CountryID ,countrycode
from UC_Reference.dbo.tb_country
where countryid > 0 and flag <> 1

Open GetAllCountryCode_Cur
Fetch Next From GetAllCountryCode_Cur
Into @VarCountryID , @VarCountryCode


While @@FETCH_STATUS = 0
Begin

    set @TempCountryCodeStr = @VarCountryCode

	while ( charindex(',' , @VarCountryCode ) <> 0 )
	Begin

            set @TempCountryCodeStr = substring(@VarCountryCode , 1 , charindex(',' , @VarCountryCode ) - 1 )
			insert into #TempAllCountryCode values ( @TempCountryCodeStr )
            set @VarCountryCode = substring(@VarCountryCode , charindex(',' , @VarCountryCode ) + 1 , Len(@VarCountryCode) )
	End

	insert into #TempAllCountryCode values ( @VarCountryID , @VarCountryCode )
 
	Fetch Next From GetAllCountryCode_Cur
	Into @VarCountryID ,@VarCountryCode

End

Close GetAllCountryCode_Cur
Deallocate GetAllCountryCode_Cur

------------------------------------------------------
-- Populate the appropriate Country Code for each
-- Destination being created in the system
-------------------------------------------------------

Declare @VarDestination varchar(60),
        @VarEffectiveDate date ,
		@VarResolvedCountryID int             


Declare Cur_CreateNewDestination Cursor For
select destination , min(EffectiveDate) as MinEffectiveDate
from #TempUploadDestination
where flag & 64 = 64
group by destination

OPEN Cur_CreateNewDestination   
FETCH NEXT FROM Cur_CreateNewDestination
INTO @VarDestination  , @VarEffectiveDate 

WHILE @@FETCH_STATUS = 0   
BEGIN 

       ------------------------------------------------------------
	   -- Scenario 1 : Destination contain dial codes for multiple
	   -- Countries
	   -----------------------------------------------------------

	   if ( ( select count(distinct CountryCode) from #TempDestinationCountryCode where Destination = @VarDestination )  > 1 ) 
	   Begin

				-------------------------------------------------------------------------------
				-- Scenario 1.1 : Case where all the country codes belong to the same country
				-- ( Example Dominican Republic , Puerto Rico etc)
				-------------------------------------------------------------------------------

				-------------------------------------------------------------------------------
				-- Scenario 1.2 : Case where all the country codes belong to different countries
				-------------------------------------------------------------------------------


				select @VarResolvedCountryID = min(tbl1.CountryID) 
				from #TempAllCountryCode tbl1 
				inner join #TempDestinationCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode
				where tbl2.Destination = @VarDestination



	   End

       -----------------------------------------------------------------------------------
	   -- Scenario 2 : Destination contains single country code for all dialed digits
	   -----------------------------------------------------------------------------------

	   if ( ( select count(distinct CountryCode) from #TempDestinationCountryCode where Destination = @VarDestination )  = 1 ) 
	   Begin

				-------------------------------------------------------------------------------
				-- Scenario 2.1 : Case where single country code is being shared by multiple
				-- countries . Example (Russia and Kazakhistan)
				-------------------------------------------------------------------------------

				if ( 
						(
							select count(distinct tbl1.CountryID) 
							from #TempAllCountryCode tbl1 
							inner join #TempDestinationCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode
							where tbl2.Destination = @VarDestination
						) > 1
				   )
				Begin

						if ( 
								(
									select count(distinct tbl1.CountryID) 
									from #TempAllCountryCode tbl1 
									inner join #TempDestinationCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode
									inner join uc_reference.dbo.tb_Country tbl3 on tbl1.CountryID = tbl3.CountryID
									where tbl2.Destination = @VarDestination
									and charindex(tbl3.Country , tbl2.Destination) <> 0
								) = 1
						   )
						   Begin

									select @VarResolvedCountryID = tbl1.CountryID
									from #TempAllCountryCode tbl1 
									inner join #TempDestinationCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode
									inner join uc_reference.dbo.tb_Country tbl3 on tbl1.CountryID = tbl3.CountryID
									where tbl2.Destination = @VarDestination
									and charindex(tbl3.Country , tbl2.Destination) <> 0

						   End

						   Else
						   Begin
				
									select @VarResolvedCountryID = min(tbl1.CountryID) 
									from #TempAllCountryCode tbl1 
									inner join #TempDestinationCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode
									where tbl2.Destination = @VarDestination

						    End
							

				End

				-------------------------------------------------------------------------------
				-- Scenario 2.2 : Normal case where all single country code associated to single
				-- country ID
				-------------------------------------------------------------------------------

				Else
				Begin
				
						select @VarResolvedCountryID = tbl1.CountryID
						from #TempAllCountryCode tbl1 
						inner join #TempDestinationCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode
						where tbl2.Destination = @VarDestination

				End


	   End

	   insert into #TempNewDestinations
		(
			Destination,
			DestinationAbbrv,
			DestinationTypeID,
			InternalCode,
			ExternalCode,
			BeginDate,
			EndDate,
			NumberPlanID,
			CountryID
		)
		select @VarDestination , substring(@VarDestination , 1,20) ,
		       Case
					When charindex('Mobile' , @VarDestination) <> 0  then 2
					Else 1
			   End,
		       NULL , NULL , @VarEffectiveDate , NULL , @NumberplanID,
			   @VarResolvedCountryID 
		      

	   FETCH NEXT FROM Cur_CreateNewDestination
	   INTO @VarDestination  , @VarEffectiveDate
 
END   

CLOSE Cur_CreateNewDestination  
DEALLOCATE Cur_CreateNewDestination

select tbl2.Country , tbl1.*
from #TempNewDestinations tbl1
inner join UC_Reference.dbo.tb_Country tbl2 on tbl1.CountryID = tbl2.CountryID

------------------------------------------------------------
-- Insert the new destinations into the TB_Destination table
------------------------------------------------------------

insert into UC_Reference.dbo.tb_Destination
(
	Destination,
	DestinationAbbrv,
	DestinationTypeID,
	InternalCode,
	ExternalCode,
	BeginDate,
	EndDate,
	NumberPlanID,
	CountryID,
	ModifiedDate,
	ModifiedByID,
	Flag
)
select 	Destination, DestinationAbbrv,	DestinationTypeID,InternalCode,
	    ExternalCode,BeginDate, EndDate, NumberPlanID, 	CountryID,
		getdate(), @UserID, 0
from #TempNewDestinations

----------------------------------------------------------------
-- Update the IDs of the newly created destinations in the
-- Upload tables
----------------------------------------------------------------

update tbl3
set tbl3.DestinationID = tbl1.DestinationID
from UC_Reference.dbo.tb_Destination tbl1
inner join #TempNewDestinations tbl2 on tbl1.Destination = tbl2.Destination
    and tbl1.NumberPlanID = tbl2.NumberPlanID
	and tbl1.BeginDate = tbl2.BeginDate
	and tbl1.CountryID = tbl2.CountryID
	and tbl1.DestinationTypeID = tbl2.DestinationTypeID
inner join #TempUploadDestination tbl3 on tbl2.Destination = tbl3.Destination
    and tbl3.DestinationId is NULL 
	and tbl3.Flag & 64 = 64
 
 
-----------------------------------------------------
-- Drop all the temporary tables created during the 
-- process
-----------------------------------------------------   

drop table #TempDestinationCountryCode
drop table #TempNewDestinations
drop table #TempAllCountryCode

Return 0
GO
