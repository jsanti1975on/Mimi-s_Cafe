<#
.SYNOPSIS
    Introduces randomized naming errors into a clean fiscal year dataset.

.DESCRIPTION
    Simulates human error and naming inconsistencies for audit and automation training.
    Randomly renames a percentage of existing daily PDF files with fuzzy,
    nonstandard naming conventions.

.PARAMETER RootPath
    Path to the fiscal year directory (e.g., I:\FY2025-2026)

.PARAMETER FuzzPercentage
    Percentage (1–100) of files to rename with invalid or fuzzy names.

.EXAMPLE
    .\OS_FiscalYear_FuzzyNames.ps1 -RootPath "I:\FY2025-2026" -FuzzPercentage 10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RootPath,

    [ValidateRange(1,100)]
    [int]$FuzzPercentage = 10
)

# ======================================================================
# Configuration
# ======================================================================
$ValidPatterns = @(
    "OS BACKUP",
    "OS CASH FLOW REPORT",
    "OS TAX REPORT"
)

# Common user mistakes and alternate patterns
$FuzzyVariants = @(
    "BACKUP"             , "BackUp"          , "bkup" ,
    "cashflow"           , "cash flow"       , "FlowReport" ,
    "tax"                , "Tax-Report"      , "Taxes" ,
    "report"             , "Rpt"             , "Rep" ,
    "OS_"                , "O.S."            , "OrchidShop" ,
    "randomfile"         , "temp"            , "draft"
)

Write-Host "`n===== Starting Fuzzy Name Injection =====" -ForegroundColor Cyan
Write-Host "Root: $RootPath" -ForegroundColor Yellow
Write-Host "Fuzziness Level: $FuzzPercentage%`n" -ForegroundColor Yellow

# Gather all PDF files under fiscal year
$AllPDFs = Get-ChildItem -Path $RootPath -Recurse -File -Filter *.pdf -ErrorAction SilentlyContinue

if (-not $AllPDFs) {
    Write-Host "No PDF files found. Ensure you’ve already generated the fiscal data." -ForegroundColor Red
    exit
}

# Calculate number of files to fuzz
$TotalFiles = $AllPDFs.Count
$FuzzCount  = [Math]::Ceiling(($FuzzPercentage / 100) * $TotalFiles)

Write-Host "Total PDF Files: $TotalFiles"
Write-Host "Files to Corrupt (approx): $FuzzCount`n"

# Randomly select which files to rename
$FilesToFuzz = Get-Random -InputObject $AllPDFs -Count $FuzzCount

foreach ($file in $FilesToFuzz) {
    try {
        $dir  = $file.DirectoryName
        $base = $file.BaseName

        # Choose a random fuzzy variant and position
        $variant = Get-Random -InputObject $FuzzyVariants
        $insertionPoint = Get-Random -Minimum 0 -Maximum ($base.Length)

        # Insert fuzzy text in the middle of the filename
        $newBase = ($base.Insert($insertionPoint, "_$variant_")).Trim('_')
        $newName = "$newBase.pdf"
        $newPath = Join-Path $dir $newName

        # Rename the file
        Rename-Item -Path $file.FullName -NewName $newName -Force

        Write-Host "🔸 Fuzzed: $($file.Name) → $newName" -ForegroundColor DarkYellow
    }
    catch {
        Write-Host "⚠️  Failed to rename $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n===== Fuzzy Naming Simulation Complete =====" -ForegroundColor Cyan
Write-Host "Corrupted File Count: $FuzzCount"
Write-Host "You can now run 'OS_FiscalYear_DailyReport_UnifiedScan.ps1' to detect invalid files." -ForegroundColor Green
