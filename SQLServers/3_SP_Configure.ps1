Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\3_SP_ConfigureLog.txt

Write-Output "Setting sp_configure options $(Get-Date)"
Invoke-Sqlcmd -ServerInstance  $Env:COMPUTERNAME -Query "use Master ;
exec sp_configure 'show advanced options' , 1
reconfigure;
exec sp_configure 'Database Mail XPs' , 1
reconfigure;
exec sp_configure 'Ad Hoc Distributed Queries' , 1
reconfigure;
exec sp_configure 'remote access' , 1
reconfigure;
exec sp_configure 'xp_cmdshell' , 1
reconfigure;
exec sp_configure 'clr enabled', 1
reconfigure;
exec sp_configure 'clr strict security' ,1
reconfigure;
exec sp_configure 'Agent XPs' , 1
reconfigure;
exec sp_configure 'max degree of parallelism' ,2
reconfigure;
exec sp_configure 'cost threshold for parallelism' , 25
reconfigure;
exec sys.sp_configure N'backup compression default', N'1'
go"

Write-Output "Renaming and disabling sa account $(Get-Date)"

Invoke-Sqlcmd -ServerInstance $Env:COMPUTERNAME -Query "use Master; ALTER
LOGIN [sa] WITH NAME = [<<username>>]
ALTER LOGIN [<<username>>] DISABLE
GO"


Invoke-Sqlcmd -ServerInstance $Env:COMPUTERNAME -Query "USE [master]
GO
if not exists(select * from sys.server_principals where
name='<<domain>>\<<username>>')
begin
CREATE LOGIN [<<domain>>\<<username>>] FROM WINDOWS WITH
DEFAULT_DATABASE=[master]
end
ALTER SERVER ROLE [sysadmin] ADD MEMBER [<<domain>>\<<username>>]
GO
USE [master]
GO
if not exists(select * from sys.server_principals where
name='<<domain>>\<<username>>')
begin
CREATE LOGIN [<<domain>>\<<username>>] FROM WINDOWS WITH
DEFAULT_DATABASE=[master]
end
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [<<domain>>\<<username>>]
GO"


# Define variables
$MachineName = $Env:COMPUTERNAME
#$MachineName
$serverInstance = $MachineName  # Replace with your SQL Server instance name
#$serverInstance

$threshold = 32                              # Threshold in GB
$reserveSmall = 8                            # Reserved memory for OS if <=
32 GB
$reserveLarge = 16                           # Reserved memory for OS if >
32 GB

# Get the total server memory (in GB)
$totalMemoryGB = [Math]::Round((Get-WmiObject -Class
Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
#$totalMemoryGB = 32

# Calculate memory to allocate to SQL Server
if ($totalMemoryGB -le $threshold) {
    $sqlMemory = $totalMemoryGB - $reserveSmall
   #Write-host $sqlMemory 'GB is the sql memory value'
} elseif ($totalMemoryGB -gt 32 -and $totalMemoryGB -le 64){
    $sqlMemory = [Math]::Round((.75 * $totalMemoryGB))
   Write-host $sqlMemory 'GB is the sql memory value, which represents 75%
of total memory between 32-64 gb ' -fore yellow
   }
  elseif ($totalMemoryGB -gt 64){
  $sqlmemory = $totalMemoryGB - $reserveLarge
}

# Ensure the memory allocation is not negative
if ($sqlMemory -lt 0) {
    Write-Error "Calculated SQL Server memory is less than 0 GB. Check your
configuration."
    exit
}

# Command to set max server memory
$sqlCommand = @"
EXEC sys.sp_configure 'max server memory (MB)', $($sqlMemory * 1024);
RECONFIGURE;
"@

# Execute the command
# sqlcmd -S $serverInstance -Q $sqlCommand

# Execute the command
Invoke-Sqlcmd -ServerInstance $serverInstance  $sqlCommand

# Output the configuration
Write-Host "Total Memory: $totalMemoryGB GB" -fore cyan
Write-Host "SQL Server Allocated Memory: $sqlMemory GB" -fore Yellow
Write-Host "Command executed successfully."

Write-Host "SP_Configure and other settings done!" -ForegroundColor Yellow

Stop-Transcript