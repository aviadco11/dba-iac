Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\5_Set_Cluster_log.txt

 #Install-module failoverclusters
 Import-module FailoverClusters
 Import-Module SqlServer
 Install-WindowsFeature Telnet-Client

 sleep 2

cls



Write-Host "----RUN THIS CODE ON ONE NODE OF THE CLUSTER ONLY----"
-ForegroundColor Yellow

$ClusterName = Read-Host "Enter Cluster Name (ex: <<cluster_name>>)"
Write-Host "Cluster Name: " $ClusterName -fore yellow

$ClusterIP1 = Read-Host "Enter Cluster IP #1 of the new cluster  (ex:
<<ip_address>>)"
Write-Host "Cluster IP 1: " $ClusterIP1 -fore yellow

$ClusterIP2 = Read-Host "Enter Cluster IP #2 of the new cluster  (ex:
<<ip_address>>)"
Write-Host "Cluster IP 2: " $ClusterIP2 -fore yellow

$Clusternode1 = Read-Host "Enter Node 1 name (ex:<<servername>>)"
Write-Host  "Cluster Node 1: " $Clusternode1 -fore yellow

$Clusternode2 = Read-Host "Enter Node 2 name (ex:<<servername>>)"
Write-Host  "Cluster Node 2: " $Clusternode2 -fore yellow

$ClusterFileshare = Read-Host "Enter Cluster Fileshare Path (ex:
\\<<servername>>.<<domain>>\share)"
Write-Host "Cluster Fileshare Path: " $ClusterFileshare  -fore yellow

New-Cluster –Node $Clusternode1, $Clusternode2 -StaticAddress $ClusterIP1
,$ClusterIP2 -NoStorage -Name $ClusterName -AdministrativeAccessPoint
ActiveDirectoryAndDns
    # Cluster -StaticAddress <<ip_address>> ,<<ip_address>>

Set-ClusterQuorum -NodeAndFileShareMajority $ClusterFileshare

#Get-ClusterResource
#Get-Service winmgmt | Restart-Service -Force

 Enable-SqlAlwaysOn -ServerInstance $Clusternode1 -Force
 Enable-SqlAlwaysOn -ServerInstance $Clusternode2 -Force

#check the agent service and start it if it's down
#get-windowsfeature failover*
#Get-WindowsFeature RSAT-Cluster*

# Get system information by IP
# gwmi Win32_ComputerSystem -Computername <<ip_address>>

# Get system information by DNS
# gwmi Win32_ComputerSystem -Computername <<servername>>

Write-Host "Set Cluster $ClusterName  done!" -ForegroundColor Yellow


Stop-Transcript