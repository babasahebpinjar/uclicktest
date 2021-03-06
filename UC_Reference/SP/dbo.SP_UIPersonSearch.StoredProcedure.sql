USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPersonSearch]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIPersonSearch] 
(
    @FirstName varchar(50) = NULL,
    @LastName varchar(50) = NULL,
    @EmailAddress varchar(50) = NULL,
	@PersonTypeID int
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
        @Clause2 varchar(1000),
	@Clause3 varchar(1000)


if (( @FirstName is not Null ) and ( len(@FirstName) = 0 ) )
	set @FirstName = NULL

if (( @LastName is not Null ) and ( len(@LastName) = 0 ) )
	set @LastName = NULL

if (( @EmailAddress is not Null ) and ( len(@EmailAddress) = 0 ) )
	set @EmailAddress = NULL


if ( ( @FirstName <> '_') and charindex('_' , @FirstName) <> -1 )
Begin

	set @FirstName = replace(@FirstName , '_' , '[_]')

End

if ( ( @LastName <> '_') and charindex('_' , @LastName) <> -1 )
Begin

	set @LastName = replace(@LastName , '_' , '[_]')

End

if ( ( @EmailAddress <> '_') and charindex('_' , @EmailAddress) <> -1 )
Begin

	set @EmailAddress = replace(@EmailAddress , '_' , '[_]')

End

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.PersonID , tbl1.Salutation , tbl1.FirstName , tbl1.LastName , tbl1.EmailAddress , tbl2.PersonType '+
              ' From tb_Person tbl1 ' +
	      ' inner join tb_Persontype tbl2 on tbl1.PersonTypeID = tbl2.PersonTypeID ' +
	      ' where tbl1.Flag & 1 <> 1 '  +
	      Case
		   When @PersonTypeID =  0 then ''
		   Else ' and tbl1.PersonTypeID =  ' + convert(varchar(50) , @PersonTypeID) 
	      End
	      
	      

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@FirstName is NULL) then ''
		   When (@FirstName = '_') then ' and tbl1.FirstName like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@FirstName) =  1 ) and ( @FirstName = '%') ) then ''
		   When ( right(@FirstName ,1) = '%' ) then ' and tbl1.FirstName like ' + '''' + substring(@FirstName,1 , len(@FirstName) - 1) + '%' + ''''
		   Else ' and tbl1.FirstName like ' + '''' + @FirstName + '%' + ''''
	       End


set @Clause2 = 
               Case
		   When (@LastName is NULL) then ''
		   When (@LastName = '_') then ' and tbl1.LastName like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@LastName) =  1 ) and ( @LastName = '%') ) then ''
		   When ( right(@LastName ,1) = '%' ) then ' and tbl1.LastName like ' + '''' + substring(@LastName,1 , len(@LastName) - 1) + '%' + ''''
		   Else ' and tbl1.LastName like ' + '''' + @LastName + '%' + ''''
	       End


set @Clause3 = 
               Case
		   When (@EmailAddress is NULL) then ''
		   When (@EmailAddress = '_') then ' and tbl1.EmailAddress like '  + '''' + '%' + '[_]' + '%' + ''''
		   When ( ( Len(@EmailAddress) =  1 ) and ( @EmailAddress = '%') ) then ''
		   When ( right(@EmailAddress ,1) = '%' ) then ' and tbl1.EmailAddress like ' + '''' + substring(@EmailAddress,1 , len(@EmailAddress) - 1) + '%' + ''''
		   Else ' and tbl1.EmailAddress like ' + '''' + @EmailAddress + '%' + ''''
	       End




-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2 + @Clause3

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.LastName , tbl1.FirstName , tbl1.EmailAddress' 

--print @SQLStr

Exec (@SQLStr)

Return

GO
