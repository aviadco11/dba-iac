cls
Write-host "######## Please uninstall SQL ami default install and the ODBC
17 driver( it breaks the new install for some reason) , to re-install to
our standard ######
# RUN THIS ONLY WHEN DEPLOYING A SQL AMI , SQL SERVER DEPLOYED AMI'S
ALREADY HAVE SQL AND SSMS INSTALLED BY DEFAULT"  -ForegroundColor Yellow


 $UserInput = Read-Host "Enter YES to proceed or any other value to quit"


    if ($UserInput -ne "yes") {
        Write-Host "  Exiting the script..." -ForegroundColor Yellow
        return}
     elseif ($UserInput -eq "yes") {
        Write-Host "  Proceeding with the script to install SQL Server:"
-ForegroundColor Green
         }


Start-Transcript -Append
c:\CRB\Bootstrap_Files\Win\2.2_SQL_SSMS_Install_ON_SQL_ami.txt

##Starting SQL Install
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

$media_path = "C:\SQLServerSetup\setup.exe"
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

Write-Host "SQL & SSMS Install done!" -ForegroundColor Yellow

Stop-Transcript