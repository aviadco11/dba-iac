<#
.SYNOPSIS
    Installs Elastic Beats Windows service (Filebeat, Winlogbeat,
Metricbeat, etc.).

.DESCRIPTION
    Generic installer for any Elastic Beat Windows service. Handles:
    - Service installation with proper paths
    - Legacy data path migration (C:\ProgramData -> C:\Program
Files\<Beat>-Data)
    - Service restart and validation
    - Remote execution support via absolute paths

    For Beats < 8.19.3 the data path was 'C:\ProgramData\<Beat>'
    For Beats >= 8.19.3 the default is 'C:\Program Files\<Beat>-Data'

    If the legacy data path exists, it will be automatically migrated.

.PARAMETER BeatType
    Type of beat: filebeat, winlogbeat, metricbeat, etc.

.PARAMETER Version
    Beat version (e.g., 8.19.11, 9.3.5)

.PARAMETER ForceLegacyPath
    Force usage of legacy data path (C:\ProgramData\<Beat>)

.EXAMPLE
    .\install-service-beat.ps1 -BeatType filebeat -Version 8.19.11

.EXAMPLE
    .\install-service-beat.ps1 -BeatType winlogbeat -Version 9.3.5

.NOTES
    Designed for remote execution via Invoke-Command.
    Uses absolute paths compatible with remote PowerShell sessions.
#>

Param (
    [Parameter(
        Position = 0,
        Mandatory = $true,
        HelpMessage = "Beat type (filebeat, filebeat2, winlogbeat,
metricbeat)"
    )]
    [ValidateSet('filebeat', 'filebeat2', 'winlogbeat', 'metricbeat')]
    [String]$BeatType,

    [Parameter(
        Position = 1,
        Mandatory = $true,
        HelpMessage = "Beat version (e.g., 8.19.11)"
    )]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [String]$Version,

    [Parameter(Mandatory = $false)]
    [switch]$ForceLegacyPath
)

$ErrorActionPreference = "Stop"

# Capitalize first letter for display name and paths
$BeatName = (Get-Culture).TextInfo.ToTitleCase($BeatType)

Write-Host "Installing $BeatName service (version $Version)..."
-ForegroundColor Cyan

# Stop the existing service - but do NOT delete it yet.
# The data migration below needs the beat to release its registry files, so
stopping is
# required. Deleting is not, and deleting FIRST is what once left a server
with no filebeat
# service at all: the migration threw, so New-Service was never reached,
and the next run
# could no longer detect the beat or find its old config. The delete is
deferred to just
# before New-Service, so any failure up to that point leaves the OLD
service registered
# (stopped) - detectable, re-runnable, and startable by hand.
$svcExisted = $false
if (Get-Service $BeatType -ErrorAction SilentlyContinue) {
    $svcExisted = $true
    Write-Host "Stopping existing $BeatType service..."
    Stop-Service $BeatType -Force
    (Get-Service $BeatType).WaitForStatus('Stopped', '00:00:15')
    Start-Sleep -Seconds 1
}

# Path configuration
if ($BeatType -eq 'filebeat2') {
    # Filebeat2 nested under filebeat2\ directory
    $WorkDir = "C:\Program
Files\Elastic\Beats\filebeat2\filebeat-$Version-windows-x86_64"
} else {
    $WorkDir = "C:\Program
Files\Elastic\Beats\$BeatType-$Version-windows-x86_64"
}

$BasePath = "$env:ProgramFiles\$BeatName-Data"
$LegacyDataPath = "$env:PROGRAMDATA\$BeatName"

# Validate WorkDir exists
if (!(Test-Path $WorkDir)) {
    throw "Beat installation directory not found: $WorkDir. Ensure the beat
was extracted correctly."
}

# Validate beat executable exists (now all beats use $BeatType.exe
including filebeat2.exe)
$BeatExe = "$WorkDir\$BeatType.exe"
if (!(Test-Path $BeatExe)) {
    throw "Beat executable not found: $BeatExe"
}

# Validate beat config exists
$BeatConfig = "$WorkDir\$BeatType.yml"
if (!(Test-Path $BeatConfig)) {
    throw "Beat configuration not found: $BeatConfig. Ensure $BeatType.yml
is in the installation directory."
}

