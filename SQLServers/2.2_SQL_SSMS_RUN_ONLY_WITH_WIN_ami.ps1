# RUN THIS ONLY WHEN DEPLOYING A WINDOWS AMI , SQL SERVER DEPLOYED AMI'S
ALREADY HAVE SQL AND SSMS INSTALLED BY DEFAULT

Start-Transcript -Append
c:\CRB\Bootstrap_Files\Win\2.2_SQL_SSMS_Install_ON_WIN_ami.txt

Function GenerateStrongPassword
([Parameter(Mandatory=$true)][int]$PasswordLength)
{
Add-Type -AssemblyName System.Web
$PassComplexCheck = $false
do {
$newPassword=[System.Web.Security.Membership]::GeneratePassword($PasswordLength,1)
If ( ($newPassword -cmatch "[A-Z\p{Lu}\s]") `
-and ($newPassword -cmatch "[a-z\p{Ll}\s]") `
-and ($newPassword -match "[\d]") `
-and ($newPassword -match "[^\w]")
)
{
$PassComplexCheck=$True
}
} While ($PassComplexCheck -eq $false)
return $newPassword
}

$newpw = GenerateStrongPassword -PasswordLength 16
#$newpw = -Join(",$newpw,")

##Starting SQL Install
Write-Output "Starting SQL Install $(Get-Date)"
$LocalAdmin = "/SQLSYSADMINACCOUNTS=`"<<domain>>\<<username>>`""

$media_path =
"C:\CRB\Bootstrap_Files\Win\SQLServer2022-DEV-x64-ENU\setup.exe"
$pathvargs  = ' /Q /ACTION=Install  /SUPPRESSPRIVACYSTATEMENTNOTICE
/IACCEPTSQLSERVERLICENSETERMS /FEATURES=SQLENGINE /UpdateEnabled=True
/UpdateSource="C:\CRB\Bootstrap_Files\Win\cu17" /INSTANCENAME=MSSQLSERVER
/INSTANCEDIR="D:\MSSQL" /SAPWD="'
$pathvargs2 = '" /SQLBACKUPDIR="D:\MSSQL\BACKUP"
/SQLTEMPDBDIR="T:\MSSQL\TEMP" /SQLUSERDBLOGDIR="L:\MSSQL\DATA"
/SQLUSERDBDIR="D:\MSSQL\DATA" /SECURITYMODE="SQL"
/SQLSVCSTARTUPTYPE="Automatic" '
$pathvargs3 =  $LocalAdmin
$pathvargs4 = ' /AGTSVCSTARTUPTYPE="Automatic"
/BROWSERSVCSTARTUPTYPE="Automatic" /TCPENABLED="1" /NPENABLED="1"'
$Command =  $pathvargs + $newpw +  $pathvargs2 + $pathvargs3 + $pathvargs4


Start-Process -FilePath $media_path  -ArgumentList $Command  -Wait

##End SQL Install



##STart SSMS Install
Write-Output "Starting SSMS Install $(Get-Date)"
Start-Process -FilePath
"C:\CRB\Bootstrap_Files\Win\SQLServer2022-DEV-x64-ENU\SSMS-Setup-ENU.exe"
 -ArgumentList  /Quiet -Wait
##End SSMS Install


Write-Host "Sql and SSMS Install done!" -ForegroundColor Yellow

Stop-Transcript