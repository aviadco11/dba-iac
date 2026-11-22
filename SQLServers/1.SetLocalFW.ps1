
Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\1_setLocalFWLog.txt

Import-Module AWSPowerShell

$instanceId = Get-EC2InstanceMetadata -Category InstanceId
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "LocalFWrules"

function setStatusTag($status) {
    $tag.Value = $status
    New-EC2Tag -Resource $instanceId -Tag $tag
}

#Enable SQL Server Ports
Write-Output "Enabling Local FW ports $(Get-Date)"
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol
TCP -LocalPort 1433 -Action allow
New-NetFirewallRule -DisplayName "SQL Admin Connection" -Direction Inbound
-Protocol TCP -LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName "SQL Database Management" -Direction
Inbound -Protocol UDP -LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName "SQL Service Broker" -Direction Inbound
-Protocol TCP -LocalPort 4022 -Action allow
New-NetFirewallRule -DisplayName "SQL Debugger/RPC" -Direction Inbound
-Protocol TCP -LocalPort 135 -Action allow
 #Enable Windows Clustering ports
New-NetFirewallRule -DisplayName "Cluster Admin" -Direction Inbound
-Protocol TCP -LocalPort 137 -Action allow
New-NetFirewallRule -DisplayName "Cluster Service" -Direction Inbound
-Protocol TCP -LocalPort 3343 -Action allow
New-NetFirewallRule -DisplayName "Cluster Service" -Direction Inbound
-Protocol UDP -LocalPort 3343 -Action allow
New-NetFirewallRule -DisplayName "High Ports" -Direction Inbound -Protocol
UDP -LocalPort 49152-65535 -Action allow
New-NetFirewallRule -DisplayName "High Ports" -Direction Inbound -Protocol
UDP -LocalPort 1024-65535 -Action allow
New-NetFirewallRule -DisplayName "SMB" -Direction Inbound -Protocol TCP
-LocalPort 445 -Action allow
#Enable SSIS ScaleOut Port
New-NetFirewallRule -DisplayName "SQL SSIS Scale Out TCP" -Direction
Inbound -Protocol TCP -LocalPort 8391 -Action allow
New-NetFirewallRule -DisplayName "SQL SSIS Scale Out UDP" -Direction
Inbound -Protocol UDP -LocalPort 8391 -Action allow
#Enable HADR and Endpoint ports for AG configs
New-NetFirewallRule -DisplayName "SQL Cluster HA" -Direction Inbound
-Protocol UDP -LocalPort 3343 -Action allow
New-NetFirewallRule -DisplayName "SQL AG EndPoint" -Direction Inbound
-Protocol TCP -LocalPort 5022 -Action allow
#Enabling related Applications , SSRS Mail port, and https
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP
-LocalPort 80 -Action allow
New-NetFirewallRule -DisplayName "SQL Server Browse Button Service"
-Direction Inbound -Protocol UDP -LocalPort 1433 -Action allow
New-NetFirewallRule -DisplayName "SSL" -Direction Inbound -Protocol TCP
-LocalPort 443 -Action allow #Enable SQL Analysis Ports
New-NetFirewallRule -DisplayName "SQL Analysis Services" -Direction Inbound
-Protocol TCP -LocalPort 2383 -Action allow
New-NetFirewallRule -DisplayName "SQL Browser" -Direction Inbound -Protocol
TCP -LocalPort 2382 -Action allow
#Enable Windows Firewall
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction
Allow -NotifyOnListen True -AllowUnicastResponseToMulticast True
Write-Host "Local FW done!" -ForegroundColor Yellow

setStatusTag("Local Firewall Rules set")


Stop-Transcript