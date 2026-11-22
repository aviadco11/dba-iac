<#
.SYNOPSIS
    Proves WHY an extract or a data-path migration fails with "access
denied" on a
    beat-upgrade target server.
.DESCRIPTION
    Read-only + probe-only (creates/removes '_diag_*' items, never touches
real installs).

    Just run it. It handles the rest itself:
      -Server <names>  runs remotely over WinRM (the SAME path the upgrade
uses, so the
                       same identity/token is tested) and writes
diag-<server>.txt per server.
      no args          runs locally; SELF-ELEVATES if needed, because a
non-elevated run
                       gives misleading PASSes.

    It separates the three candidate causes that all surface as "access
denied":
      A. Filesystem permission / elevation on the destination tree
      B. A security product blocking the write (Defender CFA/ASR,
AppLocker, WDAC, FSRM)
      C. A held handle (old service still running against the folder)
.EXAMPLE
    .\diagnose-extract-denied.ps1 -Server <<servername>>, <<servername>>
.EXAMPLE
    .\diagnose-extract-denied.ps1
#>
[CmdletBinding()]
Param(
    [string[]]$Server,          # remote targets; omit to probe THIS machine
    [switch]$NoElevate          # internal: set once we have already
relaunched elevated
)

$ErrorActionPreference = 'Continue'

# ---------- REMOTE MODE: push this same file to each server and run it
there ----------
# WinRM is how the upgrade reaches the box, so this reproduces its identity
exactly.
if ($Server) {
    $me   = $MyInvocation.MyCommand.Path
    $body = Get-Content $me -Raw
    foreach ($s in $Server) {
        Write-Host "`n##### $s #####" -ForegroundColor Magenta
        $out = Join-Path (Split-Path $me -Parent) "diag-$s.txt"
        # Tee-Object never saw anything: every line here is Write-Host
(information stream), and a
        # remote Write-Host is proxied to THIS console. Transcribe the
console instead; %TEMP% fallback.
        $tr = $false
        foreach ($cand in @($out, (Join-Path $env:TEMP "diag-$s.txt"))) {
            if ($tr) { continue }
            try   { Start-Transcript -LiteralPath $cand -Force -ErrorAction
Stop | Out-Null; $out = $cand; $tr = $true }
            catch { Write-Host "  cannot write $cand
($($_.Exception.Message))" -ForegroundColor Yellow }
        }
        try {
            Invoke-Command -ComputerName $s -ErrorAction Stop -ArgumentList
$body -ScriptBlock {
                param($src)
                $tmp = 'C:\BeatUpgrade\_diag_run.ps1'
                New-Item -ItemType Directory -Path 'C:\BeatUpgrade' -Force
-ErrorAction SilentlyContinue | Out-Null
                Set-Content -LiteralPath $tmp -Value $src -Encoding UTF8
                # finally: the copied script must go even if the probe run
throws part-way.
                try {
                    # -NoElevate: an Invoke-Command session is already
elevated; never UAC-prompt here.
                    & $tmp -NoElevate
                } finally {
                    Remove-Item -LiteralPath $tmp -Force -ErrorAction
SilentlyContinue
                    if (Test-Path -LiteralPath $tmp) {
                        Write-Host "  *** could not delete $tmp - remove it
manually ***" -ForegroundColor Red
                    } else {
                        Write-Host "  (removed $tmp)" -ForegroundColor
DarkGray
                    }
                }
            }
        } catch {
            Write-Host "  WinRM to $s failed: $($_.Exception.Message)"
-ForegroundColor Red
        }
        if ($tr) { try { Stop-Transcript | Out-Null } catch { } }
        # Only claim success if a real, non-empty file exists - never a
false 'saved'.
        $ok = $false
        if ($tr -and (Test-Path -LiteralPath $out)) {
            if ((Get-Item -LiteralPath $out).Length -gt 0) { $ok = $true }
        }
        if ($ok) {
            Write-Host "  --> saved $out" -ForegroundColor Green
        } else {
            Write-Host '
 *************************************************************'
-ForegroundColor Red
            Write-Host "  *** NOT SAVED - no diag file for $s was written.
         ***" -ForegroundColor Red
            Write-Host '  *** The console output ABOVE is the ONLY copy of
it.      ***' -ForegroundColor Red
            Write-Host '  *** Select it all and copy it out NOW, before you
close.  ***' -ForegroundColor Red
            Write-Host '
 *************************************************************'
-ForegroundColor Red
        }
    }
    Write-Host "`nDone. Send back every diag-<server>.txt file."
-ForegroundColor Cyan
    return
}

# ---------- LOCAL MODE: self-elevate, else the probes lie ----------
$curId = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdm = (New-Object
Security.Principal.WindowsPrincipal($curId)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdm -and -not $NoElevate) {
    Write-Host 'Not elevated - relaunching as administrator (accept the UAC
prompt)...' -ForegroundColor Yellow
    $log = Join-Path $env:TEMP "diag-$env:COMPUTERNAME.txt"
    $cmd = "& '$($MyInvocation.MyCommand.Path)' -NoElevate *>&1 |
Tee-Object -FilePath '$log'; Read-Host 'Press Enter to close'"
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList
'-NoProfile','-ExecutionPolicy','Bypass','-Command',$cmd -ErrorAction Stop
        Write-Host "Elevated window opened. Output is also saved to: $log"
-ForegroundColor Cyan
        return
    } catch {
        Write-Host "Could not elevate ($($_.Exception.Message)) -
continuing NON-elevated." -ForegroundColor Red
        Write-Host 'NOTE: a non-elevated run can show false DENIEDs. Treat
results with care.' -ForegroundColor Red
    }
}
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor
Cyan }
function Try-Probe($label, $sb) {
    try { & $sb | Out-Null; Write-Host "  OK      $label" -ForegroundColor
Green }
    catch { Write-Host "  DENIED  $label" -ForegroundColor Red
            Write-Host "          type: $($_.Exception.GetType().Name)"
-ForegroundColor DarkGray
            Write-Host "          msg : $($_.Exception.Message)"
-ForegroundColor DarkGray }
}

