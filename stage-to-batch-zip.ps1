$sourcePath = "C:\Users"
$stagingPath = "D:\Staging-Collection"
$zipPath = $zipPath = "D:\Forensics\Collection\Range-Collection-$(Get-Date -Format yyyy-MM-dd_HH-mm).zip"

$logFile = "D:\Range-Collection-Log.txt"

# Create staging folder
New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

# Find files modified in last 24 hours
$files = Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) }

# Log them
$files.FullName | Out-File $logFile

# Copy to staging
foreach ($file in $files) {
    Copy-Item $file.FullName -Destination $stagingPath -Force -ErrorAction SilentlyContinue
}

# Compress staging folder
Compress-Archive -Path "$stagingPath\*" -DestinationPath $zipPath -Force

# Cleanup staging
Remove-Item $stagingPath -Recurse -Force

Write-Host "Collection complete:"
Write-Host $zipPath
Write-Host "Log saved to:"
Write-Host $logFile
