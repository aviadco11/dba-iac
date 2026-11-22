
Import-Module FailoverClusters


$ClustServiceName = 'SQLRSSvc'
$ClusterFQDN = '<<servername>>.<<domain>>'

Add-ClusterGenericServiceRole  -ServiceName 'SQLServerReportingServices'
-Name $ClustServiceName -Cluster $ClusterFQDN -StaticAddress
<<ip_address>>,<<ip_address>> #$ClustIps


Move-ClusterResource -Name SQLServerReportingSvc -Group AG-RSIS

Move-ClusterResource -Name SQLServerReportingSvc -Group 'Cluster Group'



Get-ClusterGroup