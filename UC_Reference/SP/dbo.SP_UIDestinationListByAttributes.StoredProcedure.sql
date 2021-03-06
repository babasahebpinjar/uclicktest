USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDestinationListByAttributes]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDestinationListByAttributes]
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

		Select tbl1.DestinationID , tbl1.Destination , tbl3.CountryID , tbl3.Country , 0 as AssociatedDialedDigitFlag
		into #TempDestination
		from tb_Destination tbl1
		inner join @CountryIDTable tbl2 on tbl1.CountryID =  tbl2.CountryID
		inner join tb_country tbl3 on tbl2.CountryID = tbl3.CountryID
		where tbl1.numberplanid = @NumberPlanID
		and @SelectDate between tbl1.BeginDate and isnull(tbl1.EndDate , @SelectDate)
		and tbl1.DestinationtypeID = 
		   Case
					When @DestinationtypeID = 0 then tbl1.DestinationtypeID
					Else @DestinationtypeID
		   End
		and tbl1.flag & 1 <> 1


		select count(*) as TotalDD , tbl1.DestinationID
		into #TempDestinationDDCount
		from tb_DialedDigits tbl1
		right join #TempDestination tbl2 on tbl1.DestinationID = tbl2.DestinationID
		where @SelectDate between tbl1.BeginDate and isnull(tbl1.EndDate , @SelectDate)
		group by tbl1.DestinationID	
		
		update tbl1
		set AssociatedDialedDigitFlag = 
				Case 
						When tbl2.TotalDD = 0 then 0
						When tbl2.TotalDD > 0 then 1
				End	
		from #TempDestination tbl1
		inner join #TempDestinationDDCount tbl2 on tbl1.DestinationID = tbl2.DestinationID

		---------------------------------------------------------
		-- Prepare the dynamic SQL as per the regular expression
		---------------------------------------------------------

		set @SQLStr = 'Select DestinationID , Destination , CountryID , Country , AssociatedDialedDigitFlag' +
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

		set @SQLStr = @SQLStr  + ' order by tbl1.Country ,tbl1.Destination ' 

		--print @SQLStr

		Exec (@SQLStr)


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Returning List of Destinations.' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch

---------------------------------------------------
-- Drop temporary table created during processing
---------------------------------------------------

Drop table #TempDestination
Drop table #TempDestinationDDCount
GO
