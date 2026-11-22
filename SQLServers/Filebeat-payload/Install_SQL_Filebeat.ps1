# Filebeat 8.19.11 install - SQL server (run ON the box via RDP)
# For a SQL server that has NEVER had a beat. Run this in an elevated
PowerShell from the
# folder where you pasted the payload, or use ..\Install-Filebeat.cmd (see
README in this folder).
#
# Deliberately narrower than individual\Upgrade_Local.ps1:
#   - SQL role only (no Reporting / Dual, no server-type detection)
#   - filebeat only (no winlogbeat), version fixed at 8.19.11
#   - no old config to validate/migrate: an EXISTING filebeat service is an
error (quits),
#     unless an earlier run of THIS installer created it (marker file - see
the guard)
#   - no ODBC audit
#   - nothing to roll back to, so the prompts are R/C (never V)
# Log paths come from the known-layout probe (Get-SqlLogPaths.ps1) unless
passed in.

Param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('dev','qa','uat','stg','production','demo')]
    [String]$ENV,

    # Optional path overrides (the wizard always passes all three). If ANY
is passed, the
    # probe is skipped and the given lists are used as-is. An empty
-JobsOutput drops
    # input id 1; -SqlDump empty is derived from -ErrorLog.
    [String[]]$JobsOutput = @(),
    [String[]]$SqlDump    = @(),
    [String[]]$ErrorLog   = @(),

    # Skip the "install with these paths? (Y/N)" prompt - the wizard
already confirmed them.
    [Switch]$Yes
)

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot   # anchor to this folder
regardless of caller CWD
Get-ChildItem -Path ".\*.ps1" | Unblock-File

$toVersion = '8.19.11'
$beatType  = 'filebeat'

# ---- Environment-specific endpoint (same table as Upgrade_Local.ps1 -
PROJECT_NOTES 2) ----
# FILEBEAT_VPCE machine env var is created from this below.
$VPCE = switch ($ENV) {
    "dev"        { '<<endpoint>>' }
    "qa"         { '<<endpoint>>' }
    "uat"        { '<<endpoint>>' }
    "stg"        { '<<endpoint>>' }
    "production" { '<<endpoint>>' }
    "demo"       { '<<endpoint>>' }
}

# ---- FILEBEAT_PASSWORD (kept OUT of this script - see beat-secrets.psd1)
----
$fbPassword  = $null
$secretsFile = Join-Path $PSScriptRoot 'beat-secrets.psd1'
if (Test-Path $secretsFile) {
    $fbPassword = (Import-PowerShellDataFile -Path $secretsFile)[$ENV]
}

$hostName = $env:COMPUTERNAME
Write-Host "`n========================================" -ForegroundColor
Cyan
Write-Host "  SQL FILEBEAT INSTALL - $hostName"        -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Environment:  $ENV"
Write-Host "  Version:      $toVersion"
Write-Host "========================================`n" -ForegroundColor
Cyan

# ---- Validate the pasted payload is complete ----
$zipFile = "filebeat-$toVersion-windows-x86_64.zip"
$need =
@('install-service-beat.ps1','check_errors.ps1','Get-SqlLogPaths.ps1',
$zipFile)
$missing = $need | Where-Object { !(Test-Path ".\$_") }
if ($missing) {
    Write-Host "ERROR: Missing required files in $PSScriptRoot :"
-ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    throw "Paste all payload files next to this script and re-run."
}

# ---- Incremental, crash-safe local log ----
$runStamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$progressCsv = ".\install-sql-filebeat-$hostName-$runStamp.csv"
'Timestamp,Server,BeatType,Role,Result,Detail' | Set-Content -Path
$progressCsv -Encoding UTF8
function Add-ProgressRow {
    param($Result, $Detail)
    $ts = Get-Date -Format "s"
    $safe = '"' + (($Detail -replace '"','""')) + '"'
    "$ts,$hostName,$beatType,SQL,$Result,$safe" | Add-Content -Path
$progressCsv -Encoding UTF8
}

