# ============================================
# Old File Discovery Script
# ============================================
# Ollama inspired and AvA's hardened version 
# Purpose:
# Identifies files older than X hours
# using LastWriteTime (safer in production).
# Outputs results to screen and CSV log.
# ============================================

$directory = "D:\Documents"   # Define production path
$hoursBack = 72
$outputPath = "C:\Users\jasdi\old_files.csv"

if (-not (Test-Path $directory)) {
    Write-Error "Directory does not exist: $directory"
    return
}

$cutoffDate = (Get-Date).AddHours(-$hoursBack)

$files = Get-ChildItem -Path $directory -File -Recurse |
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

if ($files.Count -eq 0) {
    Write-Host "No old files found."
    return
}

foreach ($file in $files) {
    Write-Host "Old file found: $($file.FullName)"
}

$files |
    Select-Object FullName, Length, CreationTime, LastWriteTime |
    Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "Report exported to $outputPath"