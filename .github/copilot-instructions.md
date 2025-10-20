## Purpose

This repo is a small PowerShell utility (single-script) that finds and aggregates files of various types (such as images) and copies them to a target folder based on dimensions and optional date filters. These instructions explain the project's structure, important implementation details, and concrete examples so an AI coding agent can be productive immediately.

## Big picture (what edits usually touch)
- Single entrypoint: `file-aggregator.ps1` — all logic lives in this file.
- Flow: parameter parsing (param block) → argument validation (`Validate-Arguments`) → file discovery (`Get-ChildItem`) → optional date filtering → image validation (`Is-PortraitOrLandscape`) → copy or dry-run (`Copy-Item` / `Write-Output`).
- README: `README.md` contains usage examples — prefer `file-aggregator.ps1` (actual filename).

## Key implementation details to preserve or consider
- Parameters: `-SearchBase` and `-TargetFolder` are required; `-DryRun`, `-StartDate`, `-EndDate`, `-Help` are optional.
- Validation: `Validate-Arguments` fails fast with `Write-Error` and `exit 1` if required params or paths are missing. Changes that relax this behavior should preserve clear exit codes and user-facing messages.
- Image checks: `Is-PortraitOrLandscape` uses `[System.Drawing.Image]::FromFile($FilePath)` and measures Width/Height. On non-Windows systems this requires a compatible .NET runtime and native GDI+ (e.g., libgdiplus). The function catches exceptions and emits `Write-Warning` and returns `$false` for unreadable files.
- Copy behavior: destination path is created with `Join-Path -ChildPath $file.Name` and `Copy-Item -Force`. This flattens the directory structure and will overwrite files with identical names from different source folders. If you change this behavior, update README and preserve the `-DryRun` semantics.

## Concrete examples (how to run / validate)
- Windows (PowerShell):
  .\file-aggregator.ps1 -SearchBase "C:\Source" -TargetFolder "D:\Destination"
- macOS / Linux (PowerShell Core installed as `pwsh`):
  pwsh -File ./file-aggregator.ps1 -SearchBase "/Users/me/Pictures" -TargetFolder "/tmp/dest" -DryRun
- Dry-run is the primary quick test. Look for lines beginning with `Dry Run:` in output.

## Common edits and where to look
- Add new CLI options: update the `param` block at file top, then update `Show-Help` text (help string lives in the script). Also update `README.md` examples.
- Change image processing: edit `Is-PortraitOrLandscape`. Be mindful of cross-platform dependencies (System.Drawing) and the current behavior of catching exceptions and warning.
- Preserve output functions: script uses `Write-Output`, `Write-Warning`, and `Write-Error`. Tests or logging changes should respect these channels.

## Observed repo “idiosyncrasies” and gotchas
- README vs actual file name: README examples should reference `file-aggregator.ps1`.
- Flat copy & overwrites: the script copies files using only the filename (no subfolders). This means identical filenames from different directories will overwrite each other at the destination.
- Platform dependencies: `System.Drawing.Image` calls may fail on non-Windows unless native support (libgdiplus) is installed; the script handles failures by warning and skipping files but CI or tests that rely on image inspection may be flaky on macOS/Linux.

## Debugging tips (what to run and what to look for)
- Fast validation: run with `-DryRun` and appropriate date filters to confirm discovery and filtering without changing files.
- Image failures: search script output for `Unable to process file` warnings — those come from the `catch` block in `Is-PortraitOrLandscape`.
- Overwrite checks: run two source folders that contain same filename and verify destination to confirm current overwrite behavior.

## Files of interest
`file-aggregator.ps1` — primary source of truth for behavior and CLI.
- `README.md` — user-facing examples and parameter descriptions (update when changing CLI).
- `LICENSE.md` — MIT license (keep intact if adding new files).

If anything in these notes is unclear or you want me to expand any section (for example: add an automated test harness suggestion or add cross-platform image processing notes), tell me which area to expand and I will iterate.
