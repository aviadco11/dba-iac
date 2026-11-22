<#
.SYNOPSIS
    Validates a Beat's startup logs after install/upgrade.
.DESCRIPTION
    Reads the latest ndjson log and runs health checks.
      - HARD checks (affect verdict): apply to every beat type.
      - ADVISORY checks (informational): depend on beat type/config
        (module reloader & harvesters don't exist for winlogbeat).
    NEVER throws. Sets exit code:
      0 = healthy
      1 = a hard ERROR (actual log.level=error line, or no log file) - real
failure
      2 = warnings only (a confirmation check failed but NO error lines) -
operator decides
    Callers inspect $LASTEXITCODE (do NOT pass -ErrorAction Stop).
#>
Param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('filebeat','filebeat2','winlogbeat','metricbeat')]
    [String]$beatType,

    [Parameter(Position = 1, Mandatory = $true)]
    [String]$version   # e.g. 8.19.11
)

Write-Host "Waiting 10s for logs..."
Start-Sleep -Seconds 10
Write-Host "Checking $beatType logs..."

$Today    = Get-Date -Format "yyyyMMdd"
$BeatName = (Get-Culture).TextInfo.ToTitleCase($beatType)   # data dir:
Filebeat2-Data\Filebeat2\logs

# A renamed filebeat2.exe still writes log FILES with the compiled-in name
"filebeat".
$LogPrefix = if ($beatType -eq 'filebeat2') { 'filebeat' } else { $beatType
}

$LogsPath = "C:\Program Files\$BeatName-Data\$BeatName\logs"
$LogFile  = Get-ChildItem $LogsPath -Filter "$LogPrefix-$Today*.ndjson"
-ErrorAction SilentlyContinue |
    Sort-Object { if ($_.BaseName -match "$Today-(\d+)$") {
[int]$Matches[1] } else { -1 } } -Descending |
    Select-Object -First 1

if (-not $LogFile) {
    Write-Warning "No log file found in $LogsPath after startup. Service
may have failed."
    exit 1
}

$Lines  = Get-Content $LogFile.FullName -Tail 200 | ForEach-Object { $_ |
ConvertFrom-Json }
$HasError = $false   # a real error-level log line was found -> hard fail
(exit 1)
$HasWarn  = $false   # a confirmation check failed, but no error lines ->
warnings only (exit 2)

# ---- HARD check: actual error-level log lines (the ONLY thing that makes
this a hard failure) ----
$Errors = $Lines | Where-Object { $_.'log.level' -eq 'error' }
if ($Errors) {
    $HasError = $true
    Write-Warning "FAIL - Errors detected on startup:"
    $Errors | ForEach-Object { Write-Warning "       $($_.message)" }
} else { Write-Output "PASS - No errors detected in logs" }

# ---- CONFIRMATION checks: failing these is a WARNING (no error lines) not
a hard error ----
if ($Lines | Where-Object { $_.message -match $version -or
$_.system_info.build.libbeat -eq $version }) {
    Write-Output "PASS - Version $version confirmed in logs"
} else { $HasWarn = $true; Write-Warning "WARN - Could not confirm version
$version" }

if ($Lines | Where-Object { $_.message -match 'start running' }) {
    Write-Output "PASS - $beatType start running confirmed"
} else { $HasWarn = $true; Write-Warning "WARN - No 'start running'
confirmation" }

if ($Lines | Where-Object { $_.message -match 'Connection to .+
established' }) {
    Write-Output "PASS - Connection to destination established"
} else { $HasWarn = $true; Write-Warning "WARN - No connection established
message" }

$Acked = $Lines | Where-Object {
    $_.message -match 'Non-zero metrics' -and
$_.monitoring.metrics.libbeat.output.events.acked -gt 0
}
if ($Acked) {
    $latest = $Acked | Select-Object -Last 1
    Write-Output "PASS - Logs flowing
($($latest.monitoring.metrics.libbeat.output.events.acked) event(s)
acknowledged)"
} else { $HasWarn = $true; Write-Warning "WARN - No acknowledged events.
Logs may not be flowing." }

# ---- ADVISORY (informational only) ----
if ($Lines | Where-Object { $_.message -match 'Non-zero metrics in the last
30s' }) {
    Write-Output "INFO - Metrics reporting is active"
}
$Harvesters = $Lines | Where-Object { $_.message -match 'Harvester started
for paths' }
if ($Harvesters) { Write-Output "INFO - $($Harvesters.Count) harvester(s)
started" }

# ---- Verdict ----
Write-Output ""
if ($HasError) {
    Write-Warning "$beatType validation FAILED (errors in logs). Review
logs at: $($LogFile.FullName)"
    exit 1
} elseif ($HasWarn) {
    Write-Warning "$beatType validation reported WARNINGS only (no errors).
Review logs at: $($LogFile.FullName)"
    exit 2
} else {
    Write-Host -ForegroundColor Green "$beatType $version validated
successfully"
    exit 0
}
