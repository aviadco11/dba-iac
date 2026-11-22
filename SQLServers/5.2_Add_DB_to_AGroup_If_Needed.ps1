
Start-Transcript -Append
c:\CRB\Bootstrap_Files\Win\5_2_AddDBstoAG_ifNeeded_log.txt


cls
Write-host " This code with take an existing standalone dB and prep it for
AG availability and put it in AG synchronization " -ForegroundColor Yellow

import-module dbatools
import-module sqlserver

$SQLNode1 = Read-Host "Enter SQL Node1 of AG group (ex: <<servername>>)"
Write-Host "SQL Node 1: " $SQLNode1 -fore yellow


$DatabaseName = Read-Host "Enter Databasename of AG group (ex: TestdB)"
Write-Host "Database name: " $DatabaseName  -fore yellow

$AvailabilityGroupName = Read-Host "Enter Availability Group Name  (ex:
AG-TEST)"
Write-Host "Availability Group Name: " $AvailabilityGroupName  -fore yellow

$MachineName = [Environment]::MachineName
#$InstanceName = get-sqlinstance -ServerInstance $MachineName


# Construct the T-SQL command to check the current recovery mode
$sqlCommand = @"
USE [master];

DECLARE @currentRecoveryMode AS VARCHAR(20);
SELECT @currentRecoveryMode = recovery_model_desc
FROM sys.databases
WHERE name = '$DatabaseName';

SELECT @currentRecoveryMode AS CurrentRecoveryMode;
"@

# Execute the T-SQL command using Invoke-Sqlcmd and retrieve the current
recovery mode
$currentRecoveryMode = Invoke-Sqlcmd -ServerInstance $SQLNode1 -Database
"master" -Query $sqlCommand #-TrustServerCertificate

# Check the current recovery mode and set it to Full if it is currently set
to Simple
if ($currentRecoveryMode.CurrentRecoveryMode -eq "SIMPLE") {
    # Construct the T-SQL command to set recovery mode to Full
    $setRecoveryCommand = @"
USE [master];

ALTER DATABASE [$DatabaseName] SET RECOVERY FULL;
"@

    # Execute the T-SQL command to set recovery mode to Full
    Invoke-Sqlcmd -ServerInstance $SQLNode1 -Database "master" -Query
$setRecoveryCommand #-TrustServerCertificate


    Write-Output "Recovery mode changed to Full."
}
else {
    Write-Output "Recovery mode is already set to Full or unknown."
}


# Construct the T-SQL command to change the database owner to '<<username>>'
$sqlCommand = @"
USE [$DatabaseName];

ALTER AUTHORIZATION ON DATABASE::[$DatabaseName] TO <<username>>;
"@

# Execute the T-SQL command using Invoke-Sqlcmd to change the database
owner to 'sa'
Invoke-Sqlcmd -ServerInstance $SqlServerInstance -Database "master" -Query
$sqlCommand #-TrustServerCertificate

Write-Output "Database owner changed to '<<username>>'."

Backup-DbaDatabase -SqlInstance $SQLNode1 -Database $DatabaseName

Start-Sleep -Second 10

Add-DbaAgDatabase -SqlInstance $SQLNode1 -AvailabilityGroup
$AvailabilityGroupName -Database $DatabaseName  -SeedingMode Automatic
-Confirm

Write-Host "Add dBs done!" -ForegroundColor Yellow

Stop-Transcript