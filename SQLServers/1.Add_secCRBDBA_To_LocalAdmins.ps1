# Prompt for the AD group name
$ADGroupName = '<<domain>>\<<username>>'

# Define the local Administrators group
$LocalGroupName = "Administrators"

# Check if the AD group is already a member of the local Administrators
group
$groupExists = Get-LocalGroupMember -Group $LocalGroupName | Where-Object {
$_.Name -eq $ADGroupName }

if ($groupExists) {
    Write-Output "The AD group '$ADGroupName' is already a member of the
local Administrators group."
} else {
    try {
        # Add the AD group to the local Administrators group
        Add-LocalGroupMember -Group $LocalGroupName -Member $ADGroupName
        Write-Output "Successfully added '$ADGroupName' to the local
Administrators group."
    } catch {
        Write-Output "Failed to add '$ADGroupName' to the local
Administrators group. $_"
    }
}

