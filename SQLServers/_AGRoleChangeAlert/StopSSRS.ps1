
 $ServerName = [Environment]::MachineName
Get-Service -computer $ServerName SQLServerReportingServices | Stop-Service





