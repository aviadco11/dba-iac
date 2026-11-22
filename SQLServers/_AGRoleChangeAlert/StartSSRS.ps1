
 $ServerName = [Environment]::MachineName
Get-Service -computer $ServerName SQLServerReportingServices | Start-Service