USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCheckDateOverlap]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCheckDateOverlap]
(
	@BeginDate datetime,
	@Enddate datetime,
	@ResultFlag int Output
)
As

set @ResultFlag = 0

--select *
--from #TempDateOverlapCheck

if ( @EndDate is not NULL )
Begin

	----------------------------------------------------------------------------------
	-- SCENARIO 1 : EndDate is not Null and Existing Agreements End Date is not NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 1
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is not NULL
				and @BeginDate <= BeginDate
				and @EndDate >= EndDate )
	Begin 

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 2
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is not NULL
				and @BeginDate >= BeginDate
				and @EndDate <= EndDate )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 3
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is not NULL
				and @BeginDate >= BeginDate
				and @BeginDate <= EndDate
				and @EndDate >= EndDate )
	Begin

			set @ResultFlag = 1
			Return 1

	End


	---------------------------------------------------------------
	-- ADDED: Fix to handle certain overlap scenario missed earlier
	---------------------------------------------------------------
	-- DATE: 15th Feb 2020
	---------------------------------------------------------------
	-- Change Start
	---------------------------------------------------------------
	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is not NULL
				and @BeginDate <= BeginDate
				and @EndDate >= BeginDate
				and @EndDate <= EndDate )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	---------------------------------------------------------------
	-- Change End
	---------------------------------------------------------------

    ----------------------------------------------------------------------------------
	-- SCENARIO 2 : EndDate is not Null and Existing Agreements End Date is NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 4
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is NULL
				and @BeginDate <= BeginDate
				and @EndDate >= BeginDate )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 5
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is NULL
				and @BeginDate >= BeginDate
				and @EndDate >= BeginDate )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	
End

Else
Begin

	----------------------------------------------------------------------------------
	-- SCENARIO 3 : EndDate is Null and Existing Agreements End Date is not NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 6
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is not NULL
				and @BeginDate <= BeginDate )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 7
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is not NULL
				and @BeginDate >= BeginDate
				and @BeginDate <= EndDate )
	Begin

			set @ResultFlag = 1
			Return 1

	End


	----------------------------------------------------------------------------------
	-- SCENARIO 3 : EndDate is Null and Existing Agreements End Date is NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 8
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where Enddate is NULL )
	Begin

			set @ResultFlag = 1
			Return 1

	End
	
End 

Return 0
GO
