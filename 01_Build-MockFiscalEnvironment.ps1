<#
.SYNOPSIS
    Creates a complete mock fiscal year environment for The Orchid Shop (O.S.)

.DESCRIPTION
    This script builds a full fiscal directory structure for a given year range.
    - Creates a top-level fiscal year folder (e.g. FY2025-2026)
    - Creates 12 monthly folders following the organization’s fiscal calendar:
        October through September
    - Inside each month, creates one folder per day:
        OS MM-DD-YYYY
    - Inside each daily folder, creates 3 placeholder PDF files:
        * OS BACKUP MM-DD-YYYY.pdf
        * OS CASH FLOW REPORT MM-DD-YYYY.pdf
        * OS TAX REPORT MM-DD-YYYY.pdf

.PARAMETER RootPath
    The base path where the fiscal structure will be created.

.PARAMETER FiscalStartYear
    The starting year of the fiscal year (e.g. 2025).

.EXAMPLE
    .\Build-MockFiscalEnvironment.ps1 -RootPath "C:\OrchidShop" -FiscalStartYear 2025 -Verbose
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RootPath,

    [Parameter(Mandatory)]
    [int]$FiscalStartYear
)

# ======================================================================
# Configuration
# ======================================================================
$fiscalEndYear = $FiscalStartYear + 1
$fiscalFolder = Join-Path $RootPath "FY${FiscalStartYear}-${fiscalEndYear}"
$months = @(
    @{ Name = "01_October";   Year = $FiscalStartYear },
    @{ Name = "02_November";  Year = $FiscalStartYear },
    @{ Name = "03_December";  Year = $FiscalStartYear },
    @{ Name = "04_January";   Year = $FiscalStartYear + 1 },
    @{ Name = "05_February";  Year = $FiscalStartYear + 1 },
    @{ Name = "06_March";     Year = $FiscalStartYear + 1 },
    @{ Name = "07_April";     Year = $FiscalStartYear + 1 },
    @{ Name = "08_May";       Year = $FiscalStartYear + 1 },
    @{ Name = "09_June";      Year = $FiscalStartYear + 1 },
    @{ Name = "10_July";      Year = $FiscalStartYear + 1 },
    @{ Name = "11_August";    Year = $FiscalStartYear + 1 },
    @{ Name = "12_September"; Year = $FiscalStartYear + 1 }
)

$RequiredPDFs = @(
    "OS BACKUP",
    "OS CASH FLOW REPORT",
    "OS TAX REPORT"
)

Write-Host "`n=== Building Mock Fiscal Environment for FY${FiscalStartYear}-${fiscalEndYear} ===" -ForegroundColor Cyan

# ======================================================================
# Create Fiscal Folder
# ======================================================================
if (-not (Test-Path $fiscalFolder)) {
    New-Item -Path $fiscalFolder -ItemType Directory | Out-Null
    Write-Host "Created fiscal folder: $fiscalFolder" -ForegroundColor Green
} else {
    Write-Host "Fiscal folder already exists: $fiscalFolder" -ForegroundColor Yellow
}

# ======================================================================
# Create Monthly Folders and Daily Subfolders
# ======================================================================
foreach ($month in $months) {
    $monthName = $month.Name
    $monthYear = $month.Year
    $monthNumber = [int]$monthName.Substring(0,2)
    $monthPath = Join-Path $fiscalFolder $monthName

    if (-not (Test-Path $monthPath)) {
        New-Item -Path $monthPath -ItemType Directory | Out-Null
        Write-Host "📁 Created: $monthName ($monthYear)" -ForegroundColor Green
    } else {
        Write-Host "📁 Exists: $monthName ($monthYear)" -ForegroundColor DarkGray
    }

    # Get number of days in the month
    $daysInMonth = [DateTime]::DaysInMonth($monthYear, ($monthNumber - 0))

    for ($d = 1; $d -le $daysInMonth; $d++) {
        $date = Get-Date -Year $monthYear -Month $monthNumber -Day $d
        $folderName = "OS " + $date.ToString("MM-dd-yyyy")
        $dailyPath = Join-Path $monthPath $folderName

        if (-not (Test-Path $dailyPath)) {
            New-Item -Path $dailyPath -ItemType Directory | Out-Null
        }

        # Create placeholder PDFs
        foreach ($baseName in $RequiredPDFs) {
            $fileName = "$baseName $($date.ToString('MM-dd-yyyy')).pdf"
            $filePath = Join-Path $dailyPath $fileName

            if (-not (Test-Path $filePath)) {
                Set-Content -Path $filePath -Value "%PDF-1.4`n%" -Encoding ASCII
            }
        }
    }
}

Write-Host "`n✅ Mock Fiscal Environment successfully created at: $fiscalFolder" -ForegroundColor Cyan
