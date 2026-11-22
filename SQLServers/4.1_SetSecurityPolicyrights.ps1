Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\4_1_Set_secpol_log.txt

# Define the names of the services for SQL Server and SQL Server Agent
$sqlServiceName = "MSSQLSERVER"  # Replace with the instance name if it's not the default instance
$sqlAgentServiceName = "SQLSERVERAGENT"


 
# Define the security policy groups to which accounts should be added
$securityPolicies = @(
   "SeServiceLogonRight",  # Log on as a service
   "SeAssignPrimaryTokenPrivilege" ,  #  Replace a process-level token right
   "SeChangeNotifyPrivilege", #  Bypass traverse checking right
   "SeIncreaseQuotaPrivilege", # Adjust memory quotas for a process right
   "SeManageVolumePrivilege" # Perform volume maintenance tasks 
   "SeLockMemoryPrivilege"  # Lock Pages in memory  --- Added 10/15/2026
   
)
 
# Function to get the service account for a given service
function Get-ServiceAccount {
   param (
       [string]$serviceName
   )
 
   # Retrieve the service object
   $service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
 
   if ($null -eq $service) {
       Write-Error "Service '$serviceName' not found."
       return $null
   }
 
   return $service.StartName
}
 
# Function to add an account to a specific security policy
function Add-ToSecurityPolicy {
   param (
       [string]$account,
       [string]$policy
   )
 
   Write-Host "Adding $account to $policy..." -ForegroundColor Green
 
   # Backup the current security policy
   $backupFile = "$env:TEMP\SecurityPolicy.inf"
   $seceditResult = secedit /export /cfg $backupFile
 
   if ($LASTEXITCODE -ne 0) {
       Write-Error "Failed to export the current security policy."
       return
   }
 
   # Modify the policy file
   $policyFileContent = Get-Content $backupFile
   $policyLine = $policyFileContent | Where-Object { $_ -match "^$policy =" }
 
   if ($policyLine) {
       $updatedPolicyLine = $policyLine -replace "^(.*=)(.*)", "`$1 `$2,$account"
       $policyFileContent = $policyFileContent -replace [regex]::Escape($policyLine), $updatedPolicyLine
   } else {
       # Add the policy line if it does not exist
       $policyFileContent += "$policy = $account"
   }
 
   # Save the updated policy
   $updatedPolicyFile = "$env:TEMP\UpdatedSecurityPolicy.inf"
   $policyFileContent | Set-Content -Path $updatedPolicyFile -Encoding ASCII
 
   # Apply the updated policy
   $applyResult = secedit /configure /db secedit.sdb /cfg $updatedPolicyFile /areas USER_RIGHTS
 
   if ($LASTEXITCODE -eq 0) {
       Write-Host "$account successfully added to $policy." -ForegroundColor Cyan
   } else {
       Write-Error "Failed to apply the updated security policy for $policy."
   }
}
 
# Get the service accounts
$sqlServiceAccount = Get-ServiceAccount -serviceName $sqlServiceName
$sqlAgentAccount = Get-ServiceAccount -serviceName $sqlAgentServiceName
 
if ($null -ne $sqlServiceAccount -and $null -ne $sqlAgentAccount) {
   # Add each account to the defined security policies
   foreach ($policy in $securityPolicies) {
       Add-ToSecurityPolicy -account $sqlServiceAccount -policy $policy
       Add-ToSecurityPolicy -account $sqlAgentAccount -policy $policy
   }

 
   Write-Host "Security policy updates complete." -ForegroundColor Yellow
} else {
   Write-Error "Unable to retrieve service accounts. Ensure the service names are correct."
}
 


Write-Host "SecPol stuff done!" -ForegroundColor Yellow


Stop-Transcript