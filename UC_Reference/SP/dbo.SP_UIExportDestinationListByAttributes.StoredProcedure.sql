USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIExportDestinationListByAttributes]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIExportDestinationListByAttributes]
(
    @DestinationName varchar(60) = NULL,
	@SelectDate date,
	@DestinationtypeID int,
	@CountryIDList nvarchar(max),
	@NumberPlanID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

set @DestinationName = rtrim(ltrim(@DestinationName))

if (( @DestinationName is not Null ) and ( len(@DestinationName) = 0 ) )
	set @DestinationName = NULL

if ( ( @DestinationName <> '_') and charindex('_' , @DestinationName) <> -1 )
Begin

	set @DestinationName = replace(@DestinationName , '_' , '[_]')

End

Declare @CountryIDTable table (CountryID varchar(100) )

Begin Try

		insert into @CountryIDTable
		select * from FN_ParseValueList ( @CountryIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from @CountryIDTable where ISNUMERIC(CountryID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End

		------------------------------------------------------
		-- Check if the All the countries have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from @CountryIDTable 
						where CountryID = 0
				  )
		Begin

				  Delete from @CountryIDTable -- Remove all records

				  insert into @CountryIDTable (  CountryID )
				  Select countryID
				  from tb_country
				  where flag & 1  <> 1 -- Insert all the countries into the temp table

				  GOTO PROCESSRESULT
				  
		End
		
        -------------------------------------------------------------------
		-- Check to ensure that all the Country IDs passed are valid values
		-------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from @CountryIDTable 
						where CountryID not in
						(
							Select CountryID
							from tb_Country
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

		End

PROCESSRESULT:


		Select tbl1.DestinationID , tbl1.Destination , tbl1.DestinationAbbrv , 
		       tbl5.DestinationTypeID , tbl5.DestinationType,
			   tbl3.CountryID , tbl3.Country , tbl3.CountryCode ,
			   tbl4.NumberPlanID ,tbl4.NumberPlan , 
			   tbl1.BeginDate as DestinationBeginDate , 
			   tbl1.EndDate as DestinationEndDate
		into #TempDestination
		from tb_Destination tbl1
		inner join @CountryIDTable tbl2 on tbl1.CountryID =  tbl2.CountryID
		inner join tb_Country tbl3 on tbl1.CountryID = tbl3.CountryID
		inner join tb_Numberplan tbl4 on tbl1.numberplanid = tbl4.NumberPlanID
		inner join tb_DestinationType tbl5 on tbl1.DestinationTypeID = tbl5.DestinationTypeID
		where tbl1.numberplanid = @NumberPlanID
		and @SelectDate between tbl1.BeginDate and isnull(tbl1.EndDate , @SelectDate)
		and tbl1.DestinationtypeID = 
		   Case
					When @DestinationtypeID = 0 then tbl1.DestinationtypeID
					Else @DestinationtypeID
		   End
		and tbl1.flag & 1 <> 1


		---------------------------------------------------------
		-- Prepare the dynamic SQL as per the regular expression
		---------------------------------------------------------

		set @SQLStr = 'Select * ' +
		              ' from #TempDestination tbl1 '

		set @Clause1 = 
				   Case
						   When (@DestinationName is NULL) then ''
						   When (@DestinationName = '_') then ' where  tbl1.Destination like '  + '''' + '%' + '[_]' + '%' + ''''
						   When ( ( Len(@DestinationName) =  1 ) and ( @DestinationName = '%') ) then ''
						   When ( right(@DestinationName ,1) = '%' ) then ' where tbl1.Destination like ' + '''' + substring(@DestinationName,1 , len(@DestinationName) - 1) + '%' + ''''
						   Else ' where tbl1.Destination like ' + '''' + @DestinationName + '%' + ''''
				   End

		set @SQLStr = @SQLStr + @Clause1

		--------------------------------------------
		-- Add the sorting clause to the resut set
		--------------------------------------------

		--print @SQLStr

		select *
		into #TempDestination1
		from #TempDestination
		where 1 = 2

		Insert into #TempDestination1
		Exec (@SQLStr)

		---------------------------------------------------------------------------
		-- Now find out the associated dialled digits for each of these destinations
		----------------------------------------------------------------------------

		Select Destination , DestinationAbbrv , DestinationType,
			   Country , CountryCode ,NumberPlan , 
			   DestinationBeginDate , DestinationEndDate,
			   tbl2.DialedDigits , tbl2.BeginDate as DDBeginDate , tbl2.EndDate as DDEndDate
		from  #TempDestination1 tbl1 
		left join tb_DialedDigits tbl2 on tbl1.DestinationID = tbl2.DestinationID
		    and @SelectDate between tbl2.BeginDate and isnull(tbl2.EndDate , @SelectDate)


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Exporting List of Destinations.' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch


-------------------------------------------------
-- Drop temporary tables created in the process
-------------------------------------------------

Drop table #TempDestination
Drop table #TempDestination1
GO
