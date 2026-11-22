Start-Transcript -Append
c:\CRB\Bootstrap_Files\Win\5_1_Set_AGGroups_log.txt


# Preferrable to run this code on intended primary replica

cls
import-module dbatools
import-module sqlserver

Write-Host "----RUN THIS CODE ON INTENDED PRIMARY NODE OF THE CLUSTER
ONLY----" -ForegroundColor Yellow

$SQLNode1 = Read-Host "Enter SQL Node1 of AG group (ex: <<servername>>)"
Write-Host "SQL Node 1: " $SQLNode1 -fore yellow

$SQLNode2 = Read-Host "Enter SQL Node2 of AG group (ex: <<servername>>)"
Write-Host "SQL Node 2: " $SQLNode2 -fore yellow

$MachineName = [Environment]::MachineName
#$InstanceName = get-sqlinstance -ServerInstance $MachineName

$DatabaseName = Read-Host "Enter new Databasename of AG group (ex: TestdB)"
Write-Host "New Database name: " $DatabaseName  -fore yellow

$AvailabilityGroupName = Read-Host "Enter new Availability Group Name  (ex:
AG-TEST)"
Write-Host "New Availability Group Name: " $AvailabilityGroupName  -fore
yellow

$endpoint1 = "TCP://$SQLNode1.<<domain>>:5022"
$endpoint2 = "TCP://$SQLNode2.<<domain>>:5022"


New-DbaDatabase -SqlInstance $MachineName  -Name $DatabaseName

Backup-DbaDatabase -SqlInstance $MachineName  -Database $DatabaseName

Start-Sleep -Second 10

New-DbaAvailabilityGroup -Primary $SQLNode1 -Secondary $SQLNode2 -Name
$AvailabilityGroupName -Database $DatabaseName  -ClusterType Wsfc
-SeedingMode Automatic -FailoverMode Automatic
-ConnectionModeInSecondaryRole Yes -AvailabilityMode SynchronousCommit
-EndpointUrl $endpoint1, $endpoint2  #-Confirm $false

Start-Sleep 10

Invoke-Sqlcmd -ServerInstance $SQLNode1 -Database Master -Query 'alter
event session [AlwaysOn_health] on server state = START ;'
Invoke-Sqlcmd -ServerInstance $SQLNode2 -Database Master -Query 'alter
event session [AlwaysOn_health] on server state = START ;'


Write-Host "Set Agroups done!" -ForegroundColor Yellow

Stop-Transcript