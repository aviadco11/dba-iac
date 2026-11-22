Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\4_RenameComputerLog.txt

Import-Module AWSPowerShell
$instanceId = Get-EC2InstanceMetadata -Category InstanceId
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "Host_Name_Status"

function getStatusTag() {
    $tag = Get-EC2Tag -Filter @{Name="resource-id";Values=$instanceId} |
Where-Object Key -eq "Host_Name_Status" | select -ExpandProperty Value
    return $tag
}

function setStatusTag($status) {
    $tag.Value = $status
    New-EC2Tag -Resource $instanceId -Tag $tag
}

function RenameComputer {
    # Script parameters
    $SecretAD = "ad_join_secret"

    Write-Host("------------------------------")
    $RunUser = $env:username
    Write-Host("PowerShell session user: $RunUser")

    # Fetch tags from AWS
    $newComputerName= Get-EC2Tag -Filter
@{Name="resource-id";Values=$instanceId} | Where-Object Key -eq "Name" |
select -ExpandProperty Value
    $initialOUTag = Get-EC2Tag -Filter
@{Name="resource-id";Values=$instanceId} | Where-Object Key -eq "InitialOU"
| select -ExpandProperty Value


    # Setting Hostname
        #Duplicate of line 61
        #$newComputerName = $nameTag
      Write-Host("Changing Hostname to " + $newComputerName )
      Rename-Computer -NewName $newComputerName -Force

<#
    # Getting AD user secret
    Write-Output "Getting Secrets info $(Get-Date)"
    Write-Host("Loading Secret <" + $SecretAD + ">")
    try { $SecretObj = (Get-SECSecretValue -SecretId $SecretAD) }
    catch {
        Write-Host("Could not load secret <" + $SecretAD + "> - terminating
execution")
        return
    }
    [PSCustomObject]$Secret = ($SecretObj.SecretString  | ConvertFrom-Json)
    Write-Host("Domain (from Secret): <" + $Secret.Domain + ">")


    # Settings AWS DCs as DNS servers
    #Write-Host("Setting AWS DCs as DNS servers")
    #$interfaceIndex = Get-NetAdapter -Name * | select -ExpandProperty
InterfaceIndex | Select-Object -First 1
    #Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex
-ServerAddresses ("<<ip_address>>","<<ip_address>>")

    # Performing Domain Join
    Write-Output "Performing Domain Join $(Get-Date)"
    setStatusTag("Joining Domain")
    Write-Host("Domain Join - Domain: <" + $Secret.Domain + ">")
    $password = $Secret.Password | ConvertTo-SecureString -asPlainText
-Force
    $username = $Secret.UserID + "@" + $Secret.Domain
    $credential = New-Object
System.Management.Automation.PSCredential($username, $password)
    Write-Host("Attempting to join domain <" + $Secret.Domain + ">")
    try {
        Add-Computer -NewName $newComputerName -OUPath $initialOUTag
-DomainName $Secret.Domain -Credential $credential -Passthru  #-Restart
-Force
        #Add-Computer -OUPath $initialOUTag -DomainName $Secret.Domain
-Credential $credential #-Restart -Force
    }
    catch {
        Add-Computer -NewName $newComputerName -OUPath $initialOUTag
-DomainName $Secret.Domain -Credential $credential -Passthru #-Restart
-Force
        "Attempting rename once more from access denied error in first pass"
    }
    Finally {
        setStatusTag("Domain Join Complete")
    }
#>
   Write-Host("Requesting restart...")
   Restart-Computer -Force


#------------------------------------------------------------------------------

}

Write-Output "Executing Rename computer function  $(Get-Date)"
RenameComputer


Stop-Transcript