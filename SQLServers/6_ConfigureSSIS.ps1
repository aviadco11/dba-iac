
Param (
        [Parameter(Mandatory)]
        $SQLSvcAcct = "<<domain>>\<<username>>",

        [Parameter(Mandatory)]
        $SQLSvcPW = "<<password>>",

        [Parameter(Mandatory)]
        $ISSvcAcct = "<<domain>>\<<username>>",


        [Parameter(Mandatory)]
        $ISSvcPW = "<<password>>",

        [Parameter(Mandatory)]
        $ISMSAcct = "<<domain>>\<<username>>",

        [Parameter(Mandatory)]
        $ISMSPW = "<<password>>",

        [Parameter(Mandatory)]
        $IsPrimary = 1,          #DEFAULT SERVER USED FOR CERTIFICATE
CREATION ONLY

        [Parameter(Mandatory)]
        $AGName = "AG-RSIS",

        [Parameter(Mandatory)]
        $AGListenName = "AWS-LS-RSIS-STG",

        [Parameter(Mandatory)]
        $SecondaryServer = "<<servername>>",

        [Parameter(Mandatory)]
        $Env = "STG",

        [Parameter(Mandatory)]
        $IsWorker = 1,

        [Parameter(Mandatory)]
        $PrimaryIP = "<<ip_address>>",

        [Parameter(Mandatory)]
        $SecondaryIP = "<<ip_address>>"



)

<#

#SQL SERVER ENGINE ACCOUNT
$SQLSvcAcct = "<<domain>>\<<username>>"
$SQLSvcPW = "<<password>>"

#INTEGRATION SERVICE ACCOUNT
$ISSvcAcct = "<<domain>>\<<username>>"
$ISSvcPW = "<<password>>"

#INTEGRATION MASTER SERVICE ACCOUNT
$ISMSAcct = "<<domain>>\<<username>>"
$ISMSPW = "<<password>>"
$IsPrimary = 1          #DEFAULT SERVER USED FOR CERTIFICATE CREATION ONLY
$AGName = "AG-RSIS"
$AGListenName = "AWS-LS-RSIS-STG"
$SecondaryServer = "<<servername>>"
$Env = "STG"
$IsWorker = 1
$PrimaryIP = '<<ip_address>>'
$SecondaryIP = '<<ip_address>>'

#>

#IMPORT MODULES
Import-module SqlServer
Import-module PKI
Import-module AWSPowershell

##GET MACHINE NAME
$MachineName = [Environment]::MachineName

$MachineName = [Environment]::MachineName
$InstanceName = get-sqlinstance -ServerInstance $MachineName

Write-Host $InstanceName
write-Host $MachineName

#GET IP ADDRESS
$ipAddy =
[System.Net.Dns]::GetHostAddresses($MachineName)[0].IPAddressToString;
Write-Host $ipAddy


#GET FULLY QUALIFIED DOMAIN NAME
$FQDN =[System.Net.Dns]::GetHostByName($MachineName).HostName
Write-Host $FQDN


#ENABLE ALWAYS ON
 Enable-SqlAlwaysOn -ServerInstance $MachineName -Force
# check the agent service and start it if it's down


#GET WINDOWS CLUSTER NAME
$Clustername = Get-Cluster

Write-Host "Windows Cluster name is: $Clustername"

