USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCheckDateOverlapForAccountMode]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSCheckDateOverlapForAccountMode]
(
	@StartPeriod datetime,
	@EndPeriod datetime,
	@ResultFlag int Output
)
As

set @ResultFlag = 0

--select *
--from #TempDateOverlapCheck

if ( @EndPeriod is not NULL )
Begin

	----------------------------------------------------------------------------------
	-- SCENARIO 1 : EndPeriod is not Null and Existing Records End Period is not NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 1
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is not NULL
				and @StartPeriod <= StartPeriod
				and @EndPeriod >= EndPeriod )
	Begin 

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 2
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is not NULL
				and @StartPeriod >= StartPeriod
				and @EndPeriod <= EndPeriod )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 3
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is not NULL
				and @StartPeriod >= StartPeriod
				and @StartPeriod <= EndPeriod
				and @EndPeriod >= EndPeriod )
	Begin

			set @ResultFlag = 1
			Return 1

	End

    ----------------------------------------------------------------------------------
	-- SCENARIO 2 : EndPeriod is not Null and Existing Records End Date is NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 4
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is NULL
				and @StartPeriod <= StartPeriod
				and @EndPeriod >= StartPeriod )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 5
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is NULL
				and @StartPeriod >= StartPeriod
				and @EndPeriod >= StartPeriod )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	
End

Else
Begin

	----------------------------------------------------------------------------------
	-- SCENARIO 3 : EndPeriod is Null and Existing Record End Date is not NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 6
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is not NULL
				and @StartPeriod <= StartPeriod )
	Begin

			set @ResultFlag = 1
			Return 1

	End

	------------------
	-- CONDITION 7
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is not NULL
				and @StartPeriod >= StartPeriod
				and @StartPeriod <= EndPeriod )
	Begin

			set @ResultFlag = 1
			Return 1

	End


	----------------------------------------------------------------------------------
	-- SCENARIO 3 : EndPeriod is Null and Existing Records End Date is NULL
	----------------------------------------------------------------------------------

	------------------
	-- CONDITION 8
	------------------

	if exists ( select 1 from #TempDateOverlapCheck
				where EndPeriod is NULL )
	Begin

			set @ResultFlag = 1
			Return 1

	End
	
End 

Return 0
GO
