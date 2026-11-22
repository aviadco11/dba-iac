#Requires -Version 5.1
<#
.SYNOPSIS
    Unpacks a .txt archive created by Merge-Files.ps1, verifying each file's
    SHA-256 checksum and rebuilding the original directory tree exactly.

.PARAMETER ArchivePath
    Path to the archive .txt file (required).

.PARAMETER OutputPath
    Root directory to restore files into (required).
    Sub-directories are created automatically.

.PARAMETER Force
    Overwrite existing files without prompting.

.EXAMPLE
    .\Split-Files.ps1 -ArchivePath C:\Backups\pbs.txt -OutputPath
C:\Restored
    .\Split-Files.ps1 -ArchivePath .\PostBuildScripts_archive.txt
-OutputPath C:\PostBuildScripts -Force
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ArchivePath,
    [Parameter(Mandatory)] [string]$OutputPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SHA256Hex {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try   { [System.BitConverter]::ToString($sha.ComputeHash($Bytes))
-replace '-' }
    finally { $sha.Dispose() }
}

# --- Load archive ---

$archivePath = (Resolve-Path $ArchivePath).Path
$allLines    = [System.IO.File]::ReadAllLines($archivePath,
[System.Text.Encoding]::UTF8)

Write-Host "Archive : $archivePath  ($($allLines.Count) lines)"
Write-Host "Output  : $OutputPath"
Write-Host ''

# --- Parse archive header ---

$boundary  = $null
$fileCount = 0
$idx       = 0

for (; $idx -lt $allLines.Count; $idx++) {
    $hl = $allLines[$idx]
    if     ($hl -match '^BOUNDARY:\s+(\S+)')    { $boundary  = $Matches[1] }
    elseif ($hl -match '^FILE_COUNT:\s+(\d+)')  { $fileCount [int]$Matches[1] }
    elseif ($boundary -and $hl -eq "${boundary}:HEADER_END") { $idx++;
break }
}

if (-not $boundary) {
    throw "Archive header is missing or corrupt - BOUNDARY not found."
}

# Token that marks an escaped content line (written by Merge-Files.ps1 to
prevent
# a file's own content from colliding with a structural boundary marker)
$escapeToken  = "${boundary}:ESCAPED:"
$escapeLength = $escapeToken.Length

Write-Host "Boundary : $boundary"
Write-Host "Expected : $fileCount file(s)"
Write-Host ''

$extracted = 0
$errCount  = 0

# --- Main extraction loop ---

while ($idx -lt $allLines.Count) {

    # Skip blank separator lines between entries
    if ([string]::IsNullOrEmpty($allLines[$idx])) { $idx++; continue }

    if ($allLines[$idx] -ne "${boundary}:FILE_BEGIN") {
        Write-Warning "Unexpected content at line $($idx + 1):
$($allLines[$idx])"
        $idx++; continue
    }
    $idx++  # consume FILE_BEGIN

    # --- Metadata block ---
    $meta = @{}
    while ($idx -lt $allLines.Count) {
        $ml = $allLines[$idx]
        # Stop at CONTENT_BEGIN; also guard against a malformed entry
running into the next
        if ($ml -eq "${boundary}:CONTENT_BEGIN" -or
            $ml -eq "${boundary}:FILE_END"       -or
            $ml -eq "${boundary}:FILE_BEGIN") { break }
        if ($ml -match '^([^:]+):\s*(.*)$') {
            $meta[$Matches[1].Trim()] = $Matches[2].Trim()
        }
        $idx++
    }

    if ($idx -ge $allLines.Count -or $allLines[$idx] -ne
"${boundary}:CONTENT_BEGIN") {
        Write-Error "Entry '$($meta['Path'])': CONTENT_BEGIN marker not
found. Skipping."
        $errCount++; continue
    }
    $idx++  # consume CONTENT_BEGIN

    # --- Content lines ---
    $contentLines = [System.Collections.Generic.List[string]]::new()
    while ($idx -lt $allLines.Count -and $allLines[$idx] -ne
"${boundary}:FILE_END") {
        $contentLines.Add($allLines[$idx])
        $idx++
    }

    if ($idx -ge $allLines.Count) {
        Write-Error "Entry '$($meta['Path'])': FILE_END marker not found -
archive may be truncated."
        $errCount++; continue
    }
    $idx++  # consume FILE_END

    # --- Validate required fields ---
    $relPath  = $meta['Path']
    $encoding = $meta['Encoding']
    $checksum = $meta['Checksum'] -replace '^SHA256:', ''

    if (-not $relPath) {
        Write-Error "Entry at line $idx is missing required Path field.
Skipping."
        $errCount++; continue
    }
    if (-not $encoding -or -not $checksum) {
        Write-Error "Entry '$relPath' is missing Encoding or Checksum.
Skipping."
        $errCount++; continue
    }

    # --- Reconstruct original bytes ---
    [byte[]]$fileBytes = $null
    try {
        if ($encoding -eq 'Base64') {
            $b64       = [string]::Join('', $contentLines) -replace '\s', ''
            $fileBytes = [Convert]::FromBase64String($b64)
        }
        elseif ($encoding -eq 'UTF8') {
            $nlMode  = if ($meta['NewlineMode'])     { $meta['NewlineMode']
}     else { 'LF' }
            $trailNl = $meta['TrailingNewline'] -eq 'true'

            $nl = switch ($nlMode) {
                'CRLF' { "`r`n" }
                'CR'   { "`r"   }
                default { "`n"  }
            }

            # Unescape any lines that were escaped to avoid boundary
collision
            $unescaped = [System.Collections.Generic.List[string]]::new()
            foreach ($cl in $contentLines) {
                if ($cl.StartsWith($escapeToken)) {
                    $unescaped.Add($cl.Substring($escapeLength))
                }
                else {
                    $unescaped.Add($cl)
                }
            }

            $text = [string]::Join($nl, $unescaped)
            if ($trailNl) { $text += $nl }

            $fileBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        }
        else {
            Write-Error "Unknown encoding '$encoding' for '$relPath'.
Skipping."
            $errCount++; continue
        }
    }
    catch {
        Write-Error "Failed to decode '$relPath': $_"
        $errCount++; continue
    }

    # --- Integrity check ---
    $computed = Get-SHA256Hex $fileBytes
    if ($computed -ne $checksum) {
        Write-Error (
            "CHECKSUM MISMATCH: $relPath`n" +
            "  Expected : $checksum`n" +
            "  Computed : $computed"
        )
        $errCount++; continue
    }

    # --- Write to disk ---
    $destPath = Join-Path $OutputPath $relPath
    $destDir  = Split-Path $destPath -Parent

    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $destPath) -and -not $Force) {
        $resp = Read-Host "  Overwrite '$relPath'? [Y/N]"
        if ($resp -notmatch '^[Yy]') {
            Write-Host "  SKIP   $relPath"
            continue
        }
    }

    [System.IO.File]::WriteAllBytes($destPath, $fileBytes)
    $extracted++
    Write-Host ("  OK     {0}  ({1:N0} B)" -f $relPath, $fileBytes.Length)
}

# --- Summary ---

Write-Host ''
Write-Host "Extracted : $extracted / $fileCount"
if ($errCount -gt 0) {
    Write-Warning "Errors    : $errCount  (review output above for details)"
    exit 1
}
else {
    Write-Host "Errors    : 0 - all checksums verified OK"
}
