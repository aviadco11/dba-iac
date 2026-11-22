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
       --,@pRecipients varchar(2000) = '<<email>>'
       ,@pRecipients varchar(2000)='<<email>>;<<email>>'
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

SET @vSubject = 'SQL Server Infrastructure Build Notification for Patching
Configuration: '

IF (LEN(@WindowsClusterName) > 0)
BEGIN
SET @vSubject  = CONCAT(@vSubject, ' on cluster ', @WindowsClusterName, '
has been built and is ready for patching as of: ', @NotificationDate)
END
ELSE
BEGIN
SET @vSubject  = CONCAT(@vSubject, 'A new standalone SQL Server has been
built and is ready for patching as of: ', @NotificationDate)
END


------------
--DEFINE CSS
------------
SET @Style += +N'<style type="text/css">' + N'.tg
 {border-collapse:collapse;border-spacing:0;border-color:#aaa;}'
    + N'.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px
5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#aaa;color:#333;background-color:#ffffff;}'
    + N'.tg th{font-family:Arial,
sans-serif;font-size:14px;font-weight:normal;padding:10px
5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#aaa;color:#fff;background-color:#03A0EF;}'
    + N'.tg .tg-9ajh{font-weight:bold;background-color:#F1F1F2}' + N'.tg
.tg-hgcj{font-weight:bold;text-align:left}'
    + N'</style>';


set @EmailMessage = CONCAT('Dear <<name>>,',
'<br>',
'<br>',
'Below is a newly deployed set of server(s) that need to have patching
configured.  Please make sure you configure orchestration groups for any
clustered configurations.  Standalone machines do not require Orchestration
Groups.',
'<br>',
'<br>',
'Thanks,',
'<br>',
'<br>',
'DBA TEAM',
'<br>',
'<br>')


set @tableHTML += @Style + N'<H2>SQL Build Notification for Patching
Configuration  on '+@MyServerName + '</H2>' + @EmailMessage + @tableHTML

/*
+ N'<table class="tg">' --DEFINE TABLE
/*
Define Column Headers and Column Span for each Header Column
*/
+ N'<tr>'
    + N'<th class="tg-hgcj" colspan="1">Cluster</th>'
+ N'<th class="tg-hgcj" colspan="2">Cluster Node Details</th>'
+ N'</tr>'
/*
Define Column Sub-Headers
*/
+ N'<tr>'
+ N'<td class="tg-9ajh">Cluster Name</td>'
    + N'<td class="tg-9ajh">Node Name</td></tr>'
/*
Define data for table and cast to xml
*/
*/
IF (LEN(@WindowsClusterName) > 0 )
BEGIN

SET @tableHTML = @tableHTML

+ N'<table class="tg">' --DEFINE TABLE
/*
Define Column Headers and Column Span for each Header Column
*/
+ N'<tr>'
    + N'<th class="tg-hgcj" colspan="1">Cluster</th>'
+ N'<th class="tg-hgcj" colspan="2">Cluster Node Details</th>'
+ N'</tr>'
/*
Define Column Sub-Headers
*/
+ N'<tr>'
+ N'<td class="tg-9ajh">Cluster Name</td>'
    + N'<td class="tg-9ajh">Node Name</td></tr>'
/*
Define data for table and cast to xml
*/

+ CAST(( SELECT td = ISNULL(@clusterName,'Stand Alone') ,
'',
                    td = ISNULL(REPLACE(MachineName,'$',''),'Node Name
Unknown') ,
''
             FROM  @Machine
           FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'

END
ELSE
BEGIN
SET @tableHTML = @tableHTML +

+ N'<table class="tg">' --DEFINE TABLE
/*
Define Column Headers and Column Span for each Header Column
*/
+ N'<tr>'
    + N'<th class="tg-hgcj" colspan="1">Machine</th>'
+ N'<th class="tg-hgcj" colspan="2">Machine Node Details</th>'
+ N'</tr>'
/*
Define Column Sub-Headers
*/
+ N'<tr>'
+ N'<td class="tg-9ajh">Machine Type</td>'
    + N'<td class="tg-9ajh">Node Name</td></tr>'
/*
Define data for table and cast to xml
*/

+ CAST(( SELECT td = 'Stand Alone' ,
'',
                    td = ISNULL(REPLACE(@MyServerName,'$',''),'Node Name
Unknown') ,
''
           FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'
END
  --SELECT @tableHTML

-----------------------------------------------------
-- Send an html formatted e-mail to notify of restart
-----------------------------------------------------
   EXEC msdb.dbo.sp_send_dbmail
       @profile_name = @pMailProfile,
       @recipients = @pRecipients,
       @subject = @vSubject,
       @body = @tableHTML,
  @importance = 'High',
  @sensitivity = 'Confidential',
       @body_format = 'HTML';
