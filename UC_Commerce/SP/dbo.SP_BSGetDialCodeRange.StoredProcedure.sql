USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSGetDialCodeRange]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSGetDialCodeRange]
(
	@DDValueChar varchar(15)
)
As

Declare @DDValueBreakOut varchar(15),
        @BreakOutLevel int,
		@Counter int = 0


select @BreakOutLevel = max(len(substring(DialedDigits , len(@DDValueChar) + 1 ,  len(DialedDigits ) ) ))
from #TempMasterDialedDigits
where substring(DialedDigits , 1 , len(@DDValueChar) ) = @DDValueChar

set @BreakOutLevel = ISNULL(@BreakOutLevel , 0)

----------------------------------
-- Print for debugging purpose
----------------------------------

--select @DDValueChar as DDValueChar,
--	   @BreakOutLevel as BreakOutLevel

---------------------------------------------------------------------
-- Break out level 0 indicates that this is the most exhaustive
-- level till which the dial code has been defined
---------------------------------------------------------------------

if (@BreakOutLevel = 0)
Begin

	Insert into #TempAllDDRange (DialedDigits , DDlength) values (@DDValueChar , len(@DDValueChar))

End

------------------------------------------------------------------------
-- Any value greater than 0 indicates that the dial code needs to be 
-- further traversed for getting the detail breakout
-------------------------------------------------------------------------

Else
Begin

		set @Counter = 0

		while ( @Counter <= 9)
		Begin

		        set @DDValueBreakOut = @DDValueChar + convert(varchar(1) , @Counter)

				select @BreakOutLevel = max(len(substring(DialedDigits , len(@DDValueBreakOut) + 1 ,  len(@DDValueBreakOut) ) ))
				from #TempMasterDialedDigits
				where substring(DialedDigits , 1 , len(@DDValueBreakOut) ) = @DDValueBreakOut

				set @BreakOutLevel = ISNULL(@BreakOutLevel , 0)

				---------------------------------------------------------------------
				-- Break out level 0 indicates that this is the most exhaustive
				-- level till which the dial code has been defined
				---------------------------------------------------------------------

				if (@BreakOutLevel = 0)
				Begin


					Insert into #TempAllDDRange (DialedDigits, DDLength) values (@DDValueBreakOut , Len(@DDValueBreakOut))

				End

				Else
				Begin

						Exec SP_BSGetDialCodeRange @DDValueBreakOut

				End
						        

				set @Counter = @Counter + 1

		End


End

Return 0
GO