$beats  = 'C:\Program Files\Elastic\Beats'
$fb2    = Join-Path $beats 'filebeat2'
$stage  = 'C:\BeatUpgrade'

# The data migration (C:\ProgramData\<Beat> -> C:\Program
Files\<Beat>-Data) fails with the same
# 'access denied' as the extract, so both of its ends get the same probes
and ACL dump.
$dataDirs  = @()
$dataHomes = @()   # <Beat>-Data\<Beat>, the actual path.data - A2b's main
move target
foreach ($bn in 'Filebeat', 'Filebeat2', 'Winlogbeat') {
    $dataDirs  += (Join-Path $env:PROGRAMDATA $bn)
    $dataDirs  += (Join-Path $env:ProgramFiles "$bn-Data")
    $dataHomes += (Join-Path (Join-Path $env:ProgramFiles "$bn-Data") $bn)
}

$probes = @($beats, $fb2, $stage, 'C:\') + $dataDirs

# ---------- ARTIFACT TRACKING: nothing we create may survive, nothing else
may be touched ----------
# Every path we create is registered here, and deletion is HARD-GUARDED to
'_diag_*' leaf names.
# A path that does not look like ours is refused, so a bad Join-Path can
never delete a real install.
$script:Artifacts = New-Object System.Collections.Generic.List[string]
function New-Artifact($p) { if ($script:Artifacts -notcontains $p) {
$script:Artifacts.Add($p) }; return $p }
function Test-IsOurs($p) { return ((Split-Path $p -Leaf) -like '_diag_*') }
function Remove-Artifact($p) {
    if (-not (Test-IsOurs $p)) {
        Write-Host "  REFUSED to delete '$p' - not a _diag_ path (safety
guard)" -ForegroundColor Red
        return
    }
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse
-Force -ErrorAction SilentlyContinue }
}

Write-Section 'IDENTITY / ELEVATION'
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
Write-Host "  User     : $($id.Name)"
Write-Host "  Elevated : $((New-Object
Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
Write-Host "  Host     : $env:COMPUTERNAME   PSVersion:
$($PSVersionTable.PSVersion)"

