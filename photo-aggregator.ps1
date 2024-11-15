param (
    [string]$SearchBase,         # The base folder to search for JPEGs
    [string]$TargetFolder,       # The destination folder to copy the JPEGs
    [switch]$DryRun,             # If present, only list what would be copied
    [datetime]$StartDate,        # Optional: Filter files last modified on or after this date
    [datetime]$EndDate           # Optional: Filter files last modified on or before this date
)

# Function to validate input arguments
function Validate-Arguments {
    if (-not $SearchBase) {
        Write-Error "SearchBase is required but was not provided."
        exit 1
    }
    if (-not $TargetFolder) {
        Write-Error "TargetFolder is required but was not provided."
        exit 1
    }
    if (-not (Test-Path -Path $SearchBase)) {
        Write-Error "SearchBase '$SearchBase' does not exist or is not accessible."
        exit 1
    }
    if (-not (Test-Path -Path $TargetFolder)) {
        Write-Error "TargetFolder '$TargetFolder' does not exist or is not accessible."
        exit 1
    }
}

# Function to determine if a file meets typical portrait or landscape dimensions
function Is-PortraitOrLandscape {
    param (
        [string]$FilePath
    )

    try {
        $image = [System.Drawing.Image]::FromFile($FilePath)
        $isValid = ($image.Width -ge 800 -and $image.Height -ge 600) -or `
                   ($image.Width -ge 600 -and $image.Height -ge 800)
        $image.Dispose()
        return $isValid
    } catch {
        Write-Warning "Unable to process file: $FilePath. $_"
        return $false
    }
}

# Validate input arguments
Validate-Arguments

# Search for files
$files = Get-ChildItem -Path $SearchBase -Recurse -File -Include *.jpg, *.jpeg

if ($StartDate) {
    $files = $files | Where-Object { $_.LastWriteTime -ge $StartDate }
}

if ($EndDate) {
    $files = $files | Where-Object { $_.LastWriteTime -le $EndDate }
}

if ($files.Count -eq 0) {
    Write-Output "No JPEG files found in the search base '$SearchBase' with the specified criteria."
    exit 0
}

# Process files
foreach ($file in $files) {
    if (Is-PortraitOrLandscape -FilePath $file.FullName) {
        $destinationPath = Join-Path -Path $TargetFolder -ChildPath $file.Name

        if ($DryRun) {
            Write-Output "Dry Run: Would copy '$($file.FullName)' to '$destinationPath'."
        } else {
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            Write-Output "Copied '$($file.FullName)' to '$destinationPath'."
        }
    }
}
