# No-wizard, no-parameter entry point for
Filebeat-payload\Install_SQL_Filebeat.ps1 (SQL servers only).
# Works out -ENV from this server's NAME, so it can be run with no prior
knowledge:
# double-click Install-Filebeat-Auto.cmd, check the detected environment
and paths, answer Y.
# Self-elevates if needed. If the name matches no rule, it stops and says
how to run by hand.

# ---- Hostname -> ENV ----
# Built from every SQL host that shipped to logs-sql-* on each cluster over
7 days (2026-10-25).
# Rules are checked IN ORDER, case-insensitive. The order matters: 'prd'
must win before
# the bare 'd<nn>' rule, and 'lt02' (stg) before the generic 'lt<n>' (uat).
#   production : <<servername>>*, <<servername>>, <<servername>>,
<<servername>>/02
#   stg        : <<servername>>*, <<servername>>*, <<servername>>/04,
<<servername>>-01/02   (sandbox ships to stg)
#   uat        : <<servername>>, <<servername>>/02, <<servername>>-01/02
#   qa         : <<servername>>*, <<servername>>/04
#   dev        : <<servername>>*, <<servername>>, <<servername>>
#   demo       : no SQL host found - never derived; run the installer with
-ENV demo by hand
function Get-EnvFromHostName([string]$name) {
    $n = $name.ToLower()
    if ($n -match 'prd')       { return 'production' }
    if ($n -match 'stg|sbx')   { return 'stg' }
    if ($n -match 'lt02')      { return 'stg' }        # sqldblt02-* ships
to stg, not uat
    if ($n -match 'uat|lt\d')  { return 'uat' }        # sqldblt01-*
    if ($n -match 'qa')        { return 'qa' }
    if ($n -match 'dev')       { return 'dev' }
    if ($n -match 'rsisd\d')   { return 'dev' }        # <<servername>> (vs
<<servername>> above)
    return $null
}

$isAdmin =
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
               [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        Start-Process powershell.exe -Verb RunAs -ErrorAction Stop `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File
`"$PSCommandPath`""
    } catch {
        Write-Host "Administrator rights are required:
$($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to close"
    }
    exit
}

$engine = Join-Path $PSScriptRoot
'Filebeat-payload\Install_SQL_Filebeat.ps1'
$code   = 1
$envName = Get-EnvFromHostName $env:COMPUTERNAME
if (-not (Test-Path $engine)) {
    Write-Host "ERROR: $engine not found - copy the whole folder, including
Filebeat-payload\." -ForegroundColor Red
}
elseif (-not $envName) {
    Write-Host "ERROR: can't tell the environment from the server name
'$env:COMPUTERNAME'." -ForegroundColor Red
    Write-Host "Run it by hand instead, e.g.:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$engine`" -ENV
<dev|qa|uat|stg|production|demo>" -ForegroundColor Yellow
}
else {
    Write-Host "Server '$env:COMPUTERNAME' -> environment '$envName'"
-ForegroundColor Cyan
    # No -Yes: the installer prints the detected paths and asks Y/N before
changing anything,
    # which is also where the operator can stop if the environment above
looks wrong.
    & $engine -ENV $envName
    $code = $LASTEXITCODE
}

Read-Host "`nPress Enter to close"
exit $code