function Remove-InputBlock($lines, $marker) {
    # Delete the WHOLE '- type: filestream' input block that contains
$marker. Used when no
    # jobsOutput path exists: filebeat refuses to start on an input with an
empty 'paths:'
    # list, so the input must go away entirely rather than be left blank.
    # (Identical to the function in individual\Upgrade_Local.ps1.)
    $hit = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match
[regex]::Escape($marker)) { $hit = $i; break } }
    if ($hit -lt 0) { return $lines }        # marker already gone -
nothing to do

    $markerIndent = ($lines[$hit] -replace '^(\s*).*$','$1').Length
    $start = -1; $indent = 0
    for ($i = $hit - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^(\s*)-\s+\S' -and $Matches[1].Length -lt
$markerIndent) {
            $start = $i; $indent = $Matches[1].Length; break
        }
    }
    if ($start -lt 0) { return $lines }     # not inside a list item -
leave it alone

    $end = $lines.Count - 1
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*$') { continue }                 #
blanks belong to the block
        $ind = ($lines[$i] -replace '^(\s*).*$','$1').Length
        if ($ind -le $indent) { $end = $i - 1; break }
    }
    while ($end -gt $start -and $lines[$end] -match '^\s*$') { $end-- }   #
trim trailing blanks

    $out = @()
    if ($start -gt 0)              { $out += $lines[0..($start - 1)] }
    if ($end -lt $lines.Count - 1) { $out += $lines[($end +
1)..($lines.Count - 1)] }
    return ,$out
}

function Invoke-Validation {
    # check_errors.ps1 NEVER throws; it sets $LASTEXITCODE (PROJECT_NOTES
14). Never call it
    # with -ErrorAction Stop. Returns 0 healthy / 1 hard error / 2 warnings
only.
    param([string]$status)
    Write-Progress -Id 10 -Activity $beatType -Status $status
-PercentComplete 90
    # | Out-Host is REQUIRED: check_errors.ps1 emits its PASS/INFO lines
with Write-Output, and
    # inside a function those would join the return value (an array, not
the exit code).
    & ".\check_errors.ps1" -beatType $beatType -version $toVersion |
Out-Host
    return $LASTEXITCODE
}

# ---- Guard: this is for NEW installs only ----
# An existing filebeat service would be stopped, deleted and re-created by
# install-service-beat.ps1. Servers that already run a beat belong to
individual\.
# EXCEPTION: a service this installer created itself (e.g. a run that
failed after the service
# was registered) may be re-run over. The install DIR can't tell the two
apart - Upgrade_Local
# installs to the same path - so this installer drops a marker file there
(PHASE 2), and only a
# service whose install dir carries it counts as ours. The wizard repeats
this test.
$markerName = 'installed-by-Install_SQL_Filebeat.txt'
$existing = Get-Service $beatType -ErrorAction SilentlyContinue
if ($existing) {
    $cim = Get-CimInstance Win32_Service -Filter "Name='$beatType'"
-ErrorAction SilentlyContinue
    $own = $cim -and $cim.PathName -match '^\s*"([^"]+)"' -and
           (Test-Path (Join-Path (Split-Path $Matches[1] -Parent)
$markerName))
    if ($own) {
        Write-Host "  '$beatType' service exists (status:
$($existing.Status)) but an earlier run of this installer created it -
re-running over it." -ForegroundColor Yellow
    } else {
        $msg = "A '$beatType' service already exists on $hostName (status:
$($existing.Status)) - this script is for NEW installs only. Use
individual\Upgrade_Local.ps1 instead."
        Write-Host "ERROR: $msg" -ForegroundColor Red
        Add-ProgressRow -Result 'FAILED' -Detail $msg
        exit 1
    }
}

