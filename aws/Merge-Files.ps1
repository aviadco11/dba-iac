#Requires -Version 5.1
<#
.SYNOPSIS
    Merges every file under SourcePath into a single .txt archive.
    Text files are embedded as readable UTF-8; binary/non-UTF-8 files as
Base64.
    Each entry records its relative path, encoding, and SHA-256 checksum.
    Restore with:  Split-Files.ps1 -ArchivePath <file> -OutputPath <dir>

.PARAMETER SourcePath
    Root directory to archive. Default: C:\PostBuildScripts

.PARAMETER OutputPath
    Destination .txt file.
    Default: <parent of SourcePath>\<dir-name>_archive.txt

.EXAMPLE
    .\Merge-Files.ps1
    .\Merge-Files.ps1 -SourcePath C:\PostBuildScripts -OutputPath
C:\Backups\pbs.txt
#>
[CmdletBinding()]
param(
    [string]$SourcePath = 'C:\PostBuildScripts',
    [string]$OutputPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ---

function Get-SHA256Hex {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try   { [System.BitConverter]::ToString($sha.ComputeHash($Bytes))
-replace '-' }
    finally { $sha.Dispose() }
}

function Test-BinaryFile {
    param([byte[]]$Bytes)

    # Fast path: null byte anywhere in first 8 KB means binary
    $limit = [Math]::Min($Bytes.Length, 8192)
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Bytes[$i] -eq 0) { return $true }
    }

    # UTF-8 validity check: if the bytes can't survive a strict UTF-8
round-trip, treat as binary
    try {
        $strict = [System.Text.Encoding]::GetEncoding(
            'utf-8',
            [System.Text.EncoderFallback]::ExceptionFallback,
            [System.Text.DecoderFallback]::ExceptionFallback
        )
        [void]$strict.GetString($Bytes)
        return $false   # valid UTF-8 text
    }
    catch { return $true }  # invalid UTF-8 -> binary
}

# --- Resolve paths ---

$source = (Resolve-Path $SourcePath).Path.TrimEnd('\')

if (-not $OutputPath) {
    $OutputPath = Join-Path (Split-Path $source -Parent) "$(Split-Path
$source -Leaf)_archive.txt"
}
$absOutput = [System.IO.Path]::GetFullPath($OutputPath)

# Enumerate files, excluding the output file itself to avoid self-inclusion
$files = @(
    Get-ChildItem -LiteralPath $source -Recurse -File |
    Where-Object { [System.IO.Path]::GetFullPath($_.FullName) -ne
$absOutput }
)

# --- Boundary ---
# 32 uppercase hex chars (UUID v4); collision probability ~2^-128 per line.
# Any content line starting with "<boundary>:" is escaped by prepending
# "<boundary>:ESCAPED:" so it can never be misread as a structural marker.
$boundary    = [Guid]::NewGuid().ToString('N').ToUpper()
$escapeToken = "${boundary}:ESCAPED:"  # prepended to escaped content lines

Write-Host "Source   : $source"
Write-Host "Archive  : $absOutput"
Write-Host "Files    : $($files.Count)"
Write-Host ''

