param (
    [string]$SearchBase,
    [string]$TargetFolder,
    [string[]]$FileTypes = @('jpg','jpeg'),
    [switch]$DryRun,
    [datetime]$StartDate,
    [datetime]$EndDate,
    [switch]$Report,
    [string]$ReportPath,
    [switch]$NoImageDimensionFilter,
    [switch]$PreserveStructure,
    [switch]$PreserveExisting,
    [switch]$Help
)

function Show-Help {
    Write-Output @"
Usage: file-aggregator.ps1 -SearchBase <path> [-TargetFolder <path>] [-FileTypes <exts>] [-Report -ReportPath <file.csv>] [-DryRun] [-StartDate <date>] [-EndDate <date>] [-NoImageDimensionFilter]

This script searches for files by extensions and either copies them to a target folder or emits a CSV report (with LastAccessTime).
"@
}

if ($Help -or (-not $PSBoundParameters)) {
    Show-Help
    exit 0
}

function Validate-Arguments {
    if (-not $SearchBase) {
        Write-Error "SearchBase is required but was not provided."
        exit 1
    }

    if (-not (Test-Path -Path $SearchBase)) {
        Write-Error "SearchBase '$SearchBase' does not exist or is not accessible."
        exit 1
    }

    if ($Report) {
        if (-not $ReportPath) {
            Write-Error "ReportPath is required when -Report is specified."
            exit 1
        }
    } else {
        if (-not $TargetFolder) {
            Write-Error "TargetFolder is required unless -Report is specified."
            exit 1
        }
        if (-not (Test-Path -Path $TargetFolder)) {
            Write-Error "TargetFolder '$TargetFolder' does not exist or is not accessible."
            exit 1
        }
    }
}

function Is-PortraitOrLandscape {
    param ([string]$FilePath)
    if ($NoImageDimensionFilter) { return $true }
    try {
        $image = [System.Drawing.Image]::FromFile($FilePath)
        $isValid = ($image.Width -ge 800 -and $image.Height -ge 600) -or ($image.Width -ge 600 -and $image.Height -ge 800)
        $image.Dispose()
        return $isValid
    } catch {
        Write-Warning "Unable to process file: $FilePath. $_"
        return $false
    }
}

Validate-Arguments

# Normalize SearchBase path and TargetFolder
$SearchBase = [IO.Path]::GetFullPath($SearchBase)
if ($TargetFolder) { $TargetFolder = [IO.Path]::GetFullPath($TargetFolder) }

# Build file include patterns
$searchPatterns = @()
foreach ($ext in $FileTypes) {
    $clean = $ext.Trim().TrimStart('.')
    if ($clean.Length -gt 0) { $searchPatterns += "*.$clean" }
}

$files = Get-ChildItem -Path $SearchBase -Recurse -File -Include $searchPatterns -ErrorAction SilentlyContinue

if ($StartDate) { $files = $files | Where-Object { $_.LastWriteTime -ge $StartDate } }
if ($EndDate) { $files = $files | Where-Object { $_.LastWriteTime -le $EndDate } }

if ($files.Count -eq 0) {
    Write-Output "No files found in the search base '$SearchBase' with the specified criteria."
    exit 0
}

if ($Report) {
    $reportRows = @()
    foreach ($file in $files) {
        $include = $true
        $ext = $file.Extension.TrimStart('.').ToLower()
        if ($ext -in @('jpg','jpeg','png','gif')) {
            # For image types, optionally apply dimension filter
            if (-not (Is-PortraitOrLandscape -FilePath $file.FullName)) { $include = $false }
        }

        if ($include) {
            $reportRows += [PSCustomObject]@{
                FullName = $file.FullName
                Name = $file.Name
                Length = $file.Length
                LastWriteTime = $file.LastWriteTime
                LastAccessTime = $file.LastAccessTime
            }
        }
    }

    if ($reportRows.Count -eq 0) {
        Write-Output "No matching files to report."
        exit 0
    }

    $dir = Split-Path -Parent $ReportPath
    if (-not (Test-Path -Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $reportRows | Export-Csv -Path $ReportPath -NoTypeInformation -Force
    Write-Output "Report written to $ReportPath"
    exit 0
}

# Normal copy mode
foreach ($file in $files) {
    $include = $true
    $ext = $file.Extension.TrimStart('.').ToLower()
    if ($ext -in @('jpg','jpeg','png','gif')) {
        if (-not (Is-PortraitOrLandscape -FilePath $file.FullName)) { $include = $false }
    }

    if ($include) {
        # Compute destination path
        if ($PreserveStructure) {
            # Build destination path preserving subdirectory structure relative to SearchBase
            $searchBaseFull = [IO.Path]::GetFullPath($SearchBase).TrimEnd('\','/')
            $fileFull = [IO.Path]::GetFullPath($file.FullName)
            # On Windows perform case-insensitive compare
            if ($IsWindows) {
                $starts = $fileFull.ToLowerInvariant().StartsWith($searchBaseFull.ToLowerInvariant())
            } else {
                $starts = $fileFull.StartsWith($searchBaseFull)
            }
            if ($starts) {
                $relative = $fileFull.Substring($searchBaseFull.Length).TrimStart('\','/')
            } else {
                $relative = $file.Name
            }
            $destinationPath = Join-Path -Path $TargetFolder -ChildPath $relative
            $destDir = Split-Path -Parent $destinationPath
            if (-not (Test-Path -Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        } else {
            $destinationPath = Join-Path -Path $TargetFolder -ChildPath $file.Name
        }

        # If destination exists and PreserveExisting is set, choose a new name (do not overwrite)
        if (Test-Path -Path $destinationPath) {
            if ($PreserveExisting) {
                # Use timestamp suffix to avoid collisions: base_yyyyMMddHHmmss.ext
                $dir = Split-Path -Parent $destinationPath
                $base = [IO.Path]::GetFileNameWithoutExtension($destinationPath)
                $extn = [IO.Path]::GetExtension($destinationPath)
                $ts = (Get-Date).ToString('yyyyMMddHHmmss')
                $candidate = Join-Path $dir ("${base}_$ts$extn")
                # If collision still occurs (unlikely), append a counter
                $i = 1
                while (Test-Path -Path $candidate) {
                    $candidate = Join-Path $dir ("${base}_$ts_$i$extn")
                    $i++
                }
                $destinationPath = $candidate
            }
        }

        if ($DryRun) {
            Write-Output "Dry Run: Would copy '$($file.FullName)' to '$destinationPath'."
        } else {
            if ($PreserveExisting) {
                Copy-Item -Path $file.FullName -Destination $destinationPath -ErrorAction Stop
            } else {
                Copy-Item -Path $file.FullName -Destination $destinationPath -Force -ErrorAction Stop
            }
            Write-Output "Copied '$($file.FullName)' to '$destinationPath'."
        }
    }
}
