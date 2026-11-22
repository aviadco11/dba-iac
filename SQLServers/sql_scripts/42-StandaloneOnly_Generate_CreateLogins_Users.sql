SET NOCOUNT ON;
DECLARE @ServerName VARCHAR(100)
DECLARE @IsLegend BIT = 0

--SELECT @ServerName = LEFT(CAST(@@SERVERNAME AS VARCHAR(50)),
 CHARINDEX('\', CAST(@@SERVERNAME AS VARCHAR(50)), 1) - 1)

    DECLARE @NumRange AS VARCHAR(50) = '%[0-9]%'
    WHILE PATINDEX(@NumRange, @ServerName) > 0
BEGIN
        SET @ServerName = STUFF(@ServerName, PATINDEX(@NumRange,
@ServerName), 1, '')
END

SET @Servername = CONCAT(@ServerName , '%')
--SELECT @ServerName

-----------------
--EMAIL VARIABLES
-----------------
DECLARE @pMailProfile varchar(64)='CRB EXCH'
       ,@pRecipients varchar(2000) = '<<email>>'
       --,@pRecipients varchar(2000)='<<email>>;<<email>>'
  ,@vSubject varchar(255)
  ,@tableHTML VARCHAR(MAX) = ''
  ,@EmailMessage VARCHAR(MAX)
  ,@NotificationDate DATE =  CAST(GetDate() AS DATE)
       ,@Style NVARCHAR(MAX)= '';
DECLARE @clusterName VARCHAR(100)

SELECT @clusterName = cluster_name FROM master.sys.dm_hadr_cluster;

DECLARE @Machine TABLE (MachineName VARCHAR(4000))
DECLARE @SQLCode TABLE (SQLGrants VARCHAR(MAX))
DECLARE @WindowsClusterName sysname
DECLARE @MachineName VARCHAR(100)
DECLARE @MyServerName sysname = @@ServerName

INSERT INTO @Machine
(
    MachineName
)
SELECT DISTINCT  CS.replica_server_name
    FROM sys.availability_groups_cluster AS C
        LEFT JOIN sys.dm_hadr_availability_replica_cluster_states AS CS
            ON CS.group_id = C.group_id
WHERE cs.replica_server_name IS NOT NULL
IF @@Rowcount = 0
BEGIN
INSERT INTO @Machine
(
    MachineName
)
VALUES
(
@@SERVERNAME
)
END
select @WindowsClusterName = cluster_name from master.sys.dm_hadr_cluster;


UPDATE @Machine
SET MachineName = CONCAT(Machinename, '$')

DECLARE @SQL NVARCHAR(4000)
DECLARE cur_Logins CURSOR FOR SELECT MachineName FROM @Machine

OPEN cur_Logins

FETCH NEXT FROM cur_Logins INTO @MachineName

WHILE @@FETCH_STATUS = 0
BEGIN
SET @MachineName = CONCAT('<<domain>>\', @MachineName)
IF @IsLegend = 0
BEGIN
--SELECT @SQL = CONCAT(':CONNECT ', @@SERVERNAME , '
SELECT @SQL = CONCAT('

IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE Name =
','''',@MachineName, '''',')', '
BEGIN
CREATE LOGIN ', QUOTENAME(@machineName), ' FROM WINDOWS WITH
DEFAULT_DATABASE=[master];','
END', '
USE [master];
IF NOT EXISTS(SELECT 1 FROM Sys.sysusers WHERE Name = ',
'''',@MachineName,'''', ')','
BEGIN
CREATE USER ', QUOTENAME(@MachineName), ' FOR LOGIN ',
QUOTENAME(@MachineName), '
END

ALTER ROLE [db_datareader] ADD MEMBER ', QUOTENAME(@MachineName) ,';','

GRANT VIEW ANY DATABASE TO ', QUOTENAME(@MachineName), ';', '
GRANT VIEW ANY DEFINITION TO', QUOTENAME(@MachineName), ';', '
GRANT VIEW SERVER STATE TO ', QUOTENAME(@MachineName), ';', '
GRANT ALTER ANY AVAILABILITY GROUP TO ', QUOTENAME(@MachineName), ';', '
GRANT ALTER ANY DATABASE TO ', QUOTENAME(@MachineName), ';', '
GRANT CREATE ENDPOINT TO ', QUOTENAME(@MachineName), ';', '
GRANT ALTER ANY ENDPOINT TO ', QUOTENAME(@MachineName), ';', '
GRANT CONNECT SQL TO ', QUOTENAME(@MachineName), '
;')
END
ELSE
BEGIN
SELECT @SQL = CONCAT('IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE Name
= ','''',@MachineName, '''',')', '
BEGIN
CREATE LOGIN ', QUOTENAME(@machineName), ' FROM WINDOWS WITH
DEFAULT_DATABASE=[master];','
END', '


USE [LegendDBA];
IF NOT EXISTS(SELECT 1 FROM Sys.sysusers WHERE Name = ',
'''',@MachineName,'''', ')','
BEGIN
CREATE USER ', QUOTENAME(@MachineName), ' FOR LOGIN ',
QUOTENAME(@MachineName), '
END

ALTER ROLE [db_datareader] ADD MEMBER ', QUOTENAME(@MachineName) ,';')

END
INSERT INTO @SQLCode
(
   SQLGrants
)
SELECT @SQL
EXEC sp_executeSQL @SQL
FETCH NEXT FROM cur_Logins INTO @MachineName
END

CLOSE cur_Logins
DEALLOCATE cur_Logins


