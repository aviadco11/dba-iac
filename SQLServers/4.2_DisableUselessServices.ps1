# Define the service name
$ServiceName = "SQLWriter"

#SQLWriter
#SQLBrowser
#SQLTELEMETRY

# Check if the service exists
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($Service) {
    # Stop the service if it's running
    if ($Service.Status -eq "Running") {
        Stop-Service -Name $ServiceName -Force
        Write-Host "Service $ServiceName stopped."
    }

    # Disable the service
    Set-Service -Name $ServiceName -StartupType Disabled
    cls
    Write-Host "Service $ServiceName is now disabled."
} else {
    cls
    Write-Host "Service $ServiceName not found."
}

$ServiceName1 = "SQLBrowser"

# Define the service name
$ServiceName = "SQLBrowser"

#SQLWriter
#SQLBrowser
#SQLTELEMETRY

# Check if the service exists
$Service = Get-Service -Name $ServiceName1 -ErrorAction SilentlyContinue

if ($Service) {
    # Stop the service if it's running
    if ($Service.Status -eq "Running") {
        Stop-Service -Name $ServiceName1 -Force
        Write-Host "Service $ServiceName1 stopped."
    }

    # Disable the service
    Set-Service -Name $ServiceName1 -StartupType Disabled

    Write-Host "Service $ServiceName1 is now disabled."
} else {

    Write-Host "Service $ServiceName1 not found."
}


$ServiceName2 = "SQLTELEMETRY"

# Check if the service exists
$Service = Get-Service -Name $ServiceName2 -ErrorAction SilentlyContinue

if ($Service) {
    # Stop the service if it's running
    if ($Service.Status -eq "Running") {
        Stop-Service -Name $ServiceName2 -Force
        Write-Host "Service $ServiceName2 stopped."
    }

    # Disable the service
    Set-Service -Name $ServiceName2 -StartupType Disabled

    Write-Host "Service $ServiceName2 is now disabled."
} else {

    Write-Host "Service $ServiceName2 not found."
}
