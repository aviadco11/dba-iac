Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\2_PSCommandsAppLog.txt

Set-Location C:\CRB\Bootstrap_Files\Win
Copy-Item .\PSModules\* -Destination 'C:\Program
Files\WindowsPowerShell\Modules' -Recurse

import-module SQLServer
import-module dbatools
Import-Module AWSPowerShell

$instanceId = Get-EC2InstanceMetadata -Category InstanceId
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "AppServerInstall"

function setStatusTag($status) {
    $tag.Value = $status
    New-EC2Tag -Resource $instanceId -Tag $tag
}

Write-Output "Settig timezone $(Get-Date)"
Set-TimeZone -Name "US Eastern Standard Time"

##Format EBS Volumes
##Write-Output "Starting Drive provisioning/formatting $(Get-Date)"
##Initialize-Disk -Number 1 -PartitionStyle GPT
##New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter D |
format-volume -filesystem NTFS -newfilesystemlabel Data -AllocationUnitSize
65536


##STart SSMS Install
Write-Output "Starting SSMS Install $(Get-Date)"
Start-Process -FilePath
"C:\CRB\Bootstrap_Files\Win\SQLServer2022-DEV-x64-ENU\SSMS-Setup-ENU.exe"
 -ArgumentList  /Quiet -Wait
##End SSMS Install


Stop-Transcript