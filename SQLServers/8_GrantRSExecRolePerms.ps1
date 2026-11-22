##### Run on both SQL nodes ###################

import-module sqlserver

$ServerName = [Environment]::MachineName


cls

Write-Host "LocalName =" $ServerName
$SQLNode = Read-Host "Enter SQL Node (ex:" $ServerName")"

Write-Host "SQLNode/MachineName: " $SQLNode   -fore yellow

<#
$AvailabilityGroupName = Read-Host "Enter Availability Group Name  (ex:
AG-TEST)"
Write-Host "Availability Group Name: " $AvailabilityGroupName  -fore yellow

$ListenerName = Read-Host "Enter new Listener Name ( ex: AWS-LS-TEST-STG)"
Write-Host "Listener Name: " $ListenerName  -fore yellow

$ListenerIP1  = Read-Host "Enter 1st IP for Listener ( ex: <<ip_address>>) "
Write-Host "Listener IP #1:" $ListenerIP1   -fore yellow
#>


# Construct the T-SQL command to create the Availability Group listener
$sqlCommand = @"


USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [type] = 'R' AND
[name] = 'RSExecRole') BEGIN
    CREATE ROLE [RSExecRole];
END
GRANT EXECUTE ON dbo.xp_sqlagent_enum_jobs TO [RSExecRole];
GRANT EXECUTE ON dbo.xp_sqlagent_is_starting TO [RSExecRole];
GRANT EXECUTE ON dbo.xp_sqlagent_notify TO [RSExecRole];
GO
USE msdb;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [type] = 'R' AND
[name] = 'RSExecRole') BEGIN
    CREATE ROLE [RSExecRole];
END
GRANT EXECUTE ON dbo.SP_ADD_CATEGORY TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_ADD_JOB TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_ADD_JOBSCHEDULE TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_ADD_JOBSERVER TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_ADD_JOBSTEP TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_DELETE_JOB TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_HELP_CATEGORY TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_HELP_JOB TO [RSExecRole];
GRANT EXECUTE ON dbo.SP_HELP_JOBSCHEDULE TO [RSExecRole];
GRANT EXECUTE ON dbo.sp_verify_job_identifiers TO [RSExecRole];
GRANT SELECT ON dbo.syscategories TO [RSExecRole];
GRANT SELECT ON dbo.sysjobs TO [RSExecRole];


"@

#$sqlcommand
# Execute the T-SQL command using Invoke-SqlCmd
Invoke-Sqlcmd -ServerInstance $SQLNode -Query $sqlCommand
-TrustServerCertificate  -Verbose