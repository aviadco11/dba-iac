Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\4_2_Set_Drive_Perms.txt

# Define the names of the services for SQL Server and SQL Server Agent
$sqlServiceName = "MSSQLSERVER"  # Replace with the instance name if it's
not the default instance
$sqlAgentServiceName = "SQLSERVERAGENT"

# Function to get the service account for a given service
function Get-ServiceAccount {
   param (
       [string]$serviceName
   )

   # Retrieve the service object
   $service = Get-WmiObject -Class Win32_Service -Filter
"Name='$serviceName'"

   if ($null -eq $service) {
       Write-Error "Service '$serviceName' not found."
       return $null
   }

   return $service.StartName
}


# Get the service accounts
$sqlServiceAccount = Get-ServiceAccount -serviceName $sqlServiceName
$sqlAgentAccount = Get-ServiceAccount -serviceName $sqlAgentServiceName

#$sqlServiceName
#$sqlAgentServiceName

# Define the accounts (replace these with actual SQL Server Engine/Service
accounts)
$sqlEngineAccount = $sqlServiceAccount
$sqlAgentAccount = $sqlAgentAccount

$sqlEngineAccount
$sqlAgentAccount

# Define the paths
$paths = @("D:\", "L:\", "T:\", "C:\Program Files\Microsoft SQL Server")


# Loop through paths and set permissions
#foreach ($path in $paths) {
#      Write-Host "Granting permissions on: $path" -ForegroundColor Green
#    $acl = Get-Acl $path
#    $rule1 = New-Object
System.Security.AccessControl.FileSystemAccessRule($sqlEngineAccount,
"FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
#    $rule2 = New-Object
System.Security.AccessControl.FileSystemAccessRule($sqlAgentAccount,
"FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
#    $acl.AddAccessRule($rule1)
#    $acl.AddAccessRule($rule2)
#    Set-Acl -Path $path -AclObject $acl
#}

# Initialize counter for progress bar
$totalPaths = $paths.Count
$currentPath = 0

foreach ($path in $paths) {
    $currentPath++
    Write-Progress -Activity "Setting Permissions" -Status "Processing
$path ($currentPath of $totalPaths)" -PercentComplete (($currentPath /
$totalPaths) * 100)

    try {
        Write-Host "Processing $path..." -ForegroundColor Green
        $acl = Get-Acl $path
        $rule1 = New-Object
System.Security.AccessControl.FileSystemAccessRule($sqlEngineAccount,
"FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $rule2 = New-Object
System.Security.AccessControl.FileSystemAccessRule($sqlAgentAccount,
"FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($rule1)
        $acl.AddAccessRule($rule2)
        Set-Acl -Path $path -AclObject $acl
        Write-Host "Successfully set permissions for $sqlEngineAccount &
$sqlAgentAccount for $path" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to set permissions for ${$path}: $_"
-ForegroundColor Red
    }
}


Write-Host "Drive Permissions done!" -ForegroundColor Yellow

Stop-Transcript