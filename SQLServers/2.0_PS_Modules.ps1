Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\2_PSModules_TZ.txt

Set-Location C:\CRB\Bootstrap_Files\Win
Copy-Item .\PSModules\* -Destination 'C:\Program
Files\WindowsPowerShell\Modules' -Recurse

import-module SQLServer
import-module dbatools
Import-Module AWSPowerShell

#$instanceId = Get-EC2InstanceMetadata -Category InstanceId
#$tag = New-Object Amazon.EC2.Model.Tag
#$tag.Key = "SQLSererInstall"

#function setStatusTag($status) {
#    $tag.Value = $status
#    New-EC2Tag -Resource $instanceId -Tag $tag
#}

Write-Output "Settig timezone $(Get-Date)"
Set-TimeZone -Name "US Eastern Standard Time"


Write-Host "PS_Modules Script done!" -ForegroundColor Yellow

Stop-Transcript








