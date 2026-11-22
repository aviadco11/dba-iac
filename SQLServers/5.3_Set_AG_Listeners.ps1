Start-Transcript -Append
c:\CRB\Bootstrap_Files\Win\5_3_SetAG_Listeners_log.txt

cls

Write-Host '
!!!!! Before running below commands, a few things need to be known/set
first : !!!!!! ' -ForegroundColor Cyan
Write-Host '
 1.New listener creation needs to be run on the AG primary Node.
 2.The cluster name that these nodes are resources on , needs to be granted
FULL control to the OU that this listener name wil be created in :
      Example: <<servername>> is granted  full control in the following OU
location : "OU=Servers,OU=Databases,OU=Stg,DC=<<domain>>,DC=com ( This
example puts permissionss in the staging OU)"
 3. If the listener will be added to a different OU then that also need the
cluster name granted full control to it as well ( Normally it goes in same
OU so this may not be needed ).
    ' -ForegroundColor Yellow

 $UserInput = Read-Host "Enter YES to proceed or any other value to quit"


    if ($UserInput -ne "yes") {
        Write-Host "  Exiting the script..." -ForegroundColor Yellow
        return}
     elseif ($UserInput -eq "yes") {
        Write-Host "  Proceeding with the script to set AG Listener:"
-ForegroundColor Green
         }


import-module sqlserver


$AGPrimaryNode = Read-Host "Enter Primary Node of AG group (ex:
<<servername>>)"
Write-Host "AGPrimaryNode: " $AGPrimaryNode -fore yellow

$AvailabilityGroupName = Read-Host "Enter Availability Group Name  (ex:
AG-TEST)"
Write-Host "Availability Group Name: " $AvailabilityGroupName  -fore yellow

$ListenerName = Read-Host "Enter new Listener Name ( ex: AWS-LS-TEST-STG)"
Write-Host "Listener Name: " $ListenerName  -fore yellow

$ListenerIP1  = Read-Host "Enter 1st IP for Listener ( ex: <<ip_address>>) "
Write-Host "Listener IP #1:" $ListenerIP1   -fore yellow

$ListenerIP2  = Read-Host "Enter 2nd IP for Listener ( ex: <<ip_address>>) "
Write-Host "Listener IP #2: "$ListenerIP2 -fore yellow

#$DefaulySubMask = '255.255.255.192'
$SubnetMask = Read-Host " Enter Subnet Mask for staic IP (ex:
255.255.255.192)"
Write-Host "Subnet Mask " $SubnetMask  -fore yellow

$Port  = Read-Host "Port # ( ex: 1433) "
Write-Host "Port #: "$Port -fore yellow

<#
<<ip_address>>
<<ip_address>>
#>

# Construct the T-SQL command to create the Availability Group listener
$sqlCommand = @"
USE master
GO
ALTER AVAILABILITY GROUP [$AvailabilityGroupName]
 ADD LISTENER '$ListenerName' (
    WITH IP (('${ListenerIP1}','${SubnetMask}'),
     ('${ListenerIP2}','${SubnetMask}' )
     )
     , Port= $Port);
GO
"@

#$sqlcommand
# Execute the T-SQL command using Invoke-SqlCmd
Invoke-Sqlcmd -ServerInstance $AGPrimaryNode -Query $sqlCommand


<#
USE [master]
GO
ALTER AVAILABILITY GROUP [AG-TEST]
ADD LISTENER N'AWS-LS-TEST-STG' (
WITH IP
((N'<<ip_address>>', N'255.255.255.192'),
(N'<<ip_address>>', N'255.255.255.192')
)
, PORT=1433);
GO
#>



Write-Host "AG Listener done!" -ForegroundColor Yellow

Stop-Transcript