# --- Write archive ---

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$writer    = [System.IO.StreamWriter]::new($absOutput, $false, $utf8NoBom)
try {
    $writer.NewLine = "`r`n"   # archive wrapper always uses CRLF

    # Archive header
    $writer.WriteLine('ARCHIVE_VERSION: 1.0')
    $writer.WriteLine("BOUNDARY: $boundary")
    $writer.WriteLine("SOURCE: $source")
    $writer.WriteLine("FILE_COUNT: $($files.Count)")
    $writer.WriteLine("CREATED: $(Get-Date -Format 'o')")
    $writer.WriteLine("${boundary}:HEADER_END")
    $writer.WriteLine()

    $n = 0
    foreach ($f in $files) {
        $rel      = $f.FullName.Substring($source.Length).TrimStart('\')
        $rawBytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $hash     = Get-SHA256Hex $rawBytes
        $isBin    = Test-BinaryFile $rawBytes

        $writer.WriteLine("${boundary}:FILE_BEGIN")
        $writer.WriteLine("Path: $rel")
        $writer.WriteLine("Checksum: SHA256:$hash")
        $writer.WriteLine("OriginalSize: $($rawBytes.Length)")

        if ($isBin) {
            # Binary entry stored as Base64
            $writer.WriteLine('Encoding: Base64')
            $writer.WriteLine("${boundary}:CONTENT_BEGIN")
            $writer.WriteLine(
                [Convert]::ToBase64String($rawBytes,
[System.Base64FormattingOptions]::InsertLineBreaks)
            )
        }
        else {
            # Text entry stored as UTF-8, human-readable
            $text = [System.Text.Encoding]::UTF8.GetString($rawBytes)

            # Detect original newline convention.
            # Mixed line endings (some CRLF, some bare LF, etc.) cannot be
round-tripped
            # through line-based normalisation, so fall back to Base64 for
those files.
            $hasCRLF   = $text -match '\r\n'
            $hasLFOnly = ($text -replace '\r\n', '') -match '\n'
            $hasBareCR = ($text -replace '\r\n', '') -match '\r'
            $mixedNL   = ($hasCRLF -and ($hasLFOnly -or $hasBareCR)) -or
($hasLFOnly -and $hasBareCR)

            if ($mixedNL) {
                # Store as Base64 to preserve mixed line endings
byte-for-byte
                $writer.WriteLine('Encoding: Base64')
                $writer.WriteLine("${boundary}:CONTENT_BEGIN")
                $writer.WriteLine(
                    [Convert]::ToBase64String($rawBytes,
[System.Base64FormattingOptions]::InsertLineBreaks)
                )
                $writer.WriteLine("${boundary}:FILE_END")
                $writer.WriteLine()
                $n++
                Write-Host ("  {0,$(("$($files.Count)").Length)}/{1}  [B64]
 {2}  (mixed newlines)" -f $n, $files.Count, $rel)
                continue
            }

            $nlMode = if ($hasCRLF) { 'CRLF' } elseif ($hasBareCR) { 'CR' }
else { 'LF' }

            $trailingNl = $text.Length -gt 0 -and ($text[-1] -eq "`n" -or
$text[-1] -eq "`r")

            # Normalise to LF for line-based storage in the archive
            $norm  = $text -replace '\r\n', "`n" -replace '\r', "`n"
            $lines = $norm -split "`n"

            # -split on a string ending with \n produces a phantom trailing
empty element; remove it
            if ($trailingNl -and $lines.Count -gt 0 -and $lines[-1] -eq '')
{
                $lines = $lines[0..($lines.Count - 2)]
            }

            $writer.WriteLine('Encoding: UTF8')
            $writer.WriteLine("NewlineMode: $nlMode")
            $writer.WriteLine("TrailingNewline:
$($trailingNl.ToString().ToLower())")
            $writer.WriteLine("${boundary}:CONTENT_BEGIN")

            foreach ($line in $lines) {
                # Escape any line that starts with the boundary prefix to
prevent marker collisions
                if ($line.StartsWith("${boundary}:")) {
                    $writer.WriteLine("${escapeToken}$line")
                }
                else {
                    $writer.WriteLine($line)
                }
            }
        }

        $writer.WriteLine("${boundary}:FILE_END")
        $writer.WriteLine()

        $n++
        $tag = if ($isBin) { '[BIN]' } else { '[TXT]' }
        Write-Host ("  {0,$(("$($files.Count)").Length)}/{1}  {2}  {3}" -f
$n, $files.Count, $tag, $rel)
    }
}
finally {
    $writer.Flush()
    $writer.Dispose()
}

$sz = (Get-Item $absOutput).Length
Write-Host ''
Write-Host ("Complete. {0} file(s) archived -> {1}  ({2:N1} KB)" -f
$files.Count, $absOutput, ($sz / 1KB))