Write-Section 'A. WRITE PROBES (the decisive test - which dir refuses what)'
foreach ($d in $probes) {
    if (-not (Test-Path $d)) { Write-Host "  (absent) $d" -ForegroundColor
DarkGray; continue }
    Write-Host "  -- $d"
    $pd  = New-Artifact (Join-Path $d '_diag_probe_dir')
    $pd2 = New-Artifact (Join-Path $d '_diag_probe_dir2')   # the rename
target
    $pt  = New-Artifact (Join-Path $d '_diag_probe.txt')
    $pe  = New-Artifact (Join-Path $d '_diag_probe.exe')
    Try-Probe "create subdirectory"        { New-Item -ItemType Directory
-Path $pd -Force -ErrorAction Stop }
    Try-Probe "create .txt file"           { Set-Content $pt 'x'
-ErrorAction Stop }
    Try-Probe "create .exe file (ASR/FSRM) "{ Set-Content $pe 'x'
-ErrorAction Stop }
    Try-Probe "rename subdirectory"        { Rename-Item $pd $pd2
-ErrorAction Stop }
    foreach ($a in @($pd, $pd2, $pt, $pe)) { Remove-Artifact $a }
}

Write-Section 'A2. MOVE PROBE (mimics the failing Move-Item exactly)'
# NOTE: Move-Item reports the SOURCE path on denial even when the
DESTINATION is the
# unwritable side - verified. So the real upgrade error text does NOT
identify the culprit.
$srcRoot = New-Artifact (Join-Path $stage '_diag_probe_src')
$src     = Join-Path $srcRoot 'filebeat-x-windows-x86_64'
New-Item -ItemType Directory -Path $src -Force -ErrorAction
SilentlyContinue | Out-Null
Set-Content (Join-Path $src 'filebeat.exe') 'x' -ErrorAction
SilentlyContinue
foreach ($dest in @((New-Artifact (Join-Path $beats '_diag_moved')),
(New-Artifact (Join-Path $fb2 '_diag_moved')))) {
    if (-not (Test-Path (Split-Path $dest -Parent))) { continue }
    Try-Probe "move '$src' -> '$dest'" { Move-Item -LiteralPath $src
-Destination $dest -Force -ErrorAction Stop }
    # Move it back so the next destination gets the same probe; if that
fails, the final
    # sweep still removes '_diag_moved' itself.
    if (Test-Path $dest) { Move-Item -LiteralPath $dest -Destination $src
-Force -ErrorAction SilentlyContinue }
    Remove-Artifact $dest
}
Remove-Artifact $srcRoot

Write-Section 'A2b. DATA-MIGRATION MOVE PROBE (ProgramData -> <Beat>-Data)'
foreach ($bn in 'Filebeat', 'Filebeat2', 'Winlogbeat') {
    $lp = Join-Path $env:PROGRAMDATA $bn
    if (-not (Test-Path $lp)) { Write-Host "  (no legacy data) $lp"
-ForegroundColor DarkGray; continue }
    # Destination = deepest EXISTING ancestor of <Beat>-Data\<Beat>. This
probe must never create a
    # real (non-_diag_) directory, and ACLs are inherited, so an ancestor
is a fair stand-in.
    $dest = $null
    foreach ($c in @((Join-Path (Join-Path $env:ProgramFiles "$bn-Data")
$bn),
                     (Join-Path $env:ProgramFiles "$bn-Data"),
                     $env:ProgramFiles)) {
        if (-not $dest -and (Test-Path $c)) { $dest = $c }
    }
    $ms = New-Artifact (Join-Path $lp '_diag_move_src')
    $md = New-Artifact (Join-Path $dest '_diag_move_dst')
    Remove-Artifact $ms
    Remove-Artifact $md
    New-Item -ItemType Directory -Path $ms -Force -ErrorAction
SilentlyContinue | Out-Null
    if (-not (Test-Path $ms)) {
        Write-Host "  DENIED  create '$ms' - cannot even write inside the
legacy data dir" -ForegroundColor Red
        continue
    }
    Set-Content (Join-Path $ms '_diag_payload.txt') 'x' -ErrorAction
SilentlyContinue
    Write-Host "  -- $lp  ->  $dest"
    Try-Probe "move '$ms' -> '$md'" { Move-Item -LiteralPath $ms
-Destination $md -Force -ErrorAction Stop }
    Remove-Artifact $md
    Remove-Artifact $ms
}

