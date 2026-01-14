<#
.SYNOPSIS
    Recursively audits a fiscal year directory structure for required reports.

.DESCRIPTION
    Scans all daily folders within a fiscal year directory to:
        - Validate required OS daily report files
        - Detect fuzzy or misnamed files created by staff
        - Identify Pavilion / Rental / FPO / Refund documents
        - Produce console feedback and a CSV audit summary

.CONTEXT
    This script supports financial reconciliation, CPA reporting, and exception review
    in the Mimi’s Café | POS_Workgroup environment. It is typically executed from
    the shared POS workstation or automation account on the file server.

.EXAMPLE
    .\OS_FiscalYear_DailyReport_UnifiedScan.ps1 -RootPath "I:\FY2025-2026"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RootPath
)

# ======================================================================
# CONFIGURATION
# ======================================================================
$CSV_Output = Join-Path $RootPath ("OS_FiscalYear_Audit_" + (Get-Date -Format "yyyy-MM-dd_HHmmss") + ".csv")

# Required report base names
$RequiredReports = @(
    "OS BACKUP",
    "OS CASH FLOW REPORT",
    "OS TAX REPORT"
)

# Key operational or exception terms to flag
$SpecialKeywords = @("PAVILION","RENTAL","FPO","REFUND")

# Common fuzzy or incorrect name patterns per report
$FuzzyRules = @{
    "OS BACKUP"           = @("backup","back-up","back up","bkup","bkp")
    "OS CASH FLOW REPORT" = @("cash","cashflow","cash flow","cash-flow","flow")
    "OS TAX REPORT"       = @("tax","tax report","tax-report")
}

# Folder naming standard
$DailyFolderPattern = "^OS\s\d{2}-\d{2}-\d{4}$"

Write-Host "`n===== Starting Fiscal Year Daily Report Audit =====" -ForegroundColor Cyan
Write-Host "Root Path: $RootPath" -ForegroundColor Yellow
Write-Host "Report Output: $CSV_Output`n" -ForegroundColor Yellow

# ======================================================================
# INITIALIZE STORAGE
# ======================================================================
$SummaryRows     = @()
$InvalidDayCount = 0
$TotalFolders    = 0

# ======================================================================
# LOCATE DAILY FOLDERS
# ======================================================================
$DailyFolders = Get-ChildItem -Path $RootPath -Directory -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $DailyFolderPattern } |
                Sort-Object FullName

if (-not $DailyFolders) {
    Write-Host "No valid daily folders found under $RootPath" -ForegroundColor Red
    exit
}

# ======================================================================
# MAIN SCAN LOOP
# ======================================================================
foreach ($folder in $DailyFolders) {
    $TotalFolders++
    Write-Host "-------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "📂 Scanning Folder: $($folder.FullName)" -ForegroundColor Yellow

    $datePart = $folder.Name.Substring(3)

    # Gather files (PDF/XPS/OXPS)
    $files = Get-ChildItem -Path $folder.FullName -File -ErrorAction SilentlyContinue |
             Where-Object { $_.Extension -match '^(?i)\.(pdf|xps|oxps)$' }

    $missing      = @()
    $foundCount   = 0
    $SpecialFlags = @()

    # ---------------- REQUIRED FILE VALIDATION ----------------
    foreach ($req in $RequiredReports) {
        # 1. Perfect match
        if ($files | Where-Object { $_.BaseName -like "$req*" }) {
            Write-Host "  ✔ Found Required: $req" -ForegroundColor Green
            $foundCount++
            continue
        }

        # 2. Fuzzy name match
        $patterns = $FuzzyRules[$req]
        $fuzzy = $files | Where-Object {
            foreach ($p in $patterns) {
                if ($_.BaseName -match $p) { return $true }
            }
            return $false
        }

        if ($fuzzy) {
            foreach ($f in $fuzzy) {
                Write-Host "  ⚠ Found (Nonstandard): $($f.Name)" -ForegroundColor DarkYellow
                Write-Host "    ↳ Expected: $req $datePart.pdf" -ForegroundColor Gray
            }
            $foundCount++
            continue
        }

        # 3. Missing report entirely
        Write-Host "  ❌ Missing Required Report: $req" -ForegroundColor Red
        Write-Host "    ↳ Expected: $req $datePart.pdf" -ForegroundColor DarkGray
        $missing += $req
    }

    # ---------------- SPECIAL DOCUMENT DETECTION ----------------
    foreach ($keyword in $SpecialKeywords) {
        $foundSpecial = $files | Where-Object { $_.Name -match $keyword }
        if ($foundSpecial) {
            foreach ($fs in $foundSpecial) {
                Write-Host "  🔹 Found Special Document: $($fs.Name)" -ForegroundColor Cyan
            }
            $SpecialFlags += $keyword
        }
    }

    # ---------------- STATUS LOGIC ----------------
    if ($missing.Count -eq 0) {
        $Status = "OK"
        Write-Host "  ✅ STATUS: OK" -ForegroundColor Green
    }
    else {
        $Status = "INVALID — REQUIRED REPORTS MISSING"
        Write-Host "  🚫 STATUS: INVALID — REQUIRED REPORTS MISSING" -ForegroundColor Red
        $InvalidDayCount++
    }

    # ---------------- BUILD CSV RECORD ----------------
    $SummaryRows += [pscustomobject]@{
        FolderName     = $folder.Name
        FolderPath     = $folder.FullName
        Status         = $Status
        FoundCount     = $foundCount
        MissingCount   = $missing.Count
        MissingReports = if ($missing.Count -gt 0) { $missing -join "; " } else { "" }
        SpecialFlags   = if ($SpecialFlags.Count -gt 0) { $SpecialFlags -join "; " } else { "" }
        ScanDate       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# ======================================================================
# EXPORT RESULTS
# ======================================================================
$SummaryRows | Export-Csv -Path $CSV_Output -NoTypeInformation -Encoding UTF8

Write-Host "`n===== SCAN COMPLETE =====" -ForegroundColor Cyan
Write-Host "📊 Total Folders Scanned : $TotalFolders" -ForegroundColor Yellow
Write-Host "🚫 Invalid Day Count     : $InvalidDayCount" -ForegroundColor Red
Write-Host "🗎 CSV Report Saved To   : $CSV_Output`n" -ForegroundColor Green

# Optional summary object for scripting chain
[pscustomobject]@{
    RootPath        = $RootPath
    TotalFolders    = $TotalFolders
    InvalidDayCount = $InvalidDayCount
    ReportPath      = $CSV_Output
}
