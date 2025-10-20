# File Aggregator

This repository contains `file-aggregator.ps1`, a flexible PowerShell utility that searches for files by type and either copies them to a target folder or emits a CSV report.

## Example Scenarios

Search and copy JPEGs to a target folder..

`pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -TargetFolder "/path/to/dest"`

Perform a dry run (no changes) with date filtering for text files.

`pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -TargetFolder "/tmp/dest" -FileTypes txt -DryRun -StartDate "2024-01-01" -EndDate "2024-12-31"`

Produce a CSV report of all `txt` and `log` files.

`pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -Report -ReportPath "/tmp/report.csv" -FileTypes txt,log`

Copy all files and preserve subdirectory structure but avoid overwriting existing files.

`pwsh -File ./file-aggregator.ps1 -SearchBase "/path/to/src" -TargetFolder "/tmp/dest" -PreserveStructure -PreserveExisting`

## Tests

Pester tests live under the `tests/` directory. They create temporary files and validate both report and copy behaviors. Run them with PowerShell (Pester must be available):

```powershell
pwsh -Command "Install-Module -Name Pester -Scope CurrentUser -Force"  # if needed
pwsh -File ./tests/FileAggregator.Tests.ps1
```
