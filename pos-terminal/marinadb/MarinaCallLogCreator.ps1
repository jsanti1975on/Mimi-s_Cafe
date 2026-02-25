# ============================================
# Marina Call Log Creator (Production)
# ============================================
# Purpose:
# Creates a standardized call log record
# and appends entry to SlipMasterIndex.csv
#
# Author: Jason
# ============================================

Clear-Host

# -------- CONFIGURATION --------
$RootPath = "D:\01_CUSTOMER_SERVICE_SPECIALIST\01_marinaDB\"
$IndexFile = Join-Path $RootPath "SlipMasterIndex.csv"

# -------- USER INPUT --------
$SlipInput = Read-Host "Enter Slip Number (example: 33)"
$TenantName = Read-Host "Enter Tenant Name"
$Subject = Read-Host "Enter Subject (example: Boat Show)"
$Summary = Read-Host "Enter Summary of Call"

# -------- FORMAT SLIP NUMBER --------
try {
    $SlipNumber = [int]$SlipInput
    $SlipFormatted = $SlipNumber.ToString("D3")
}
catch {
    Write-Host "Invalid Slip Number. Exiting." -ForegroundColor Red
    exit
}

# -------- BUILD PATH --------
$SlipFolder = Join-Path $RootPath ("SLIP_$SlipFormatted")
$OtherFolder = Join-Path $SlipFolder "Other"

if (!(Test-Path $OtherFolder)) {
    New-Item -ItemType Directory -Path $OtherFolder -Force | Out-Null
}

# -------- FILE NAME --------
$DateStamp = Get-Date -Format "yyyy-MM-dd"
$SafeSubject = $Subject -replace '[^a-zA-Z0-9]', '_'
$FileName = "$DateStamp" + "_Slip$SlipFormatted" + "_$SafeSubject.txt"
$FilePath = Join-Path $OtherFolder $FileName

if (Test-Path $FilePath) {
    Write-Host "File already exists. No overwrite performed." -ForegroundColor Yellow
    exit
}

# -------- BUILD CALL LOG CONTENT --------
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$Content = @"
Marina Communication Record
----------------------------------------
Slip Number : $SlipFormatted
Tenant Name : $TenantName
Date        : $TimeStamp
Subject     : $Subject

Summary:
$Summary

Recorded By : $env:USERNAME
----------------------------------------
"@

$Content | Out-File -FilePath $FilePath -Encoding UTF8

Write-Host "Call log saved to $FilePath" -ForegroundColor Green

# -------- APPEND TO CSV INDEX --------

if (!(Test-Path $IndexFile)) {
    "SlipNumber,TenantName,DocumentType,FileName,RelativePath,CreatedTime,Notes,Status" |
        Out-File $IndexFile -Encoding UTF8
}

$RelativePath = "SLIP_$SlipFormatted\Other\$FileName"

$CsvLine = "$SlipFormatted,$TenantName,Call Log,$FileName,$RelativePath,$TimeStamp,$Subject,Active"

Add-Content -Path $IndexFile -Value $CsvLine

Write-Host "SlipMasterIndex updated." -ForegroundColor Cyan
Write-Host "Operation complete." -ForegroundColor Green
