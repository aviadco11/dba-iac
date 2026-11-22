
###requires SQLServerReportingServices.exe installer file , usually
included in the terraform project , located at
C:\CRB\Bootstrap_Files\Win\SQLServer2022-DEV-x64-ENU
###
https://businesswintelligence.com/content/12/reporting-services-automatic-install

$setup_path =
"C:\CRB\Bootstrap_Files\Win\SQLServer2022-DEV-x64-ENU\SQLServerReportingServices.exe"

$installArgs = ""
$installArgs += " /passive"
$installArgs += " /log C:\CRB\Bootstrap_Files\Win\ssrs-install-log.txt"
$installArgs += " /InstallFolder=`"C:\Program Files\Microsoft SQL Server
Reporting Services`""
$installArgs += " /IAcceptLicenseTerms"
#$installArgs += " /PID=XXXX-XXXX-XXXX-XXXX"

Start-Process -FilePath $setup_path -ArgumentList $installArgs -Wait

##Restart host once install finishes ( -wait above ensures Start-process
will finish )
Restart-Computer