# ---- Pre-flight env-var checks: stop BEFORE anything is changed ----
# No password at all = a beat that can never authenticate, so don't install
one.
$curPw =
[Environment]::GetEnvironmentVariable('FILEBEAT_PASSWORD','Machine')
if (-not $curPw -and -not $fbPassword) {
    $msg = "FILEBEAT_PASSWORD is not set on this server and
beat-secrets.psd1 has no entry for '$ENV' - nothing was changed."
    Write-Host "ERROR: $msg" -ForegroundColor Red
    Add-ProgressRow -Result 'FAILED' -Detail $msg
    exit 1
}
# Values from ANOTHER environment: FILEBEAT_ENVIRONMENT / FILEBEAT_PASSWORD
are kept (never
# overwritten, PROJECT_NOTES 7) while FILEBEAT_VPCE is set to -ENV's
endpoint, which can mix
# environments (e.g. an aborted 'dev' run, then 'production'). A mismatch
can also be
# deliberate ('prod' vs 'production'), so ask rather than stop.
$mismatch = @()
$curEnv  =
[Environment]::GetEnvironmentVariable('FILEBEAT_ENVIRONMENT','Machine')
$curVpce = [Environment]::GetEnvironmentVariable('FILEBEAT_VPCE','Machine')
if ($curEnv -and $curEnv -ne $ENV)    { $mismatch += "FILEBEAT_ENVIRONMENT
= '$curEnv' (kept as-is)" }
if ($curVpce -and $curVpce -ne $VPCE) { $mismatch += "FILEBEAT_VPCE =
$curVpce (will be replaced with the '$ENV' endpoint)" }
if ($curPw -and $fbPassword -and $curPw -ne $fbPassword) { $mismatch +=
"FILEBEAT_PASSWORD differs from the '$ENV' secret (kept as-is)" }
if ($mismatch) {
    Write-Host "WARNING: machine env vars on this server don't match
'$ENV':" -ForegroundColor Yellow
    foreach ($m in $mismatch) { Write-Host "    $m" -ForegroundColor Yellow
}
    if ((Read-Host "  Continue anyway? (Y/N)") -notmatch '^[Yy]') {
        Add-ProgressRow -Result 'FAILED' -Detail ("Operator stopped on
env-var mismatch: " + ($mismatch -join '; '))
        Write-Host "Stopped - nothing was changed." -ForegroundColor Red
        exit 1
    }
}

try {
    # ---- Machine env vars the deployed config references (PROJECT_NOTES
7) ----
    # Create when ABSENT; NEVER overwrite an existing value.
    $fbEnvCur =
[Environment]::GetEnvironmentVariable('FILEBEAT_ENVIRONMENT','Machine')
    if (-not $fbEnvCur) {
        [Environment]::SetEnvironmentVariable('FILEBEAT_ENVIRONMENT', $ENV,
'Machine')
        Write-Host "FILEBEAT_ENVIRONMENT created = $ENV" -ForegroundColor
Yellow
    } elseif ($fbEnvCur -ne $ENV) {
        Write-Host "FILEBEAT_ENVIRONMENT is '$fbEnvCur', not '$ENV' - left
as-is" -ForegroundColor Yellow
    }
    if (-not
[Environment]::GetEnvironmentVariable('FILEBEAT_PRODUCT','Machine')) {
        [Environment]::SetEnvironmentVariable('FILEBEAT_PRODUCT', 'sql',
'Machine')
        Write-Host "FILEBEAT_PRODUCT created = sql" -ForegroundColor Yellow
    }
    if (-not
[Environment]::GetEnvironmentVariable('FILEBEAT_USER','Machine')) {
        [Environment]::SetEnvironmentVariable('FILEBEAT_USER',
'filebeat_setup', 'Machine')
        Write-Host "FILEBEAT_USER created = filebeat_setup"
-ForegroundColor Yellow
    }
    if (-not $curPw) {   # the pre-flight guarantees $fbPassword is set in
this case
        [Environment]::SetEnvironmentVariable('FILEBEAT_PASSWORD',
$fbPassword, 'Machine')
        Write-Host "FILEBEAT_PASSWORD created (from $secretsFile)"
-ForegroundColor Yellow
    }
    if ([Environment]::GetEnvironmentVariable("FILEBEAT_VPCE","Machine")
-ne $VPCE) {
        [Environment]::SetEnvironmentVariable("FILEBEAT_VPCE", $VPCE,
"Machine")
        Write-Host "FILEBEAT_VPCE set = $VPCE" -ForegroundColor Yellow
    }

    # ---- Resolve the 3 path sets: jobsOutput, sqlDump, ERRORLOG ----
    $overridden = $PSBoundParameters.ContainsKey('JobsOutput') -or
                  $PSBoundParameters.ContainsKey('SqlDump') -or
                  $PSBoundParameters.ContainsKey('ErrorLog')
    if ($overridden) {
        $jobsPaths = @($JobsOutput | Where-Object { $_ -and $_.Trim() } |
ForEach-Object { $_.Trim() })
        $dumpPaths = @($SqlDump    | Where-Object { $_ -and $_.Trim() } |
ForEach-Object { $_.Trim() })
        $errPaths  = @($ErrorLog   | Where-Object { $_ -and $_.Trim() } |
ForEach-Object { $_.Trim() })
    } else {
        $probe     = & ".\Get-SqlLogPaths.ps1"
        $jobsPaths = @($probe.JobsOutput)
        $dumpPaths = @($probe.SqlDump)
        $errPaths  = @($probe.ErrorLog)
    }
    if (-not $errPaths.Count) {
        throw "No SQL ERRORLOG path found (looked for
<drive>:\MSSQL\MSSQL*\MSSQL\Log) - is this a SQL server?"
    }
    # sqlDump missing -> same directory as ERRORLOG, different leaf (string
surgery only, as in
    # Upgrade_Local.ps1: dump files exist only after a SQL fault, so no
existence check).
    if (-not $dumpPaths.Count) {
        $dumpPaths = @($errPaths | ForEach-Object { ($_ -replace
'[^\\/]*$', '') + 'SQLDump*.txt' } | Select-Object -Unique)
        Write-Host "  sqlDump path not given - derived from ERRORLOG:
$($dumpPaths -join ', ')" -ForegroundColor Yellow
    }

    Write-Host "SQL log paths:" -ForegroundColor Cyan
    if ($jobsPaths.Count) { foreach ($p in $jobsPaths) { Write-Host "
 jobsOutput : $p" } }
    else { Write-Host "    jobsOutput : NONE - input id 1 will be dropped"
-ForegroundColor DarkGray }
    foreach ($p in $dumpPaths) { Write-Host "    sqlDump    : $p" }
    foreach ($p in $errPaths)  { Write-Host "    ERRORLOG   : $p" }
    if (-not $Yes -and (Read-Host "  Install filebeat $toVersion with these
paths? (Y/N)") -notmatch '^[Yy]') {
        throw "Operator declined the install"
    }

    # ---------- PHASE 1: EXTRACT (depth-agnostic, same as
Upgrade_Local.ps1) ----------
    Write-Progress -Id 10 -Activity $beatType -Status "Extracting"
-PercentComplete 25
    $beatPath    = "C:\Program Files\Elastic\Beats"
    $beatSubPath = Join-Path $beatPath "filebeat-$toVersion-windows-x86_64"
    $staging     = Join-Path $beatPath "_staging_filebeat"
    if (!(Test-Path $beatPath)) { New-Item -ItemType Directory -Force -Path
$beatPath | Out-Null }

    # An extract at this version is already here (manual unzip, or an
earlier partial run).
    $useExisting = $false
    if (Test-Path "$beatSubPath\filebeat.exe") {
        Write-Host "  Existing $toVersion extract found: $beatSubPath"
-ForegroundColor Yellow
        $ans = ''
        while ($ans -ne 'O' -and $ans -ne 'U') {
            $ans = (Read-Host "  [O]verride (delete + re-extract from ZIP)
/ [U]se existing").Trim().ToUpper()
        }
        if ($ans -eq 'U') { $useExisting = $true }
    }

    if ($useExisting) {
        Write-Host "  Using existing extract - skipping ZIP extraction
(configure/install still run)" -ForegroundColor Cyan
        # A reused extract may already be configured, so the placeholders
are gone. Restore
        # the two template files from the ZIP so the fill below always
starts clean.
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $PSScriptRoot
$zipFile))
        try {
            foreach ($rel in 'filebeat.yml','modules.d/mssql.yml') {
                $entry = $zip.Entries | Where-Object { $_.FullName -like
"*/$rel" } | Select-Object -First 1
                if (-not $entry) { throw "Template '$rel' not found inside
$zipFile" }
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,
(Join-Path $beatSubPath $rel), $true)
            }
        } finally { $zip.Dispose() }
    }
    else {
        if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
        Expand-Archive -LiteralPath ".\$zipFile" -DestinationPath $staging
-Force

        $exe = Get-ChildItem $staging -Recurse -File -Filter "filebeat.exe"
-ErrorAction SilentlyContinue | Select-Object -First 1
        if (!$exe) { throw "Extraction failed - 'filebeat.exe' not found
inside $zipFile" }
        $srcRoot = $exe.Directory.FullName

        if (Test-Path $beatSubPath) { Remove-Item $beatSubPath -Recurse
-Force }
        # -ErrorAction Stop is REQUIRED: Move-Item's failure is
NON-TERMINATING.
        for ($try = 1; $try -le 5; $try++) {
            try { Move-Item -LiteralPath $srcRoot -Destination $beatSubPath
-Force -ErrorAction Stop; break }
            catch {
                if ($try -eq 5) {
                    $dg = Join-Path $PSScriptRoot
'diagnose-extract-denied.ps1'
                    if (Test-Path $dg) {
                        Write-Host "  Move failed 5/5 - running extract
diagnostic before failing..." -ForegroundColor Yellow
                        try { & $dg -NoElevate }
                        catch { Write-Host "  diagnostic itself failed:
$($_.Exception.Message)" -ForegroundColor DarkGray }
                    }
                    throw
                }
                Write-Host "  Move blocked (attempt $try/5), retrying in
3s..." -ForegroundColor DarkGray
                Start-Sleep -Seconds 3
            }
        }
        Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
    }

    # ---------- PHASE 2: CONFIGURE (fill the SQL template from the ZIP)
----------
    Write-Progress -Id 10 -Activity $beatType -Status "Configuring"
-PercentComplete 50
    $cfgLines = @(Get-Content "$beatSubPath\filebeat.yml")
    if (-not $jobsPaths.Count) { $cfgLines = Remove-InputBlock $cfgLines
'{path_to_jobsOutput_logs}' }

    $cfgLines | ForEach-Object {
        if     ($_ -match '{path_to_jobsOutput_logs}') { $jobsPaths |
ForEach-Object { "    - $_" } }
        elseif ($_ -match '{path_to_sqlDump_logs}')    { $dumpPaths |
ForEach-Object { "    - $_" } }
        else   { $_ }
    } | Set-Content "$beatSubPath\filebeat.yml"

    # ERRORLOG -> ONE flow-sequence line (PROJECT_NOTES 4b): var.paths:
['a', 'b']
    $errorLine = "    var.paths: [" + (($errPaths | ForEach-Object { "'" +
$_ + "'" }) -join ', ') + "]"
    (Get-Content "$beatSubPath\modules.d\mssql.yml") | ForEach-Object {
        if ($_ -match '{path_to_ERRORLOG}') { $errorLine } else { $_ }
    } | Set-Content "$beatSubPath\modules.d\mssql.yml"

    foreach ($f in 'filebeat.yml','modules.d\mssql.yml') {
        if ((Get-Content "$beatSubPath\$f" -Raw) -match '{path_to_') {
            throw "SQL: unresolved placeholder remains in $f after
substitution"
        }
    }
    # Marks this install dir as created by THIS installer - see the guard
at the top.
    "Created by Install_SQL_Filebeat.ps1 on $(Get-Date -Format s) for ENV
'$ENV'." |
        Set-Content (Join-Path $beatSubPath $markerName)

    $inputSummary = if ($jobsPaths.Count) { 'jobsoutput, sqldump' } else {
'sqldump only (input id 1 dropped)' }
    Write-Host "  SQL log paths set ($inputSummary) + mssql ERRORLOG"
-ForegroundColor Cyan

    # ---------- PHASE 3: INSTALL + PHASE 4: VALIDATE ----------
    Write-Progress -Id 10 -Activity $beatType -Status "Installing service"
-PercentComplete 75
    & ".\install-service-beat.ps1" -BeatType $beatType -Version $toVersion

    $valExit = Invoke-Validation "Validating logs"

    # AUTOMATIC SINGLE RETRY on exit 2 (same rule as the app runners):
every check that yields
    # "warnings only" is time-dependent (version line, start running,
connection, acked
    # events), and a freshly started beat may just not have shipped its
first batch yet.
    # Exit 1 (real error line / no log file) is NOT retried. ONE retry,
never a loop.
    if ($valExit -eq 2) {
        Write-Host "  [WARN] Validation reported warnings only (no errors)
- the beat may not have connected / shipped its first batch yet."
-ForegroundColor Yellow
        Write-Host "  Retrying validation ONCE, automatically, in 45 s (+10
s inside check_errors.ps1 - this is not a hang)." -ForegroundColor Yellow
        Start-Sleep -Seconds 45
        $valExit = Invoke-Validation "Re-validating logs (automatic retry)"
        if ($valExit -eq 0) { Write-Host "  Validation passed on the
automatic retry." -ForegroundColor Green }
    }

    # Still not clean: operator decides. New install = nothing to revert
to, so R/C only.
    while ($valExit -ne 0) {
        $kind = if ($valExit -eq 2) { 'warnings only (no errors)' } else {
'ERRORS' }
        $col  = if ($valExit -eq 2) { 'Yellow' } else { 'Red' }
        Write-Host "  Validation reported $kind (exit $valExit)."
-ForegroundColor $col
        $ans = Read-Host "  [R]erun validation / [C]ontinue (leave as-is
for review)? (R/C)"
        if ($ans -match '^[Rr]') { $valExit = Invoke-Validation
"Re-validating logs" }
        elseif ($ans -match '^[Cc]') { break }
        else { Write-Host "  Please answer R or C." -ForegroundColor
DarkGray }
    }
    Write-Progress -Id 10 -Activity $beatType -Completed

    if ($valExit -eq 0) {
        Add-ProgressRow -Result 'SUCCESS' -Detail "paths: $inputSummary"
        $ok = $true
    } elseif ($valExit -eq 2) {
        Add-ProgressRow -Result 'SUCCESS-WARNINGS' -Detail 'operator
continued despite validation warnings'
        $ok = $true
    } else {
        Add-ProgressRow -Result 'FAILED' -Detail 'validation errors - left
in place for review'
        $ok = $false
    }
}
catch {
    Write-Progress -Id 10 -Activity $beatType -Completed
    Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
    Add-ProgressRow -Result 'FAILED' -Detail $_.Exception.Message
    $ok = $false
}

Write-Host "`n========================================" -ForegroundColor
Cyan
Write-Host "  DONE - $hostName (SQL install)"         -ForegroundColor Cyan
Write-Host "  Log: $progressCsv"
Write-Host "========================================`n" -ForegroundColor
Cyan
if ($ok) { Write-Host "Filebeat $toVersion installed." -ForegroundColor
Green; exit 0 }
else { Write-Host "Install FAILED or left with errors - review the log."
-ForegroundColor Red; exit 1 }
