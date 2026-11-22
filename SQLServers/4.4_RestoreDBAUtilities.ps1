Start-Transcript -Append
c:\CRB\Bootstrap_Files\Win\4_4_Restore_DBAUTILITIES_log.txt

Invoke-Sqlcmd -ServerInstance $Env:COMPUTERNAME -Query "USE [master]
RESTORE DATABASE [DBAUtilities] FROM  DISK =
N'C:\CRB\Bootstrap_Files\Win\DBAUtilities\DBAUtilities_FB.bak' WITH  FILE =
1
,  MOVE N'DBAUtilities_log' TO N'L:\MSSQL\DATA\DBAUtilities_log.ldf'
,  NOUNLOAD
,  STATS = 5

GO"

Invoke-Sqlcmd -ServerInstance $Env:COMPUTERNAME -Query "USE [DBAUtilities]
GO
ALTER AUTHORIZATION ON DATABASE::[DBAUtilities] TO [<<username>>]
GO"

Invoke-Sqlcmd -ServerInstance $Env:COMPUTERNAME -Query "USE [master]
GO
ALTER DATABASE [DBAUtilities] SET COMPATIBILITY_LEVEL = 160

GO"


Write-Host "Restore DBAUtilities done!" -ForegroundColor Yellow

Stop-Transcript

