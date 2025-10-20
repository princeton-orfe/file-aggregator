# File Aggregator

This repository contains `file-aggregator.ps1`, a flexible PowerShell utility that searches for files by type and either copies them to a target folder or emits a CSV report.

Features:
- Search by file extensions (e.g. jpg, png, txt, csv).
```

1. Search and copy JPEGs (preserves original behavior):
   `pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -TargetFolder "/path/to/dest"`

2. Perform a dry run with date filtering for text files:
   `pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -TargetFolder "/tmp/dest" -FileTypes txt -DryRun -StartDate "2024-01-01" -EndDate "2024-12-31"`

3. Produce a CSV report (includes LastAccessTime):
   `pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -Report -ReportPath "/tmp/report.csv" -FileTypes txt,log`

4. Disable image dimension filtering (useful for synthetic/empty JPEG files):
   `pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -TargetFolder "/tmp/dest" -NoImageDimensionFilter`

5. Preserve subdirectory structure and avoid overwriting existing files:
   `pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -TargetFolder "/tmp/dest" -PreserveStructure -PreserveExisting`

## Tests

Pester tests live under the `tests/` directory. They create temporary files and validate both report and copy behaviors. Run them with PowerShell (Pester must be available):

```powershell
pwsh -Command "Install-Module -Name Pester -Scope CurrentUser -Force"  # if needed
pwsh -File ./tests/FileAggregator.Tests.ps1
```
# Photo Aggregator

This script searches recursively for JPEG files in a specified directory and copies them to a target directory.
Only JPEG files with common portrait or landscape dimensions are considered.
    
## Parameters

```
 -SearchBase <string>  : The base directory to search for JPEG files. Required.
 -TargetFolder <string>: The destination directory where files will be copied. Required.
 -DryRun               : (Optional) If specified, lists files that would be copied without actually copying them.
 -StartDate <datetime> : (Optional) Filters files modified on or after this date.
 -EndDate <datetime>   : (Optional) Filters files modified on or before this date.
 -Help                 : Displays this help message.
```

## Usage Examples

  1. Search and copy JPEGs:
       `.\photo-aggregator.ps1 -SearchBase "C:\Source" -TargetFolder "D:\Destination"`

  2. Perform a dry run with date filtering:
     `.\photo-aggregator.ps1 -SearchBase "C:\Source" -TargetFolder "D:\Destination" -DryRun -StartDate "2024-01-01" -EndDate "2024-12-31"`

  3. Display help:
       `.\photo-aggregator.ps1 -Help`
