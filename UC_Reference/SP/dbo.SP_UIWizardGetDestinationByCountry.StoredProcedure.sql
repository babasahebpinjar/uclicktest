USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardGetDestinationByCountry]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardGetDestinationByCountry]
(
	@CountryIDList nvarchar(max),
	@NumberPlanID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

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

		Select tbl1.DestinationID as ID , 
		       tbl1.Destination + ' ' + '(' +replace(CONVERT(varchar(10) , tbl1.BeginDate , 120 ) , '-' , '/') + ' - '+ 
							Case
									When tbl1.EndDate is not NULL then replace(CONVERT(varchar(10) , tbl1.EndDate , 120 ) , '-' , '/')
									Else 'Open'
							End  + ')'as Name
		from tb_Destination tbl1
		inner join @CountryIDTable tbl2 on tbl1.CountryID =  tbl2.CountryID
		where tbl1.numberplanid = @NumberPlanID
		and flag & 1 <> 1
		order by tbl1.Destination

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Returning List of Destinations for Wizard.' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch
GO