#GET FULLY QUALIFIED CLUSTER NAME
$Clust= Get-ClusterResource | Where-Object ResourceType -eq 'Network Name'
| Select-Object  @{L='FQDN';E={if ($_.Name -match 'SQL Network Name')
{[System.Net.Dns]::GetHostByName($_.Name.TrimStart('SQL Network Name
(').TrimEnd(')')).HostName} else
{[System.Net.Dns]::GetHostByName($_.Cluster).Hostname}}}
$ClusterFQDN = $Clust | foreach { $_.FQDN} | Sort-Object -Unique

$ClustServiceName = -Join("AWS",$Env,"_IS_MS")

$ClustIps = -Join($PrimaryIP, ",", $SecondaryIP)

$FSXShare = Get-clusterresource -cluster $Clustername | where-object
{$_.ResourceType -like "File Share Witness"} | get-clusterparameter -Name
"sharepath" | Select Value

$FSxSharePath = $FSXShare | foreach {$_.Value}
Write-Host $FSxSharePath

<#
$searchFor =@(
    @{
        name = 'tag:clustername'
        values = "<<servername>>.<<domain>>"
    }
)
Get-EC2Instance -Filter $searchFor
#>



###############################################
#CREATE MASTER CERT FOLDER IF IT DOESN'T EXIST#
###############################################
$MasterCertpath = "C:\CRB\SSIS\MasterCert"
If(!(test-path -PathType container $MasterCertpath))
{
      New-Item -ItemType Directory -Path $MasterCertpath
}

$MasterCertName = "ssismastercert.pfx"
$MasterCert = -Join($MasterCertpath,"\",$MasterCertName)


Write-Host $MasterCert

#SET PASSWORD FOR CERT
$mypwd = ConvertTo-SecureString -String "<<password>>" -Force -AsPlainText

$Subject =  "CN=$ipAddy; CN=$FQDN"
Write-Host $Subject




If ($IsPrimary -eq 1)
{
    #CREATE SIGNED CERTIFICATE
    $cert = New-SelfSignedCertificate -Subject $Subject  -FriendlyName
"SSIS Master Cert" -CertStoreLocation "Cert:\LocalMachine\My" -NotAfter
(get-date).AddYears(8)
    $thumbprint = $cert | foreach { $_.Thumbprint}
    Write-host $thumbprint

    $thumbprint = $null
    $thumprint = "<<certificate_thumbprint>>"
    #EXPORT THE CERTIFICATE WE NEED IT FOR SECONDARY NODES
    Export-PfxCertificate -Cert "Cert:\LocalMachine\My\$thumbprint"
-FilePath $MasterCert -Password $mypwd
    #Export-PfxCertificate -Cert "Cert:\Local Computer\Trusted Root
Certification Athorities\Certificates\$thumbprint" -FilePath $MasterCert
-Password $mypwd

    Copy-Item -Path "$MasterCertpath\*" -Destination "$FSXSharePath\"
-Recurse

    # Load the IntegrationServices Assembly

[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices")
    # Store the IntegrationServices Assembly namespace to avoid typing it
every time
    $ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"

    Write-Host "Connecting to server ..."
    # Create a connection to the server
    $sqlConnectionString = -Join("Data Source=", $MachineName,";Initial
Catalog=master;Integrated Security=SSPI;")
    Write-Host $sqlConnectionString
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
$sqlConnectionString

    # Create the Integration Services object
    $integrationServices = New-Object $ISNamespace".IntegrationServices"
$sqlConnection

    # Provision a new SSIS Catalog
    $catalog = New-Object $ISNamespace".Catalog" ($integrationServices,
"SSISDB", "<<password>>")
    $catalog.Create()

    Detach-DbaDatabase -SqlInstance $MachineName -Database SSISDB

    $SSISDataFile = "C:\Program Files\Microsoft SQL
Server\MSSQL15.<<servername>>\MSSQL\DATA\SSISDB.mdf"
    Get-DbaDbDetachedFileInfo -SqlInstance $MachineName  -Path "C:\Program
Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\SSISDB.mdf"

    #####Move files from the AMI default location of C:\Program
Files\Microsoft SQL Server\MSSQL15.SQLPOC01\MSSQL\DATA\ , to
D:\MSSQL\DATA\.mdf &  L:\MSSQL\DATA\.ldf  ####

    Move-Item -Path "C:\Program Files\Microsoft SQL
Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\SSISDB.mdf" -Destination
D:\MSSQL\DATA\SSISDB.mdf
    Move-Item -Path "C:\Program Files\Microsoft SQL
Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\SSISDB.ldf" -Destination
L:\MSSQL\DATA\SSISDB.ldf

    $fileStructure = New-Object
System.Collections.Specialized.StringCollection
    $fileStructure.Add("D:\MSSQL\DATA\SSISDB.mdf")
    $filestructure.Add("L:\MSSQL\DATA\SSISDB.ldf")
    Mount-DbaDatabase -SqlInstance $MachineName  -Database SSISDB
-FileStructure $fileStructure

    Add-DbaAgDatabase -SqlInstance $MachineName -AvailabilityGroup $AGName
-Database SSISDB  -SeedingMode Automatic

}



If ($IsPrimary -ne 1)
{
    $MasterCertFSXPath = -Join($FSxSharePath,"\",$MasterCertName)
    Import-PfxCertificate -FilePath $MasterCertFSXPath -CertStoreLocation
"Cert:\LocalMachine\Root" -Password $mypwd

    $cert = Get-ChildItem -Path Cert:LocalMachine\MY | Select-Object
FriendlyName, Thumbprint, Subject, NotBefore, NotAfter | where
{$_.FriendlyName -eq "SSIS Master Service"}
    $thumbprint = $cert | foreach { $_.Thumbprint}

}


#INSTALL SSIS MASTER SERVICE
Write-Output "Starting SSIS Master Service Install $(Get-Date)"
$pathvargs = -join("/Q /IACCEPTSQLSERVERLICENSETERMS
/INDICATEPROGRESS=`"FALSE`" /ACTION=`"install`" /FEATURES=IS_MASTER
/INSTANCENAME=","`"",$InstanceName,"`" /SQLSVCACCOUNT= `"$SQLSvcAcct`"
/SQLSVCPASSWORD=`"$SQLSvcPW`" /ISSVCAccount= `"$ISSvcAcct`"
/ISSVCPASSWORD=`"$ISSvcPW`" /ISMASTERSVCACCOUNT='`"$ISMSAcct`"
/ISMASTERSVCPASSWORD= `"$ISMSPW`" /ISMASTERSVCPORT=`"8391`"
/ISMASTERSVCTHUMBPRINT= `"$thumbprint`" /ISSVCSTARTUPTYPE=`"Automatic`"
/USEMICROSOFTUPDATE=`"False`"", "")
Write-Host $pathvargs
$media_path =
"C:\CRB\Bootstrap_Files\Win\SQLServer2022-DEV-x64-ENU\setup.exe"
Start-Process -FilePath $media_path -ArgumentList $pathvargs  -Wait



# run on both primary nodes
$MSConfigpath = "C:\Program Files\Microsoft SQL
Server\160\DTS\Binn\MasterSettings.config"
$MSConfigold = "C:\Program Files\Microsoft SQL
Server\160\DTS\Binn\MasterSettingsOLD.config"

If ($IsPrimary -eq 1) {
    Copy-Item -Path "$MSConfigpath" -Destination "$FSXSharePath\" -Recurse

    $Config = -Join($AGListenName,",1433")
    Write-Host $AgListenerName
    Copy-Item -Path $MSConfigpath -Destination $MSConfigold
    (Get-Content $MSConfigPath -Raw) -Replace "`".`"", "`"$config`"" |
Set-Content $MSConfigPath
    Stop-Service -Name "SSISScaleOutMaster160"
    Start-Service -Name "SSISScaleOutMaster160"
}


If ($IsPrimary -ne 1) {
    $BinnDir = "C:\Program Files\Microsoft SQL Server\160\DTS\Binn"
    $MasterConfigNew = -Join($FSXSharePath, "\MasterSettings.config")
    Copy-Item $MasterConfigNew -Destination $BinnDir -Force
    Stop-Service -Name "SSISScaleOutMaster160"
    Start-Service -Name "SSISScaleOutMaster160"


}

<#  SHOUULD'T NEED TO DO THIS
$query0 = "ALTER LOGIN ##MS_SSISLogDBWorkerAgentLogin##
WITH PASSWORD = '<<password>>'
"

Invoke-Sqlcmd -server $MachineName -database master -Query $query0

$query1 = "SELECT Sid FROM syslogins WHERE
name='##MS_SSISLogDBWorkerAgentLogin##'"
$sid = Invoke-Sqlcmd -server $MachineName -database master -Query $query1 |
select -ExpandProperty Sid
$hexSid = ($sid|ForEach-Object ToString X2) -join ''
$password = ConvertTo-SecureString "<<password>>" -AsPlainText -Force
New-DbaLogin -SqlInstance $MachineName -Login
"##MS_SSISLogDBWorkerAgentLogin##" -Sid $hexSid -SecurePassword $password
#>


#ADD SSIS Service account to the ssis_cluster_worker role
$query0 = -Join("CREATE USER [", $ISSvcAcct, "] FOR LOGIN [",$ISSvcAcct,"];
ALTER ROLE [ssis_cluster_worker] ADD MEMBER [", $ISSvcAcct,"];")
Invoke-Sqlcmd -Server $machinename -Database "SSISDB" -Query $query0
-TrustServerCertificate


#UPDATE LOGGING INFORMATION
$connString = -Join ('Data Source=',$MachineName, ';Initial
Catalog=SSISDB;Integrated Security=SSPI;')
$query1 = -Join("EXEC [internal].[update_logdb_info]", "'",$MachineName,
"'", ",'",$connString,"'")
Invoke-Sqlcmd -server $MachineName -database "SSISDB" -query $query1
-TrustServerCertificate

If ($IsPrimary -eq 1)
{
    #Copy-DbaLogin -Source $MachineName -Destination $SecondaryServer
-Login

    Add-ClusterGenericServiceRole -ServiceName 'SSISScaleOutMaster160'
-Name $ClustServiceName -Cluster $ClusterFQDN -StaticAddress
'<<ip_address>>,<<ip_address>>' #$ClustIps

    #UPDATE MASTER ADDRESS
    $query3 = -Join("EXEC [catalog].[update_master_address] @MasterAddress
= N'https://", $ClusterFQDN, ":8391'")
    Invoke-Sqlcmd -server $AGListenName -database SSISDB -Query $query
-TrustServerCertificate

    #ENABLE SCALEOUT
    $query4 = “EXEC catalog.enable_scaleout”
    Invoke-Sqlcmd -server $AGListenName -database SSISDB -Query $query
-TrustServerCertificate

}


##WORKER Installation
$fsxshare = "\\<<servername>>.<<domain>>\share"
$MasterCertPath = -Join($fsxshare, "\ssismastercert.pfx")

Write-Host $MasterCertPath

#### copyyy sql installation folder from primary sql nodes to ssis scale
out workers #####################

 $mypwd = ConvertTo-SecureString -String "<<password>>" -Force -AsPlainText
Import-PfxCertificate -FilePath $MasterCertPath -CertStoreLocation
"Cert:\LocalMachine\Root" -Password $mypwd


#INSTALL SSIS WORKER SERVICE
Write-Output "Starting SSIS WORKER Service Install $(Get-Date)"
$pathvargs = -join("/Q /ACTION=Install /SUPPRESSPRIVACYSTATEMENTNOTICE
/IACCEPTSQLSERVERLICENSETERMS /FEATURES=`“IS_WORKER`” /ENU=`“True`”
/INDICATEPROGRESS=`“True`” /X86=`"False`" /ISSVCAccount= `"$ISSvcAcct`"
/ISSVCPASSWORD=`"$ISSvcPW`" /ISWORKERSVCSTARTUPTYPE=`"Automatic`"
/ISWORKERSVCACCOUNT=`"$ISSvcAcct`" /ISWORKERSVCPASSWORD=`"$ISMSPW`"")
Write-Host $pathvargs
$media_path =
"C:\CRB\Bootstrap_Files\Win\SQLServer2022-DEV-x64-ENU\setup.exe"
Start-Process -FilePath $media_path -ArgumentList $pathvargs  -Wait



#### copy generated cert to the masters 01 + 02
 $path = "C:\Program Files\Microsoft SQL
Server\160\DTS\Binn\SSISScaleOutWorker.cer"
 $dest = -Join($fsxshare, "\workercert01.cer")
 Copy-Item -Path $path -Destination $dest
 $path = "C:\Program Files\Microsoft SQL
Server\160\DTS\Binn\SSISScaleOutWorker.cer"
 $dest = -Join($fsxshare, "\workercert02.cer”)
 Copy-Item -Path $path -Destination $dest

$worker1 = -Join($fsxshare,"\workercert01.cer")
$worker2 = -Join($fsxshare,"\workercert02.cer")
###in 01
Import-Certificate -FilePath $worker1 -CertStoreLocation
"Cert:\LocalMachine\Root"
###in 02
Import-Certificate -FilePath $worker2 -CertStoreLocation
"Cert:\LocalMachine\Root"


 $path = "C:\Program Files\Microsoft SQL
Server\150\DTS\Binn\SSISScaleOutWorker.cer"
 $dest = “\\<<servername>>\c$\workercert02.cer”
 Copy-Item -Path $path -Destination $dest
 $path = “C:\Program Files\Microsoft SQL
Server\150\DTS\Binn\SSISScaleOutWorker.cer”
 $dest = “\\<<servername>>\c$\workercert02.cer”
 Copy-Item -Path $path -Destination $dest

###in 01 Import-Certificate -FilePath "c:\\workercert02.cer”
-CertStoreLocation "Cert:\LocalMachine\Root"
###in 02 Import-Certificate -FilePath "c:\\workercert02.cer”
-CertStoreLocation "Cert:\LocalMachine\Root"

