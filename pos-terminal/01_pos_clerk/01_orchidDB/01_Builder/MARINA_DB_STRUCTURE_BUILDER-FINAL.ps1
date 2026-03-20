# ============================================
# MARINA DB STRUCTURE BUILDER (FINAL)
# Author: Jason / AvA
# Purpose: Lean operational environment
# ============================================

Clear-Host

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   MARINA DATABASE BUILD (LEAN)      "
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------
# ROOT PATH
# --------------------------------------------

$RootPath        = "H:\01_CUSTOMER_SERVICE_SPECIALIST\01_marinaDB"

$SlipRoot        = Join-Path $RootPath "SLIPS"
$AgreementRoot   = Join-Path $RootPath "Agreements"
$CallLogRoot     = Join-Path $RootPath "CallLogs"
$UnassignedRoot  = Join-Path $RootPath "UNASSIGNED"
$ScriptRoot      = Join-Path $RootPath "Scripts"
$LogsRoot        = Join-Path $RootPath "Logs"

$IndexFile       = Join-Path $RootPath "SlipMasterIndex.csv"
$LedgerFile      = Join-Path $RootPath "IntegrityLedger.csv"
$OvernightFile   = Join-Path $RootPath "Overnight.csv"

# --------------------------------------------
# CREATE CORE DIRECTORIES
# --------------------------------------------

$dirs = @(
    $RootPath,
    $SlipRoot,
    $AgreementRoot,
    $CallLogRoot,
    $UnassignedRoot,
    $ScriptRoot,
    $LogsRoot
)

foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "[CREATED] $dir"
    }
    else {
        Write-Host "[OK]      $dir"
    }
}

# --------------------------------------------
# CREATE SLIP STRUCTURE (LEAN)
# --------------------------------------------

Write-Host ""
Write-Host "Building Slip Folders..." -ForegroundColor Yellow

1..80 | ForEach-Object {

    $SlipNumber = "{0:D3}" -f $_
    $SlipFolder = Join-Path $SlipRoot "SLIP_$SlipNumber"

    if (!(Test-Path $SlipFolder)) {
        New-Item -ItemType Directory -Path $SlipFolder | Out-Null
    }

    $SubFolders = @(
        "Agreement",
        "Operations",
        "UNASSIGNED"
    )

    foreach ($sub in $SubFolders) {

        $path = Join-Path $SlipFolder $sub

        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }
}

Write-Host "Slip folders ready."

# --------------------------------------------
# CREATE SlipMasterIndex.csv
# --------------------------------------------

if (!(Test-Path $IndexFile)) {

    Write-Host ""
    Write-Host "Creating SlipMasterIndex.csv..." -ForegroundColor Yellow

    $rows = 1..80 | ForEach-Object {

        [pscustomobject]@{
            SlipNumber     = "{0:D3}" -f $_
            TenantName     = ""
            Phone          = ""
            Email          = ""
            AgreementDate  = ""
            ExpirationDate = ""
            Status         = "OPEN"
            Notes          = ""
            LastUpdated    = ""
        }

    }

    $rows | Export-Csv $IndexFile -NoTypeInformation

    Write-Host "[CREATED] SlipMasterIndex.csv"
}
else {
    Write-Host "[OK]      SlipMasterIndex.csv"
}

# --------------------------------------------
# CREATE IntegrityLedger.csv
# --------------------------------------------

if (!(Test-Path $LedgerFile)) {

    Write-Host ""
    Write-Host "Creating IntegrityLedger.csv..." -ForegroundColor Yellow

    @(
        [pscustomobject]@{
            FileName   = ""
            FullPath   = ""
            SHA256     = ""
            DateLogged = ""
            SlipNumber = ""
            Notes      = ""
        }
    ) | Export-Csv $LedgerFile -NoTypeInformation

    Write-Host "[CREATED] IntegrityLedger.csv"
}
else {
    Write-Host "[OK]      IntegrityLedger.csv"
}

# --------------------------------------------
# CREATE Overnight.csv (Operational Log)
# --------------------------------------------

if (!(Test-Path $OvernightFile)) {

    Write-Host ""
    Write-Host "Creating Overnight.csv..." -ForegroundColor Yellow

    @(
        [pscustomobject]@{
            DateTime   = ""
            SlipNumber = ""
            StaffName  = ""
            Note       = ""
        }
    ) | Export-Csv $OvernightFile -NoTypeInformation

    Write-Host "[CREATED] Overnight.csv"
}
else {
    Write-Host "[OK]      Overnight.csv"
}

# --------------------------------------------
# COMPLETE
# --------------------------------------------

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  MARINA DATABASE READY"
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
