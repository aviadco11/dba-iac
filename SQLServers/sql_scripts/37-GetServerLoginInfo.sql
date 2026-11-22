USE [DBAUtilities]
GO

/****** Object:  StoredProcedure [dbo].[GetServerLoginInfo]    Script Date:
8/21/2025 9:42:02 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



  CREATE OR ALTER      PROCEDURE [dbo].[GetServerLoginInfo]

       @pKeepDays INT = 30
      ,@Output BIT = 0

    AS
/*========================================================================================
                            Cross River Bank
==========================================================================================
Proc Name   : [dbo].[GetServerLoginInfo]
Author      : Eugene Smolyak
Create Date : Unknown
==========================================================================================
Description : [dbo].[GetServerLoginInfo]
==========================================================================================
Test Query  :
EXEC dbo.[GetServerLoginInfo]  @pKeepDays=30, @output = 1;



==========================================================================================
Returns     : 0 Success / 1 Failure
==========================================================================================
Revisions   :
Author            Date        Description

pasaro  2025-08-21  Modified the variable to use the sqljobsoutput
directory
pasaro  2025-08-27  Re-wrote completely to store locally in the
DBAUtilities DB
                              This allows us to then save the data in S3
using backups
========================================================================================*/
    BEGIN

SET NOCOUNT ON;
---------------------------
--DECLARE WORKING VARIABLES
---------------------------
declare @CleanupDate datetime;
declare @svrName varchar(255)
DECLARE @CleanDay DATETIME
DECLARE @rowcount INT
DECLARE @Msg VARCHAR(2000)

-----------------------------------------------------
--DROP AND CREATE GLOBAL TEMP TABLES FOR THIS PROCESS
-----------------------------------------------------
  DROP TABLE IF EXISTS ##final_result_login_info;

  CREATE TABLE ##final_result_login_info
  (command_name VARCHAR(255) NULL,
  command VARCHAR(1000) NULL
  )
------------------------------
--INITIALIZE WORKING VARIABLES
------------------------------
  SET @CleanupDate = DATEADD(DAY, -@pKeepDays, GETDATE())
SET @CleanDay = CAST(CAST(@CleanupDate AS DATE) AS DATETIME)


  --by default it will take the current server name, we can the set the
server name as well
set @svrName = convert(varchar,SERVERPROPERTY
('ComputerNamePhysicalNetBIOS'));

-----------------------------------------------------------------------
--GENERATE THE TABLES THAT CONTAIN THE PERMISSIONS THAT WE NEED TO SAVE
-----------------------------------------------------------------------
exec DBAUtilities.dbo.sp_SrvPermissions @DropTempTables=0, @Output='None';


  INSERT ##final_result_login_info
(command_name
,Command)
  SELECT '1-SrvPrincipal' AS [Type], RTRIM(createScript) FROM
##SrvPrincipals WHERE createScript IS NOT NULL
    UNION
    SELECT '2-RoleName, LoginName',    RTRIM(addScript) FROM ##SrvRoles
WHERE addScript IS NOT NULL
    UNION
    SELECT '3-GranteeName',            RTRIM(GrantScript) FROM
##SrvPermissions WHERE GrantScript IS NOT NULL
    AND RTRIM(GrantScript) NOT LIKE '%Certificate%'
    ORDER BY 1;

BEGIN TRY
-----------------------------------------------
--PREVENT TESTING RECORDS FROM CLUTTERING TABLE
-----------------------------------------------
DELETE FROM DBAUtilities.dbo.Server_login_info
WHERE CreateDate > @CleanDay

--------------------
--INSERT NEW RECORDS
--------------------
INSERT INTO DBAUtilities.dbo.Server_login_info
(ServerName
,Command_name
,command)
SELECT @@SERVERNAME AS ServerName,
  command_name,
  command
FROM ##final_result_login_info

--------------------------------------------
--DELETE DATA OLDER THAN 30 DAYS IN THE PAST
--------------------------------------------
DELETE FROM DBAUtilities.dbo.Server_login_info
WHERE CreateDate < @CleanupDate
END TRY

BEGIN CATCH
   PRINT 'An error occurred!';
PRINT ERROR_MESSAGE();   -- prints the error message
PRINT ERROR_NUMBER();    -- prints the error number
PRINT ERROR_SEVERITY();  -- prints severity
PRINT ERROR_STATE();     -- prints state
PRINT ERROR_LINE();      -- prints line number where error occurred

  -- Re-throw the original error with all details
THROW;

-------------------------------
--RETURN A FAILURE IN PROCEDURE
-------------------------------
RETURN 1
END CATCH;

----------------------------
--RETURN OUTPUT IF REQUESTED
----------------------------
IF @Output = 1
BEGIN
PRINT CONCAT('Permissions records created > ', @CleanDay)
SELECT * FROM DBAUtilities.dbo.Server_login_info
WHERE CreateDate > @CleanDay
END
----------------------
--RETURN 0 FOR SUCCESS
----------------------
RETURN 0
    END

GO