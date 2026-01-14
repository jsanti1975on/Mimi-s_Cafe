<#
.SYNOPSIS
    Introduces random naming errors and special business documents
    into a clean fiscal year dataset for audit simulation.

.DESCRIPTION
    - Randomly renames a subset of existing daily report PDFs using fuzzy naming.
    - Randomly creates new special document PDFs (FPO, Pavilion, Refund).
    - Intended for use with OS_FiscalYear_DailyReport_UnifiedScan.ps1.

.PARAMETER RootPath
    The fiscal year root directory (e.g. I:\FY2025-2026).

.PARAMETER FuzzPercentage
    Percentage (1–100) of existing PDFs to rename with fuzzy/invalid names.

.PARAMETER SpecialInsertCount
    Approximate number of random special documents to create across the dataset.

.EXAMPLE
    .\OS_FiscalYear_FuzzyAndSpecial.ps1 -RootPath "I:\FY2025-2026" -FuzzPercentage 10 -SpecialInsertCount 50
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RootPath,

    [ValidateRange(1,100)]
    [int]$FuzzPercentage = 10,

    [ValidateRange(1,1000)]
    [int]$SpecialInsertCount = 50
)

# ======================================================================
# CONFIGURATION
# ======================================================================
$ValidPatterns = @("OS BACKUP", "OS CASH FLOW REPORT", "OS TAX REPORT")

# Common naming variants for fuzzed names
$FuzzyVariants = @(
    "BackUp", "bkup", "back-up", "cashflow", "FlowRpt",
    "taxes", "tax-report", "report_copy", "rptv2", "OrchidShop"
)

# Special document templates
$SpecialSamples = @(
    "FPO_Jack_Doe.pdf",
    "Pavilion_Rental_John_Doe.pdf",
    "Doe_John_Refund.pdf"
)

Write-Host "`n===== Starting Fuzzy + Special Document Injection =====" -ForegroundColor Cyan
Write-Host "Root Path: $RootPath" -ForegroundColor Yellow
Write-Host "Fuzz Percentage: $FuzzPercentage%  |  Special Docs: $SpecialInsertCount`n" -ForegroundColor Yellow

# ======================================================================
# GATHER ALL PDF FILES
# ======================================================================
$AllPDFs = Get-ChildItem -Path $RootPath -Recurse -File -Filter *.pdf -ErrorAction SilentlyContinue
if (-not $AllPDFs) {
    Write-Host "No PDF files found. Run the fiscal year generation script first." -ForegroundColor Red
    exit
}

# ======================================================================
# FUZZY RENAMING PHASE
# ======================================================================
$TotalFiles = $AllPDFs.Count
$FuzzCount  = [Math]::Ceiling(($FuzzPercentage / 100) * $TotalFiles)
$FilesToFuzz = Get-Random -InputObject $AllPDFs -Count $FuzzCount

foreach ($file in $FilesToFuzz) {
    try {
        $dir  = $file.DirectoryName
        $base = $file.BaseName
        $variant = Get-Random -InputObject $FuzzyVariants
        $insertionPoint = Get-Random -Minimum 0 -Maximum ($base.Length)
        $newBase = ($base.Insert($insertionPoint, "_$variant_")).Trim('_')
        $newName = "$newBase.pdf"
        Rename-Item -Path $file.FullName -NewName $newName -Force
        Write-Host "🔸 Fuzzed: $($file.Name) → $newName" -ForegroundColor DarkYellow
    }
    catch {
        Write-Host "⚠️  Failed to rename $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ======================================================================
# SPECIAL DOCUMENT INJECTION PHASE
# ======================================================================
$DailyFolders = Get-ChildItem -Path $RootPath -Directory -Recurse |
                Where-Object { $_.Name -match '^OS\s\d{2}-\d{2}-\d{4}$' }

if (-not $DailyFolders) {
    Write-Host "No valid daily folders found. Check RootPath structure." -ForegroundColor Red
    exit
}

for ($i = 1; $i -le $SpecialInsertCount; $i++) {
    $folder = Get-Random -InputObject $DailyFolders
    $sample = Get-Random -InputObject $SpecialSamples

    $targetPath = Join-Path $folder.FullName $sample

    # Avoid overwriting any existing file
    if (-not (Test-Path $targetPath)) {
        try {
            Set-Content -Path $targetPath -Value "%PDF-1.4`n%" -Encoding ASCII
            Write-Host "📄 Added Special Doc: $($folder.Name)\$sample" -ForegroundColor Cyan
        }
        catch {
            Write-Host "⚠️  Could not create $sample in $($folder.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ======================================================================
# SUMMARY
# ======================================================================
Write-Host "`n===== Injection Complete =====" -ForegroundColor Cyan
Write-Host "Renamed (Fuzzed) Files : $FuzzCount" -ForegroundColor Yellow
Write-Host "Inserted Special Docs  : $SpecialInsertCount" -ForegroundColor Yellow
Write-Host "You can now run OS_FiscalYear_DailyReport_UnifiedScan.ps1 to verify results." -ForegroundColor Green
