
####Please create sql engine and Service Account in the domain prior to
running this script #####

cls
Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\4_0_SetSQLsvcaccts.txt

Set-ExecutionPolicy Unrestricted -Force

$SQLAccount = Read-Host "Enter ENGINE service account name without domain
(UK\) (ex: servacct001)"
$SQLPassword = Read-Host "Enter service account password, make sure it is
typed correctly"
Write-Host "SQL Service Account: " $SQLAccount -fore yellow

$AgentSQLSVCAccount = Read-Host "Enter AGENT service account name without
domain (UK\) (ex: servacct001)"
$AgentSQLPassword = Read-Host "Enter AGENT  service account password, make
sure it is typed correctly"
Write-Host "AGENT Service Account: " $AgentSQLSVCAccount -fore yellow

$SQLSVCDomain  = "<<domain>>"
$SQLSVCAccount = "<<domain>>\"+$SQLAccount
$SGGroup = "<<domain>>\<<username>>"
$AgentSVCAccount = "<<domain>>\"+$AgentSQLSVCAccount

<#
# Agent Set Service Account
#cls
$serviceName = Get-Service -Name "SQL*AGENT*"
#$serviceName.Name
#$serviceName = "SQL Server Agent (MSSQLSERVER)"
if (!($serviceName.Name)) { Write-Host "SQL Agent $serviceName does not
exist. Skipping Account Swap" -fore Yellow }
if (($serviceName.Name))  { Write-host  "Configuring SQL Agent Service"
"INFO"
sc.exe config $serviceName.Name `obj= $AgentSVCAccount  `password=
$AgentSQLPassword }
#>

############################################ Stop All SQL Services
##################################################
# Stop SQL Services
$serviceName = Get-Service -Name "MSSQL*"
if (!($serviceName)) { Write-Host "SQL Engine Service
($($serviceName.Name)) does not exist. Skipping Stopping Service" -fore
Green }
if (($serviceName))  { Get-Service -Name "MSSQL*" | Stop-Service -force
Write-Host "Stopped SQL Engine Service ($($serviceName.Name))" -fore
Magenta }

$serviceName = Get-Service -Name "MsDtsServer*"
if (!($serviceName)) { Write-Host "Integration Service
($($serviceName.Name)) does not exist. Skipping Stopping Service" -fore
Green }
if (($serviceName))  { Get-Service -Name "MsDtsServer*"| Stop-Service
Write-Host "Stopped Integration Service ($($serviceName.Name))" -fore
Magenta }

$serviceName = Get-Service -Name "MSSQLFDLauncher*"
if (!($serviceName)) { Write-Host "SQL Full Text Service
($($serviceName.Name)) does not exist. Skipping Stopping Service" -fore
Green }
if (($serviceName))  { Get-Service -Name "MSSQLFDLauncher*"| Stop-Service
Write-Host "Stopped SQL Full Text Service ($($serviceName.Name))" -fore
Magenta }

$serviceName = Get-Service -Name "MSSQLServerOLAPService*"
if (!($serviceName)) { Write-Host "SQL Analysis Service
($($serviceName.Name)) does not exist. Skipping Stopping Service" -fore
Green }
if (($serviceName))  { Get-Service -Name "MSSQLServerOLAPService*"|
Stop-Service
Write-Host "Stopped SQL Analysis Service ($($serviceName.Name))" -fore
Magenta }


Write-Host "..........................................................."
-fore Magenta
Write-Host "Setting the service accounts and passwords" -fore Yellow
Write-Host "..........................................................."
-fore Magenta



######################################################## Change Service
Accounts #########################################
# SSIS Set Service Account
$serviceName = Get-Service -Name "MsDtsServer*"
if (!($serviceName)) { Write-Host "SSIS Service $serviceName does not
exist. Skipping Account Swap" -fore Yellow }
if (($serviceName))  { Write-host "Configuring SQL Integration Service
SSIS" "INFO"
sc.exe config $serviceName obj= $SQLSVCAccount password= $SQLPassword}



# Full Text Set Service Account
$serviceName = Get-Service -Name "MSSQLFDLauncher*"
if (!($serviceName)) { Write-Host "Full Text $serviceName does not exist.
Skipping Account Swap" -fore Yellow }
if (($serviceName))  { Write-host  "Configuring SQL Full Text Service"
"INFO"
sc.exe config $serviceName obj= $SQLSVCAccount password= $SQLPassword}

# Analysis Service Set Service Account
$serviceName = Get-Service -Name "MSSQLServerOLAPService*"
if (!($serviceName)) { Write-Host "SSAS $serviceName does not exist.
Skipping Account Swap" -fore Yellow }
if (($serviceName))  { Write-host  "Configuring SQL Analysis Service" "INFO"
sc.exe config $serviceName obj= $SQLSVCAccount password= $SQLPassword}

# Agent Set Service Account
#cls
$serviceName = Get-Service -Name "SQL*AGENT*"
$serviceName[0]
#$serviceName = "SQL Server Agent (MSSQLSERVER)"
if (!($serviceName)) { Write-Host "SQL Agent $serviceName does not exist.
Skipping Account Swap" -fore Yellow }
if (($serviceName))  { Write-host  "Configuring SQL Agent Service" "INFO"
sc.exe config $serviceName obj= $AgentSVCAccount password=
$AgentSQLPassword}



#Change Service Account for Default Instance
$serviceName = get-service | where-object {$_.Name -eq 'MSSQLSERVER'}
if ($serviceName){
Write-host  "Configuring SQL DEFAULT Instance Engine Service" "INFO"
sc.exe config $serviceName obj= $SQLSVCAccount password= $SQLPassword}
if (!($serviceName)) { Write-Host "SQL Default Instance Engine $serviceName
does not exist." -fore Yellow }

#Change Service Account for Named Instance
$serviceName = get-service | where-object {$_.Name -like 'MSSQL$*'}
if ($serviceName){
Write-host  "Configuring SQL Named Instance Engine Service" "INFO"
sc.exe config $serviceName obj= $SQLSVCAccount password= $SQLPassword}
if (!($serviceName)) { Write-Host "SQL Named Instance Engine $serviceName
does not exist." -fore Yellow }



Write-Host "..........................................................."
-fore Magenta
Write-Host "Starting the services................" -fore Yellow
Write-Host "..........................................................."
-fore Magenta



############################################ Start SQL Services
################################################
# Start SQL Engine Services
$serviceName = Get-Service -Name "MSSQL*"
if (!($serviceName)) { Write-Host "$serviceName does not exist. Skipping
Service Start" -fore Red }
if (($serviceName))  { Write-host  "Starting services" "INFO"
Restart-Service "MSSQL*" -force
Write-Host "($($serviceName.Name)) Started" -fore Green }

# Start SQL Agent Services
$serviceName = Get-Service -Name "SQL*AGENT*"
if (!($serviceName)) { Write-Host "SQL Agent $serviceName does not exist.
Skipping Service Start" -fore Red }
if (($serviceName))  { Start-Service "SQL*AGENT*"
Write-Host "($($serviceName.Name)) Started" -fore Green}

# Start SQL Full Text Services
$serviceName = Get-Service -Name "MSSQLFDLauncher*"
if (!($serviceName)) { Write-Host "Full Text $serviceName does not exist.
Skipping Service Start" -fore Red }
if (($serviceName))  { Start-Service "MSSQLFDLauncher"
Write-Host "($($serviceName.Name)) Started" -fore Green}

# Start SQL Analysis Services
$serviceName = Get-Service -Name "MSSQLServerOLAPService*"
if (!($serviceName)) { Write-Host "SSAS $serviceName does not exist.
Skipping Service Start" -fore Red }
if (($serviceName))  { Start-Service "MSSQLServerOLAPService"
Write-Host "($($serviceName.Name)) Started" -fore Green}

# Start SQL Analysis Services
$serviceName = Get-Service -Name "MsDtsServer*"
if (!($serviceName)) { Write-Host "SSIS $serviceName does not exist.
Skipping Service Start" -fore Red }
if (($serviceName))  { Start-Service "MsDtsServer*"
Write-Host "($($serviceName.Name)) Started" -fore Green}

# Disable SQL Telemetry service

# Stop the service
Stop-Service -Name "SQLTELEMETRY"

# Disable the service
Set-Service -Name "SQLTELEMETRY" -StartupType Disabled


Write-Host "Set SQL svc Accounts done!" -ForegroundColor Yellow

Stop-Transcript