Write-Section 'A3. SAME-VOLUME CHECK (a cross-volume move is a slow copy,
not a rename)'
foreach ($d in @($beats, $stage, $env:PROGRAMDATA)) {
    if (Test-Path $d) { Write-Host "  $d -> volume $((Get-Item
$d).PSDrive.Name):" }
}
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -eq 'C' } |
    ForEach-Object { Write-Host "  C: free =
$([math]::Round($_.Free/1GB,1)) GB" }

Write-Section 'B. ACLs + ATTRIBUTES on the destination tree'
foreach ($d in @($beats, $fb2) + $dataDirs) {
    if (-not (Test-Path $d)) { continue }
    Write-Host "  -- $d"
    $i = Get-Item $d -Force
    Write-Host "     attributes: $($i.Attributes)"
    $acl = Get-Acl $d
    Write-Host "     owner     : $($acl.Owner)"
    Write-Host "     inheritance blocked: $($acl.AreAccessRulesProtected)"
    $acl.Access | ForEach-Object {
        Write-Host ("     {0,-6} {1,-45} {2}  inherited={3}" -f
$_.AccessControlType, $_.IdentityReference, $_.FileSystemRights,
$_.IsInherited)
    }
}

Write-Section 'C. LEFTOVER STAGING DIRS (a failed run leaves these behind)'
$left = Get-ChildItem $beats -Recurse -Directory -Filter '_staging*'
-ErrorAction SilentlyContinue
if ($left) { $left | ForEach-Object { Write-Host "  $($_.FullName)
 (modified $($_.LastWriteTime))" -ForegroundColor Yellow } }
else { Write-Host '  none' }

Write-Section 'C2. RUNNING BEAT SERVICES (a live service holds its own
folder)'
Get-CimInstance Win32_Service -Filter "Name LIKE 'filebeat%' OR Name LIKE
'winlogbeat%'" -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Host "  $($_.Name) [$($_.State)] $($_.PathName)"
}
Get-Process filebeat*, winlogbeat* -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Host "  proc $($_.Name) pid=$($_.Id)
path=$($_.Path)" }

Write-Section 'D. DEFENDER: Controlled Folder Access / ASR / exclusions'
try {
    $s = Get-MpComputerStatus -ErrorAction Stop
    Write-Host "  RealTimeProtectionEnabled :
$($s.RealTimeProtectionEnabled)"
    Write-Host "  OnAccessProtectionEnabled :
$($s.OnAccessProtectionEnabled)"
    Write-Host "  IsTamperProtected         : $($s.IsTamperProtected)"
} catch { Write-Host "  Get-MpComputerStatus failed:
$($_.Exception.Message)" -ForegroundColor DarkGray }
try {
    $p = Get-MpPreference -ErrorAction Stop
    # 0=Disabled 1=Enabled(block) 2=AuditMode - CFA denies writes with
ACCESS DENIED
    Write-Host "  EnableControlledFolderAccess :
$($p.EnableControlledFolderAccess)  (1 = BLOCKING)" -ForegroundColor Yellow
    Write-Host "  CFA protected folders  :
$(($p.ControlledFolderAccessProtectedFolders) -join '; ')"
    Write-Host "  CFA allowed apps       :
$(($p.ControlledFolderAccessAllowedApplications) -join '; ')"
    Write-Host "  ASR rule IDs           :
$(($p.AttackSurfaceReductionRules_Ids) -join '; ')"
    Write-Host "  ASR rule actions       :
$(($p.AttackSurfaceReductionRules_Actions) -join '; ')  (1 = BLOCK)"
    Write-Host "  ExclusionPath          : $(($p.ExclusionPath) -join '; ')"
    Write-Host "  ExclusionProcess       : $(($p.ExclusionProcess) -join ';
')"
} catch { Write-Host "  Get-MpPreference failed (needs elevation):
$($_.Exception.Message)" -ForegroundColor DarkGray }

Write-Section 'D2. DEFENDER EVENT LOG - did it actually block us? (last 2
hours)'
# 1123/1124 = Controlled Folder Access block/audit, 1121/1122 = ASR
block/audit, 1116 = malware detected
$since = (Get-Date).AddHours(-2)
try {
    $ev = Get-WinEvent -FilterHashtable @{
LogName='Microsoft-Windows-Windows Defender/Operational';
Id=1116,1117,1121,1122,1123,1124; StartTime=$since } -ErrorAction Stop
    $ev | Select-Object -First 20 | ForEach-Object { Write-Host "
 [$($_.Id)] $($_.TimeCreated)  $(($_.Message -split "`n")[0])"
-ForegroundColor Yellow }
} catch { Write-Host '  no Defender block/detection events in the last 2h
(or log unavailable)' }

Write-Section 'E. ORG POLICY: AppLocker / WDAC / FSRM file screening'
try {
    $al = Get-AppLockerPolicy -Effective -ErrorAction Stop
    Write-Host "  AppLocker effective policy PRESENT; rule collections:
$(($al.RuleCollections | ForEach-Object { $_.RuleCollectionType }) -join ',
')" -ForegroundColor Yellow
} catch { Write-Host '  AppLocker: no effective policy / cmdlet
unavailable' }
try {
    $ci = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace
root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
    Write-Host "  DeviceGuard CodeIntegrityPolicyEnforcementStatus:
$($ci.CodeIntegrityPolicyEnforcementStatus)  (2 = enforced)"
} catch { Write-Host '  DeviceGuard: not queryable' }
$srm = Get-Service srmsvc -ErrorAction SilentlyContinue
if ($srm) { Write-Host "  FSRM (File Server Resource Manager) service:
$($srm.Status) - file SCREENING can deny writes by extension"
-ForegroundColor Yellow }
else      { Write-Host '  FSRM not installed' }
try {
    $fsev = Get-WinEvent -FilterHashtable @{ LogName='Application';
ProviderName='SRMSVC'; StartTime=$since } -ErrorAction Stop
    $fsev | Select-Object -First 10 | ForEach-Object { Write-Host "  FSRM
[$($_.Id)] $($_.TimeCreated) $(($_.Message -split "`n")[0])"
-ForegroundColor Yellow }
} catch { Write-Host '  no FSRM events in the last 2h' }

Write-Section 'F. VERBATIM REPRO of the upgrade extract (splits the phases)'
# The upgrade copies its ZIP to C:\BeatUpgrade and extracts from there, so
on any server
# that already attempted an upgrade a real ZIP is present - find it rather
than ask for it.
# No ZIP (never attempted / cleaned)? Build a synthetic one: this probes
the FILESYSTEM,
# and a same-shaped tree with a real-sized .exe exercises the same rights +
any size/ASR rule.
$zip = Get-ChildItem $stage -Filter '*-windows-x86_64.zip' -File
-ErrorAction SilentlyContinue |
       Sort-Object Length -Descending | Select-Object -First 1
$synth = $null
if ($zip) {
    Write-Host "  using staged ZIP: $($zip.FullName)
($([math]::Round($zip.Length/1MB,1)) MB)"
    $zipPath = $zip.FullName
} else {
    # Peak transient disk for the synthetic path is ~380MB (measured).
Refuse on a tight
    # volume rather than risk filling C: on a SQL box - the other sections
still run.
    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
    if ($freeGB -lt 5) {
        Write-Host "  SKIPPED - only $freeGB GB free on C:; not writing a
~380MB probe. Sections A-E still apply." -ForegroundColor Yellow
        $zipPath = $null
    } else {
        Write-Host "  no staged ZIP found - building a synthetic one
(~380MB transient, $freeGB GB free)" -ForegroundColor DarkGray
        $synth  = New-Artifact (Join-Path $env:TEMP '_diag_synth')
        $inner  = Join-Path $synth 'filebeat-8.19.11-windows-x86_64'
        Remove-Artifact $synth
        New-Item -ItemType Directory -Path (Join-Path $inner 'modules.d')
-Force -ErrorAction SilentlyContinue | Out-Null
        try {
            # Real-sized binary: catches any size- or extension-based block
a stub would miss.
            $fs = [System.IO.File]::Create((Join-Path $inner
'filebeat.exe'))
            $fs.SetLength(190MB); $fs.Close()
            Set-Content (Join-Path $inner 'filebeat.yml') 'x' -ErrorAction
SilentlyContinue
            $zipPath = New-Artifact (Join-Path $env:TEMP '_diag_synth.zip')
            Remove-Artifact $zipPath
            Compress-Archive -Path $inner -DestinationPath $zipPath
-ErrorAction Stop
        } catch {
            Write-Host "  could not build synthetic ZIP:
$($_.Exception.Message)" -ForegroundColor DarkGray
            $zipPath = $null
        }
    }
}
if ($zipPath) {
    # FIXED TEST DESIGN. The previous version extracted ONCE and moved the
same source into
    # Beats\ then BACK OUT, then into Beats\filebeat2\ - so the filebeat2
attempt ran against a
    # source that had already been moved twice, and its DENIED could not be
attributed. Now each
    # destination gets a FRESH extract and is never moved back, so the two
are independent.
    # filebeat2 goes FIRST because it is the destination that actually
failed in the upgrade.
    foreach ($base in @($fb2, $beats)) {
        if (-not (Test-Path $base)) { continue }
        Write-Host "  -- destination: $base" -ForegroundColor Yellow
        $ps = New-Artifact (Join-Path $beats '_diag_staging')
        Remove-Artifact $ps       # fresh staging for THIS destination
        Try-Probe "PHASE1 create staging '$ps'"      { New-Item -ItemType
Directory -Path $ps -Force -ErrorAction Stop }
        Try-Probe "PHASE2 Expand-Archive -> staging" { Expand-Archive
-LiteralPath $zipPath -DestinationPath $ps -Force -ErrorAction Stop }
        $ex = Get-ChildItem $ps -Recurse -File -Filter '*.exe' -ErrorAction
SilentlyContinue | Select-Object -First 1
        if (-not $ex) {
            Write-Host '  PHASE2 produced no .exe - the EXTRACTION itself
was blocked' -ForegroundColor Red
            Remove-Artifact $ps
            continue
        }
        Write-Host "  found exe at: $($ex.FullName)"
        $dd = New-Artifact (Join-Path $base '_diag_dest')
        Remove-Artifact $dd
        $src = $ex.Directory.FullName
        # RETRY on failure: separates a TRANSIENT hold (an AV/EDR handle on
a just-written exe -
        # passes on attempt 2+) from a HARD denial (fails all 3). This is
the discriminator the
        # previous run could not provide.
        $moved = $false
        for ($att = 1; $att -le 3; $att++) {
            try {
                Move-Item -LiteralPath $src -Destination $dd -Force
-ErrorAction Stop
                Write-Host "  OK      PHASE3 Move-Item -> '$dd'  (attempt
$att)" -ForegroundColor Green
                $moved = $true; break
            } catch {
                Write-Host "  DENIED  PHASE3 Move-Item -> '$dd'  (attempt
$att/3)" -ForegroundColor Red
                Write-Host "          type: $($_.Exception.GetType().Name)"
-ForegroundColor DarkGray
                Write-Host "          msg : $($_.Exception.Message)"
-ForegroundColor DarkGray
                if ($att -lt 3) { Start-Sleep -Seconds 3 }
            }
        }
        if ($moved -and $att -gt 1) { Write-Host "          => TRANSIENT
(passed on retry $att) - a handle/scanner, not a permission"
-ForegroundColor Yellow }
        elseif (-not $moved)        { Write-Host '          => HARD DENIAL
(all 3 attempts) - not a timing issue' -ForegroundColor Yellow }
        # No move-back: reusing a moved source is exactly what invalidated
the previous run.
        Remove-Artifact $dd
        Remove-Artifact $ps
    }
}
if ($synth) { Remove-Artifact $synth; Remove-Artifact (Join-Path $env:TEMP
'_diag_synth.zip') }

Write-Section 'CLEANUP VERIFICATION (nothing of ours may survive)'
# Two passes: (1) re-delete every registered artifact, (2) SWEEP the probed
dirs for any
# stray '_diag_*' we did not register. Anything still present is reported
LOUDLY.
foreach ($a in $script:Artifacts) { Remove-Artifact $a }

$survivors = @()
foreach ($a in $script:Artifacts) { if (Test-Path -LiteralPath $a) {
$survivors += $a } }
# Independent sweep - catches anything the registry missed (e.g. a partial
extract).
foreach ($d in @($beats, $fb2, $stage, 'C:\', $env:TEMP, $env:ProgramFiles)
+ $dataDirs + $dataHomes) {
    if (-not (Test-Path $d)) { continue }
    Get-ChildItem -LiteralPath $d -Filter '_diag_*' -Force -ErrorAction
SilentlyContinue |
        ForEach-Object { if ($survivors -notcontains $_.FullName) {
$survivors += $_.FullName } }
}
$survivors = $survivors | Sort-Object -Unique

Write-Host "  artifacts created this run : $($script:Artifacts.Count)"
if ($survivors.Count -eq 0) {
    Write-Host '  CLEANUP OK - nothing left behind.' -ForegroundColor Green
} else {
    Write-Host "  *** CLEANUP FAILED - $($survivors.Count) item(s) STILL
PRESENT ***" -ForegroundColor Red
    foreach ($s in $survivors) {
        $why = 'unknown'
        if (-not (Test-IsOurs $s)) { $why = 'NOT a _diag_ path - refused to
delete (safety guard)' }
        else {
            try { Remove-Item -LiteralPath $s -Recurse -Force -ErrorAction
Stop; $why = 'removed on final retry' }
            catch { $why = $_.Exception.Message }
        }
        Write-Host "    $s" -ForegroundColor Red
        Write-Host "      reason: $why" -ForegroundColor Yellow
    }
    Write-Host '  TELL THE OPERATOR: remove the paths above manually. They
are inert probe' -ForegroundColor Red
    Write-Host '  artifacts (named _diag_*) and are NOT part of any beat
install.' -ForegroundColor Red
}
# Re-verify after the retry above, so the last word is accurate.
$stillThere = @($survivors | Where-Object { Test-Path -LiteralPath $_ })
if ($survivors.Count -and -not $stillThere.Count) {
    Write-Host '  ...all survivors removed on retry - final state CLEAN.'
-ForegroundColor Green
}

Write-Section 'WHAT THIS RUN TOUCHED (full disclosure)'
Write-Host '  Created + deleted (only these):' -ForegroundColor DarkGray
foreach ($a in $script:Artifacts) { Write-Host "    $a" -ForegroundColor
DarkGray }
Write-Host '  Read-only elsewhere: ACLs, services, Defender/AppLocker/WDAC
config, event logs.' -ForegroundColor DarkGray
Write-Host '  No service, ACL, registry, or AV setting was modified.'
-ForegroundColor DarkGray

Write-Section 'FRESHNESS OF THE EVIDENCE'
# Section D2 only looks back 2h and a reboot clears held handles - so say
plainly whether
# this box is still in its failed state, or whether we are looking at a
healed machine.
$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Host "  Last boot: $boot  (up $([int]((Get-Date) -
$boot).TotalHours)h)"
if (((Get-Date) - $boot).TotalHours -lt 2) {
    Write-Host '  WARNING: rebooted recently - held handles are gone and
Defender events may predate it.' -ForegroundColor Yellow
}
$anyTarget = Get-ChildItem $beats -Directory -Filter '*8.19.11*' -Recurse
-ErrorAction SilentlyContinue
if ($anyTarget) {
    Write-Host '  NOTE: 8.19.11 dirs already exist here - this box may be
PARTLY UPGRADED:' -ForegroundColor Yellow
    $anyTarget | ForEach-Object { Write-Host "    $($_.FullName)"
-ForegroundColor DarkGray }
    Write-Host '  If the failing beat was fixed since, the block may no
longer reproduce.' -ForegroundColor Yellow
}

Write-Section 'DONE - send this entire output back'