# Handle data path migration
if ($ForceLegacyPath) {
    Write-Host "Using legacy data path: $LegacyDataPath"
    # PARENT: $HomePath below is "$BasePath\$BeatName", and the legacy
registry lives directly
    # in C:\ProgramData\<Beat>. Assigning $LegacyDataPath gave
C:\ProgramData\<Beat>\<Beat>.
    $BasePath = Split-Path $LegacyDataPath -Parent
} elseif (Test-Path $LegacyDataPath) {
    Write-Host "Legacy data path found at $LegacyDataPath"
    Write-Host "Migrating to new path: $BasePath\$BeatName"

    Try {
        $BeatPath = "$BasePath\$BeatName"

        # Create destination directory
        if (!(Test-Path $BeatPath)) {
            New-Item -ItemType Directory -Path $BeatPath -ErrorAction Stop
| Out-Null
        }

        # Move all items from legacy path.
        # RETRY, same shape as the binary Move-Item in the upgrade runner:
an AV/EDR handle on a
        # file the beat only just released clears on a later attempt, while
a real permission or
        # policy denial fails all 5. The Remove-Item is INSIDE the retry on
purpose - a locked
        # destination is as likely as a locked source.
        Get-ChildItem -LiteralPath $LegacyDataPath -Force | ForEach-Object {
            $dest = Join-Path $BeatPath $_.Name
            $src  = $_.FullName
            $name = $_.Name
            for ($try = 1; $try -le 5; $try++) {
                try {
                    if (Test-Path $dest) { Remove-Item $dest -Recurse
-Force -ErrorAction Stop }
                    Move-Item $src $dest -ErrorAction Stop
                    Write-Host "  Moved: $name"
                    break
                }
                catch {
                    if ($try -eq 5) { throw }
                    Write-Host "  Move of '$name' blocked (attempt $try/5),
retrying in 3s..." -ForegroundColor DarkGray
                    Start-Sleep -Seconds 3
                }
            }
        }

        # Remove old legacy directory
        Remove-Item $LegacyDataPath -Recurse -Force -ErrorAction Stop
        Write-Host "Migration completed successfully" -ForegroundColor Green

    } Catch {
        # All 5 attempts exhausted: capture WHY before the machine state is
lost, exactly as the
        # binary-extract path does. The diagnostic ships alongside THIS
script - C:\BeatUpgrade on
        # a central run, the scripts folder on a local run - so
$PSScriptRoot finds it either way.
        # -NoElevate: this session is already elevated and must never raise
a UAC prompt.
        # Wrapped so a diagnostic failure cannot mask the real migration
error, re-thrown below.
        $dg = Join-Path $PSScriptRoot 'diagnose-extract-denied.ps1'
        if (Test-Path $dg) {
            Write-Host "Migration failed 5/5 - running the access
diagnostic before failing..." -ForegroundColor Yellow
            Try { & $dg -NoElevate }
            Catch { Write-Host "  diagnostic itself failed:
$($_.Exception.Message)" -ForegroundColor DarkGray }
        } else {
            Write-Host "Migration failed 5/5 - diagnostic not staged ($dg),
skipping it." -ForegroundColor DarkGray
        }
        # Write-Host, not Write-Error: $ErrorActionPreference is 'Stop' at
the top of this script,
        # which makes Write-Error itself terminating - so the FIRST one
used to abort this block and
        # the advice below never printed, and the real inner error was lost
with the unreached
        # 'throw $_.Exception'. The inner message is now carried in the
thrown text instead.
        Write-Host "Failed to migrate data path from $LegacyDataPath to
$BasePath" -ForegroundColor Red
        if ($svcExisted) {
            # Say it out loud: "service still there" must not read as
"recovered".
            Write-Host ""
            Write-Host "  IMPORTANT - current state of this server:"
-ForegroundColor Yellow
            Write-Host "    The $BeatType service was NOT deleted. It is
still registered on its previous" -ForegroundColor Yellow
            Write-Host "    version, so a re-run or a rollback can find it
- but it is STOPPED." -ForegroundColor Yellow
            Write-Host "    This server is NOT shipping $BeatType logs
right now, and will not until the" -ForegroundColor Yellow
            Write-Host "    rollback runs or someone starts it by hand:
 Start-Service $BeatType" -ForegroundColor Yellow
            Write-Host ""
        }
        Write-Host "Use -ForceLegacyPath to continue with the legacy path."
-ForegroundColor Yellow
        throw "Failed to migrate data path from $LegacyDataPath to
$BasePath ($($_.Exception.Message))"
    }
} else {
    Write-Host "Using new data path: $BasePath\$BeatName"
}

# Set up paths
$HomePath = "$BasePath\$BeatName"
$LogsPath = "$HomePath\logs"
$KeystorePath = "$WorkDir\data\$BeatName.keystore"

# Ensure data directory exists
if (!(Test-Path $HomePath)) {
    Write-Host "Creating data directory: $HomePath"
    New-Item -ItemType Directory -Path $HomePath -Force | Out-Null
}

# The data is in place, so the old registration can go now and free the
service name for
# New-Service below. Deferred to here deliberately - see the Stop-Service
note above.
if ($svcExisted) {
    Write-Host "Deleting existing $BeatType service..."
    sc.exe delete $BeatType | Out-Null
    Start-Sleep -Seconds 2   # let the SCM release the name
}

# Build service command
$FullCmd = "`"$BeatExe`" " +
           "--environment=windows_service " +
           "-c `"$BeatConfig`" " +
           "--path.home `"$WorkDir`" " +
           "--path.data `"$HomePath`" " +
           "--path.logs `"$LogsPath`" " +
           "-E keystore.path=`"$KeystorePath`" " +
           "-E logging.files.redirect_stderr=true"

Write-Host "Creating $BeatType service..."
Write-Host "  Binary: $BeatExe"
Write-Host "  Config: $BeatConfig"
Write-Host "  Data:   $HomePath"
Write-Host "  Logs:   $LogsPath"

# Create the service
Try {
    New-Service -Name $BeatType `
                -DisplayName $BeatName `
                -BinaryPathName $FullCmd `
                -StartupType Automatic `
                -ErrorAction Stop | Out-Null

    Write-Host "Service created successfully" -ForegroundColor Green

} Catch {
    Write-Error "Failed to create service: $($_.Exception.Message)"
    throw
}

# Configure and start service
Try {
    # Set to delayed-auto start for better boot performance
    Write-Host "Configuring service for delayed-auto start..."
    $scResult = sc.exe config $BeatType start= delayed-auto 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set delayed-auto start: $scResult"
    }

    # Start the service
    Write-Host "Starting $BeatType service..."
    Start-Service -Name $BeatType -ErrorAction Stop

    # Wait for service to reach Running state
    Write-Host "Waiting for service to start (timeout: 30s)..."
    $timeout = New-TimeSpan -Seconds 30
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    do {
        $svc = Get-Service $BeatType
        if ($svc.Status -eq 'Running') {
            Write-Host "$BeatName service is running!" -ForegroundColor
Green
            break
        }
        Start-Sleep -Milliseconds 500
    } while ($sw.Elapsed -lt $timeout)

    if ($svc.Status -ne 'Running') {
        throw "Service did not reach Running state within 30 seconds.
Current status: $($svc.Status)"
    }

    # Additional stability check
    Write-Host "Validating service stability (5s)..."
    Start-Sleep -Seconds 5

    $svc = Get-Service $BeatType
    if ($svc.Status -ne 'Running') {
        throw "Service stopped unexpectedly. Current status: $($svc.Status)"
    }

    Write-Host "Service installation completed successfully!"
-ForegroundColor Green
    Write-Host "Service: $BeatType" -ForegroundColor Green
    Write-Host "Status:  $($svc.Status)" -ForegroundColor Green
    Write-Host "Logs:    $LogsPath" -ForegroundColor Green

} Catch {
    Write-Error "Service failed to start: $($_.Exception.Message)"
    Write-Warning "Check logs at: $LogsPath"
    Write-Warning "Run 'Get-EventLog -LogName Application -Source $BeatType
-Newest 10' for details"
    throw
}
