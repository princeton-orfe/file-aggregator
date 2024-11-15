# ORFE Photo Aggregator

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
