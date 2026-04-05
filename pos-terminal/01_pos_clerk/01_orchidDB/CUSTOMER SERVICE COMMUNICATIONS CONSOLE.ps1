# ============================================
# Customer Service Communications Console !!!! Run with PowerShell !!!!
# Author: Jason
# Version: 1.1 | This version supports graphical user interfaces for each button. 
# Customer Service Communications Console daily use for C.S.S. or Admin
# Purpose:
# Unified marina operations console for:
# - Slip lookup
# - Tenant lookup
# - Open slip search
# - Agreement entry
# - Call logger
# - Integrity ledger checks
# - Recent PDF / POS lookup
# - Folder shortcuts
# ============================================
# Write the autocreate file code to create the file Overnight.csv like the other portions of project do.
# Also get labtop version of overnight up to date as well. 
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# ============================================
# CONFIGURATION
# ============================================
$RootPath             = "F:\PropShop Accounting\CUSTOMER_SERVICE_SPECIALIST\01_CUST_SV_CONSOLE\"
$SlipRoot             = Join-Path $RootPath "SLIPS"
$AgreementRoot        = Join-Path $RootPath "Agreements"
$FinanceRoot          = ""
$SearchRoot           = "F:\PropShop Accounting\CUSTOMER_SERVICE_SPECIALIST\01_CUST_SV_CONSOLE\Agreements"
$WeeklySlipFile       = Join-Path $RootPath "Weekly_Slip_Normalized.csv" #Source of Truth
$IndexFile            = Join-Path $RootPath "SlipMasterIndex.csv"
$IntegrityLedgerFile  = Join-Path $RootPath "IntegrityLedger.csv"
$CallLogRoot          = Join-Path $RootPath "CallLogs"
$OvernightFile        = Join-Path $RootPath "Overnight.csv" 

# ============================================
# STARTUP PREP
# ============================================
if (-not (Test-Path $RootPath)) { New-Item -Path $RootPath -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $SlipRoot)) { New-Item -Path $SlipRoot -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $AgreementRoot)) { New-Item -Path $AgreementRoot -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $CallLogRoot)) { New-Item -Path $CallLogRoot -ItemType Directory -Force | Out-Null }

# Create SlipMasterIndex.csv if missing
if (-not (Test-Path $IndexFile)) {
    @(
        [pscustomobject]@{
            SlipNumber     = ""
            TenantName     = ""
            Phone          = ""
            Email          = ""
            AgreementDate  = ""
            ExpirationDate = ""
            Status         = ""
            Notes          = ""
            LastUpdated    = ""
        }
    ) | Export-Csv -Path $IndexFile -NoTypeInformation
}

# Create IntegrityLedger.csv if missing
if (-not (Test-Path $IntegrityLedgerFile)) {
    @(
        [pscustomobject]@{
            FileName     = ""
            FullPath     = ""
            SHA256       = ""
            DateLogged   = ""
            SlipNumber   = ""
            Notes        = ""
        }
    ) | Export-Csv -Path $IntegrityLedgerFile -NoTypeInformation
}

# ============================================
# HELPER FUNCTIONS
# ============================================> March 19 2026 - Below function for the addition of GUI's
function Add-OvernightEntry {
# Reminder to add file field or create the file if not exist: 03-27-2026 Added a builder script to handle file creation if not exist.
    param(
        [string]$SlipNumber,
        [string]$StaffName,
        [string]$Note,
        [string]$FilePath
    )

    if ([string]::IsNullOrWhiteSpace($Note)) {
        throw "Note cannot be empty."
    }

    # Normalize slip (optional)
    if (-not [string]::IsNullOrWhiteSpace($SlipNumber)) {
        $digits = ($SlipNumber -replace '[^\d]', '')
        if ($digits) {
            $SlipNumber = "{0:D3}" -f [int]$digits
        } else {
            $SlipNumber = ""
        }
    }

    $entry = [pscustomobject]@{
        DateTime   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        SlipNumber =  $SlipNumber
        StaffName  =  $StaffName
        Note       =  $Note
    }

    # Append safely - Note this .csv file is for all staff to use.
    if (-not (Test-Path $OvernightFile)) {
        $entry | Export-Csv -Path $OvernightFile -NoTypeInformation
    }
    else {
        $entry | Export-Csv -Path $OvernightFile -NoTypeInformation -Append
    }

        return $entry
}

function View-OvernightLog {

    if (-not (Test-Path $OvernightFile)) {
        Write-Status "No overnight log found."
        return
    }

    $data = Import-Csv $OvernightFile | Sort-Object DateTime -Descending

    Show-DataGridView -Data $data -Title "Overnight / Follow-Up Log"
}
# ============================================> March 19 2026 - Above function for the addition of GUI's
function Write-Status {
    param([string]$Message)
    $txtStatus.AppendText("[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message`r`n")
    $txtStatus.SelectionStart = $txtStatus.Text.Length
    $txtStatus.ScrollToCaret()
}

function Get-SlipFolderPath {
    param([string]$SlipNumber)
    $num = ($SlipNumber -replace '[^\d]', '')
    if ([string]::IsNullOrWhiteSpace($num)) { return $null }
    $d3 = "{0:D3}" -f [int]$num
    return Join-Path $SlipRoot "SLIP_$d3"
}

function Ensure-SlipFolder {
    param([string]$SlipNumber)
    $folder = Get-SlipFolderPath -SlipNumber $SlipNumber
    if (-not $folder) { return $null }

    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    $other = Join-Path $folder "Other"
    if (-not (Test-Path $other)) {
        New-Item -Path $other -ItemType Directory -Force | Out-Null
    }

    return $folder
}
# ===============================================================================================================================================================
function Import-SlipIndex {
    if (Test-Path $IndexFile) {
        return Import-Csv $IndexFile
    }
    return @()
}

function Save-SlipIndex {
    param([array]$Data)
    $Data | Export-Csv -Path $IndexFile -NoTypeInformation
}

function Import-IntegrityLedger {
    if (Test-Path $IntegrityLedgerFile) {
        return Import-Csv $IntegrityLedgerFile
    }
    return @()
}

function Add-CallLogEntry {
    param(
        [string]$SlipNumber,
        [string]$TenantName,
        [string]$Phone,
        [string]$Summary
    )

    $dateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeTenant = if ([string]::IsNullOrWhiteSpace($TenantName)) { "UNKNOWN" } else { ($TenantName -replace '[\\/:*?"<>|]', '_') }

    if (-not [string]::IsNullOrWhiteSpace($SlipNumber)) {
        $folder = Ensure-SlipFolder -SlipNumber $SlipNumber
        $targetFolder = Join-Path $folder "Other"
    } else {
        $targetFolder = $CallLogRoot
    }

    if (-not (Test-Path $targetFolder)) {
        New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
    }

    $fileName = "CALL_{0}_{1}.txt" -f $dateStamp, $safeTenant
    $filePath = Join-Path $targetFolder $fileName

    @"
MARINA CALL LOG
========================================
Date/Time   : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Slip Number : $SlipNumber
Tenant Name : $TenantName
Phone       : $Phone

Summary:
$Summary
"@ | Set-Content -Path $filePath -Encoding UTF8

    return $filePath
}

function Add-AgreementEntry {

    param(
        [string]$SlipNumber,
        [string]$TenantName,
        [string]$Phone,
        [string]$Email,
        [string]$AgreementDate,
        [string]$ExpirationDate,
        [string]$Status,
        [string]$Notes
    )

    # Load current index
    $data = Import-SlipIndex

    # Normalize slip number for comparison
    $SlipNumber = "{0:D3}" -f [int]($SlipNumber -replace '[^\d]', '')

    # Check if slip already exists
    $existing = $data | Where-Object { [int]$_.SlipNumber -eq [int]$SlipNumber }

if ($existing) {

    foreach ($row in $data) {

        if ([int]$row.SlipNumber -eq [int]$SlipNumber) {

            $row.TenantName     = $TenantName
            $row.Phone          = $Phone
            $row.Email          = $Email
            $row.AgreementDate  = $AgreementDate
            $row.ExpirationDate = $ExpirationDate
            $row.Status         = $Status
            $row.Notes          = $Notes
            $row.LastUpdated    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

        }

    }

    $data = $data | Sort-Object {[int]$_.SlipNumber}
    Save-SlipIndex -Data $data
    return "updated"

}
else {

    $newRow = [pscustomobject]@{
        SlipNumber     = $SlipNumber
        TenantName     = $TenantName
        Phone          = $Phone
        Email          = $Email
        AgreementDate  = $AgreementDate
        ExpirationDate = $ExpirationDate
        Status         = $Status
        Notes          = $Notes
        LastUpdated    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $data = @($data) + $newRow
    $data = $data | Sort-Object {[int]$_.SlipNumber}

    Save-SlipIndex -Data $data
    return "created"

}

}

function Add-IntegrityRecord {
    param(
        [string]$FilePath,
        [string]$SlipNumber,
        [string]$Notes
    )

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    $ledger = Import-IntegrityLedger
    $hash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash

    $duplicate = $ledger | Where-Object { $_.SHA256 -eq $hash }

    if ($duplicate) {
        return [pscustomobject]@{
            Result = "Duplicate"
            Hash   = $hash
            Match  = $duplicate
        }
    }

    $entry = [pscustomobject]@{
        FileName   = [System.IO.Path]::GetFileName($FilePath)
        FullPath   = $FilePath
        SHA256     = $hash
        DateLogged = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        SlipNumber = $SlipNumber
        Notes      = $Notes
    }

    $ledger = @($ledger) + $entry
    $ledger | Export-Csv -Path $IntegrityLedgerFile -NoTypeInformation
# 03182026 Hash ok - review Export-Csv
    return [pscustomobject]@{
        Result = "Logged"
        Hash   = $hash
        Match  = $null
    }
}
# ========== Below: The Show-DataGridView function replaced Show-DataGridView ========== 03-19-2026
# ========== Use find replace: replace all `Show-DataGridView` with  `Show-DataGridView` ==========> Done
# ========== Show-DataGridView function use: used to show a more polished report/viewer related to queries
# ========== The function is also the part that replaces input boxes with gui forms, change/revision 03-19-2026
function Show-DataGridView {

    param(
        [Parameter(Mandatory)]
        [array]$Data,

        [string]$Title = "Data Viewer"
    )

    if ($null -eq $Data -or @($Data).Count -eq 0) {
        Write-Status "No records found."
        return
    }

    # ========================================
    # Form Setup
    # ========================================
    $gridForm = New-Object System.Windows.Forms.Form
    $gridForm.Text = $Title
    $gridForm.Size = New-Object System.Drawing.Size(900, 500)
    $gridForm.StartPosition = "CenterScreen"

    # ========================================
    # DATAGRIDVIEW
    # ========================================
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = "Fill"
    $grid.ReadOnly = $true
    $grid.AutoSizeColumnsMode = "Fill"
    $grid.SelectionMode = "FullRowSelect"
    $grid.MultiSelect = $false
    $grid.AllowUserToAddRows = $false

    # Convert data to DataTable
    $table = New-Object System.Data.DataTable

    $properties = $Data[0].PSObject.Properties.Name

    foreach ($prop in $properties) {
        [void]$table.Columns.Add($prop)
    }

    foreach ($item in $Data) {
        $row = $table.NewRow()
        forEach ($prop in $properties) {
            $row[$prop] = $item.$prop
        }
        $table.Rows.Add($row)
    }

    $grid.DataSource = $table

    # ========================================
    # DOUBLE-CLICK ACTION
    # ========================================
    $grid.Add_CellDoubleClick({
        if ($grid.SelectedRows.Count -eq 0) { return }

        $row = $grid.SelectedRows[0]

        # Try to open the full path if exist
        if ($row.Cells["FullPath"] -and $row.Cells["FullPath"].Value) {
            $path = $row.Cells["FullPath"].Value
            if (Test-Path $path) {
                Start-Process $path
                return
            }
        }

        # Try DirectoryName
        if ($row.Cells["DirectoryName"] -and $row.Cells["DirectoryName"].Value) {
            $path = $row.Cells["DirectoryName"].Value
            if (Test-Path $path) {
                Start-Process explorer.exe $path
                return
            }
        }

        # Next try the slipNumber
        if ($row.Cells["slipNumber"] -and $row.Cells["slipNumber"].Value) {
            $slip = $row.Cells["slipNumber"].Value
            $folder = Get-SlipFolderPath -SlipNumber $slip
            if ($folder -and (Test-Path $folder)) {
                Start-Process explorer.exe $folder
                return
            }
        }
    })

    # ========================================
    # CLOSE BUTTON
    # ========================================
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Height = 30
    $btnClose.Dock = "Bottom"

    $btnClose.Add_Click({
        $gridForm.Close()
    })

    $gridForm.Controls.Add($grid)
    $gridForm.Controls.Add($btnClose)

    # ========================================
    # SHOW FORM
    # ========================================
    $gridForm.ShowDialog()
}
# 03-27-2026: Any remaining InputBoxes need to be removed
# ========== Above: The Show-DataGridView function replaced Show-DataGridView ========== 03-19-2026
function Prompt-Value {
    param(
        [string]$Prompt,
        [string]$Title = "Marina Control Center",
        [string]$Default = ""
    )
    return [Microsoft.VisualBasic.Interaction]::InputBox($Prompt, $Title, $Default)
}

# ============================================
# FORM SETUP
# ============================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Author: C.S.S-Jason Santiago"
$form.Size = New-Object System.Drawing.Size(980, 700)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

$title = New-Object System.Windows.Forms.Label
$title.Text = "CUSTOMER SERVICE COMMUNICATIONS CONSOLE"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 15)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Slip Lookup | Tenant Search | Logging | Integrity | Daily Operations"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(24, 52)
$form.Controls.Add($subtitle)

# ============================================
# GROUP BOXES
# ============================================
$grpLookup = New-Object System.Windows.Forms.GroupBox
$grpLookup.Text = "Lookup Tools"
$grpLookup.Size = New-Object System.Drawing.Size(450, 220)
$grpLookup.Location = New-Object System.Drawing.Point(20, 90)
$form.Controls.Add($grpLookup)

$grpOps = New-Object System.Windows.Forms.GroupBox
$grpOps.Text = "Operations"
$grpOps.Size = New-Object System.Drawing.Size(470, 220)
$grpOps.Location = New-Object System.Drawing.Point(490, 90)
$form.Controls.Add($grpOps)

$grpFolders = New-Object System.Windows.Forms.GroupBox
$grpFolders.Text = "Folders / Quick Access"
$grpFolders.Size = New-Object System.Drawing.Size(450, 140)
$grpFolders.Location = New-Object System.Drawing.Point(20, 325)
$form.Controls.Add($grpFolders)

$grpAdmin = New-Object System.Windows.Forms.GroupBox
$grpAdmin.Text = "Admin / Integrity"
$grpAdmin.Size = New-Object System.Drawing.Size(470, 140)
$grpAdmin.Location = New-Object System.Drawing.Point(490, 325)
$form.Controls.Add($grpAdmin)

$grpStatus = New-Object System.Windows.Forms.GroupBox
$grpStatus.Text = "Status"
$grpStatus.Size = New-Object System.Drawing.Size(940, 150)
$grpStatus.Location = New-Object System.Drawing.Point(20, 480)
$form.Controls.Add($grpStatus)

# ============================================
# STATUS BOX
# ============================================
$txtStatus = New-Object System.Windows.Forms.TextBox
$txtStatus.Multiline = $true
$txtStatus.ScrollBars = "Vertical"
$txtStatus.ReadOnly = $true
$txtStatus.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtStatus.Size = New-Object System.Drawing.Size(915, 115)
$txtStatus.Location = New-Object System.Drawing.Point(10, 22)
$grpStatus.Controls.Add($txtStatus)

# ============================================
# LOOKUP BUTTONS | 03-20-2026 Next button needed based on production flow is a lookup | Done
# ============================================
$btnSlipLookup = New-Object System.Windows.Forms.Button
$btnSlipLookup.Text = "Slip Lookup"
$btnSlipLookup.Size = New-Object System.Drawing.Size(130, 40)
$btnSlipLookup.Location = New-Object System.Drawing.Point(20, 35)
$btnSlipLookup.BackColor = [System.Drawing.Color]::LightGreen
$btnSlipLookup.ForeColor = [System.Drawing.Color]::Black
$grpLookup.Controls.Add($btnSlipLookup)

$btnTenantLookup = New-Object System.Windows.Forms.Button
$btnTenantLookup.Text = "Tenant Lookup"
$btnTenantLookup.Size = New-Object System.Drawing.Size(130, 40)
$btnTenantLookup.Location = New-Object System.Drawing.Point(160, 35)
$btnTenantLookup.BackColor = [System.Drawing.Color]::LightGreen
$btnTenantLookup.ForeColor = [System.Drawing.Color]::Black
$grpLookup.Controls.Add($btnTenantLookup)

$btnOpenSlips = New-Object System.Windows.Forms.Button
$btnOpenSlips.Text = "Show Open Slips"
$btnOpenSlips.Size = New-Object System.Drawing.Size(130, 40)
$btnOpenSlips.Location = New-Object System.Drawing.Point(300, 35)
$btnOpenSlips.BackColor = [System.Drawing.Color]::LightGreen
$btnOpenSlips.ForeColor = [System.Drawing.Color]::Black
$grpLookup.Controls.Add($btnOpenSlips)

$btnRecentAgreements = New-Object System.Windows.Forms.Button
$btnRecentAgreements.Text = "Recent Agreements"
$btnRecentAgreements.Size = New-Object System.Drawing.Size(130, 40)
$btnRecentAgreements.Location = New-Object System.Drawing.Point(20, 95)
$grpLookup.Controls.Add($btnRecentAgreements)

$btnRecentPOS = New-Object System.Windows.Forms.Button
$btnRecentPOS.Text = "Locate Recent PDFs"
$btnRecentPOS.Size = New-Object System.Drawing.Size(130, 40)
$btnRecentPOS.Location = New-Object System.Drawing.Point(160, 95)
$grpLookup.Controls.Add($btnRecentPOS)

$btnOpenSlipFolder = New-Object System.Windows.Forms.Button
$btnOpenSlipFolder.Text = "Open Slip Folder"
$btnOpenSlipFolder.Size = New-Object System.Drawing.Size(130, 40)
$btnOpenSlipFolder.Location = New-Object System.Drawing.Point(300, 95)
$grpLookup.Controls.Add($btnOpenSlipFolder)

# ============================================
# OPERATIONS BUTTONS
# ============================================
$btnAgreementEntry = New-Object System.Windows.Forms.Button
$btnAgreementEntry.Text = "Agreement Entry"
$btnAgreementEntry.Size = New-Object System.Drawing.Size(140, 40)
$btnAgreementEntry.Location = New-Object System.Drawing.Point(20, 35)
$btnAgreementEntry.BackColor = [System.Drawing.Color]::LightGreen
$btnAgreementEntry.ForeColor = [System.Drawing.Color]::Black
$grpOps.Controls.Add($btnAgreementEntry)

$btnCallLogger = New-Object System.Windows.Forms.Button
$btnCallLogger.Text = "Call Logger"
$btnCallLogger.Size = New-Object System.Drawing.Size(140, 40)
$btnCallLogger.Location = New-Object System.Drawing.Point(170, 35)
$grpOps.Controls.Add($btnCallLogger)

$btnRefreshIndex = New-Object System.Windows.Forms.Button
$btnRefreshIndex.Text = "View Slip Index"
$btnRefreshIndex.Size = New-Object System.Drawing.Size(140, 40)
$btnRefreshIndex.Location = New-Object System.Drawing.Point(320, 35)
$grpOps.Controls.Add($btnRefreshIndex)
# {^_^}LOOKFLAG==> Button Tested  and Deployed 03-20-2026 Note: Mark open is Overnight Follow up - use ctl-H and find replace with new name at some point
$btnMarkOpen = New-Object System.Windows.Forms.Button
$btnMarkOpen.Text = "Quik Note"
$btnMarkOpen.Size = New-Object System.Drawing.Size(140, 40)
$btnMarkOpen.Location = New-Object System.Drawing.Point(20, 95)
$btnMarkOpen.BackColor = [System.Drawing.Color]::CadetBlue
$btnMarkOpen.ForeColor = [System.Drawing.Color]::White
$grpOps.Controls.Add($btnMarkOpen)
# 03-31-2026: The btnMarkOpen is going to be reworked since we now have the slipboard for staff to use.
$btnMarkOccupied = New-Object System.Windows.Forms.Button
$btnMarkOccupied.Text = "Update Occupied"
$btnMarkOccupied.Size = New-Object System.Drawing.Size(140, 40)
$btnMarkOccupied.Location = New-Object System.Drawing.Point(170, 95)
$grpOps.Controls.Add($btnMarkOccupied)

$btnQuit = New-Object System.Windows.Forms.Button
$btnQuit.Text = "Quit"
$btnQuit.Size = New-Object System.Drawing.Size(140, 40)
$btnQuit.Location = New-Object System.Drawing.Point(320, 95)
$btnQuit.BackColor = [System.Drawing.Color]::MistyRose
$grpOps.Controls.Add($btnQuit)

# ============================================
# FOLDERS BUTTONS | 04-03-2026 comment out ...
# ============================================
$btnOpenSlipsRoot = New-Object System.Windows.Forms.Button
$btnOpenSlipsRoot.Text = "Open SLIPS"
$btnOpenSlipsRoot.Size = New-Object System.Drawing.Size(130, 40)
$btnOpenSlipsRoot.Location = New-Object System.Drawing.Point(20, 35)
$grpFolders.Controls.Add($btnOpenSlipsRoot)

$btnOpenAgreementsRoot = New-Object System.Windows.Forms.Button
$btnOpenAgreementsRoot.Text = "Open Agreements"
$btnOpenAgreementsRoot.Size = New-Object System.Drawing.Size(130, 40)
$btnOpenAgreementsRoot.Location = New-Object System.Drawing.Point(160, 35)
$grpFolders.Controls.Add($btnOpenAgreementsRoot)

$btnOpenFinance = New-Object System.Windows.Forms.Button
$btnOpenFinance.Text = "Open Finance"
$btnOpenFinance.Size = New-Object System.Drawing.Size(130, 40)
$btnOpenFinance.Location = New-Object System.Drawing.Point(300, 35)
$grpFolders.Controls.Add($btnOpenFinance)

# ============================================
# ADMIN BUTTONS
# ============================================
$btnIntegrityCheck = New-Object System.Windows.Forms.Button
$btnIntegrityCheck.Text = "Log PDF Hash"
$btnIntegrityCheck.Size = New-Object System.Drawing.Size(140, 40)
$btnIntegrityCheck.Location = New-Object System.Drawing.Point(20, 35)
$btnIntegrityCheck.BackColor = [System.Drawing.Color]::LightGreen
$btnIntegrityCheck.ForeColor = [System.Drawing.Color]::Black
$grpAdmin.Controls.Add($btnIntegrityCheck)

$btnViewLedger = New-Object System.Windows.Forms.Button
$btnViewLedger.Text = "View Ledger"
$btnViewLedger.Size = New-Object System.Drawing.Size(140, 40)
$btnViewLedger.Location = New-Object System.Drawing.Point(170, 35)
$grpAdmin.Controls.Add($btnViewLedger)

$btnOpenRoot = New-Object System.Windows.Forms.Button
$btnOpenRoot.Text = "Open MarinaDB Root"
$btnOpenRoot.Size = New-Object System.Drawing.Size(140, 40)
$btnOpenRoot.Location = New-Object System.Drawing.Point(320, 35)
$grpAdmin.Controls.Add($btnOpenRoot)

# ============================================
# EVENT HANDLERS | AddED Slip Lookup 03-20-2026, Adding btnTenantLookup 03-31-2026 | Made use of btnMarkOpen using overnight/follow up
# 04-02-2026: SlipBoard is complete with ability to add a note to only open slips, We can use this button for Admin to add notes to perm tenants. Not written yet - !!!!
# 04-04-2026: Writting the logic for the legal binding documents btnIntegrityCheck.
# ============================================

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------04-04-2026 below ----------->
# Integrity Ledger 
$btnIntegrityCheck.Add_Click({

    $form.Hide()

    # ========================================
    # LOG THE PDF HASHED VALUE "CHECKSUM"
    # ========================================
    $hashForm = New-Object System.Windows.Forms.Form
    $hashForm.Text = "Log PDF Hash"
    $hashForm.Size = New-Object System.Drawing.Size(500, 300)
    $hashForm.StartPosition = "CenterScreen"

    function New-Label($text, $y) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point(20, $y)
        $lbl.Size = New-Object System.Drawing.Size(150, 20)
        return $lbl
    }

    function New-Textbox($y, $width = 300) {
        $txt = New-Object System.Windows.Forms.TextBox
        $txt.Location = New-Object System.Drawing.Point(160, $y)
        $txt.Size = New-Object System.Drawing.Size($width, 20)
        return $txt
    }

    # ================================================================================
    # FILE SELECTION | Reminder: Used a dialog picker for this one
    # ================================================================================
    $hashForm.Controls.Add((New-Label "Selected File" 20))

    $txtFile = New-Textbox 20 220
    $txtFile.ReadOnly = $true
    $hashForm.Controls.Add($txtFile)

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "Browse"
    $btnBrowse.Size = New-Object System.Drawing.Size(80, 23)
    $btnBrowse.Location = New-Object System.Drawing.Point(390, 18)
    $hashForm.Controls.Add($btnBrowse)

    # ================================================================================
    # SLIP NUMBER
    # ================================================================================
    $hashForm.Controls.Add((New-Label "Slip Number (optional)" 60))
    $txtSlip = New-Textbox 60
    $hashForm.Controls.Add($txtSlip)

    # ================================================================================
    # NOTES
    # ================================================================================
    $hashForm.Controls.Add((New-Label "Notes" 100))
    $txtNotes = New-Textbox 100
    $hashForm.Controls.Add($txtNotes)

    # ================================================================================
    # BUTTONS
    # ================================================================================
    $btnLog = New-Object System.Windows.Forms.Button
    # Changing Hash to Checksum - You hash a file to get a checksum
    $btnLog.Text = "Log Checksum"
    $btnLog.Size = New-Object System.Drawing.Size(120, 30)
    $btnLog.Location = New-Object System.Drawing.Point(120, 160)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = New-Object System.Drawing.Size(120, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(260, 160)

    $hashForm.Controls.Add($btnLog)
    $hashForm.Controls.Add($btnCancel)

    # ================================================================================
    # EVENTS
    # ================================================================================

    # Browse for file
    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.InitialDirectory = $AgreementRoot
        $dialog.Filter = "PDF files (*.pdf)|*.pdf|All files (*.*)|*.*"

        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtFile.Text = $dialog.FileName
        }
    })

    # Log Hashed File / Checksum
    $btnLog.Add_Click({
        try {
            if ([string]::IsNullOrWhiteSpace($txtFile.Text)) {
                [System.Windows.Forms.MessageBox]::Show("Please select a file.") | Out-Null
                return
            }
            
            $slip = $txtSlip.Text
            # If the console scales out - use the function to normalize
            if (-not [string]::IsNullOrWhiteSpace($slip)) {
                $digits = ($slip -replace '[^\d]', '')
                if (-not [string]::IsNullOrWhiteSpace($digits)) {
                    $slip = "{0:D3}" -f [int]$digits
                }
            }

            $result = Add-IntegrityRecord `
                -FilePath $txtFile.Text `
                -SlipNumber $slip `
                -Notes $txtNotes.Text
# {^_^}LOOKFLAG=> Reminder about the clock sku issue from other duplicates
            if ($result.Result -eq "Duplicate") {
                [System.Windows.Forms.MessageBox]::Show(
                    "Duplicate file detected. `nHash: $($result.Hash)",
                    "Duplicate"
                 ) | Out-Null

                 Write-Status "Duplicate hash detected for [$($txtFile.Text)]."
            }
            else {
                [System.Windows.Forms.MessageBox]::Show(
                    "Hash logged successfully.`nHash: $($result.Hash)",
                    "Success"
                ) | Out-Null

                Write-Status "Integrity record logged for [$($txtFile.Text)]."
            }

            $hashForm.Close()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exeception.Message) | Out-Null
        }
    })

    $btnCancel.Add_Click({
        $hashForm.Close()
    })

    # Return to main form
    $hashForm.Add_FormClosed({
        $form.Show()
    })

    $hashForm.ShowDialog()
})         
 
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------04-04-2026 Above ----------->

$btnMarkOpen.Add_Click({

    $form.Hide()

    # ==============================
    # OVERNIGHT / FOLLOW-UP
    # ==============================
    $noteForm = New-Object System.Windows.Forms.Form
    $noteForm.Text = "Overnight / Follow-Up"
    $noteForm.Size = New-Object System.Drawing.Size(450, 420)
    $noteForm.StartPosition = "CenterScreen"

    function New-Label($text, $y) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point(20, $y)
        $lbl.Size = New-Object System.Drawing.Size(150, 20)
        return $lbl
    }

    function New-Textbox($y, $height = 20) {
        $txt = New-Object System.Windows.Forms.TextBox
        $txt.Location = New-Object System.Drawing.Point(170, $y)
        $txt.Size = New-Object System.Drawing.Size(240, $height)
        return $txt
    }

    $y = 20

    # Slip (Optional)
    $noteForm.Controls.Add((New-Label "Slip Number (optional)" $y))
    $txtSlip = New-Textbox $y
    $noteForm.Controls.Add($txtSlip)

    # Staff Member Name
    $y += 40
    $noteForm.Controls.Add((New-Label "Staff Name" $y))
    $txtStaff = New-Textbox $y
    $noteForm.Controls.Add($txtStaff)

    # Note
    $y += 40
    $noteForm.Controls.Add((New-Label "Note" $y))
    $txtNote = New-Textbox ($y + 25) 120
    $txtNote.Multiline = $true
    $noteForm.Controls.Add($txtNote)

    # ==============================
    # BUTTONS
    # ==============================
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "Save Entry"
    $btnSave.Size = New-Object System.Drawing.Size(120, 30)
    $btnSave.Location = New-Object System.Drawing.Point(90, 250)
        
# Stop Point 03-19-2026
    $btnView = New-Object System.Windows.Forms.Button
    $btnView.Text = "View Log"
    $btnView.Size = New-Object System.Drawing.Size(120, 30)
    $btnView.Location = New-Object System.Drawing.Point(230, 250)
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Close"
    $btnCancel.Size = New-Object System.Drawing.Size(120, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(160, 300)

    $noteForm.Controls.Add($btnSave)
    $noteForm.Controls.Add($btnView)
    $noteForm.Controls.Add($btnCancel)
        
    # ==============================
    # EVENTS
    #==============================
    $btnSave.Add_Click({
        try { 
        
            if ([string]::IsNullOrWhiteSpace($txtNote.Text)) {
                [System.Windows.Forms.MessageBox]::Show("Note is required.") | Out-Null
                return
            }
            
            $entry = Add-OvernightEntry `
                -SlipNumber $txtSlip.Text `
                -StaffName $txtStaff.Text `
                -Note $txtNote.Text
                

            Write-Status "Overnight Entry saved for slip [$($entry.SlipNumber)]."

            [System.Windows.Forms.MessageBox]::Show("Entry saved.") | Out-Null

            $noteForm.Close()

        } catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message) | Out-Null
        }
    })

    $btnView.Add_Click({
        View-OvernightLog
    })
    
    $btnCancel.Add_Click({
        $noteForm.Close()
    })
    
    $noteForm.Add_FormClosed({
        $form.Show()
    })
    
    $noteForm.ShowDialog()
})
# ABOVE LOGIC WRITTEN 03-19-2026
# Below is logic written 03-20-2026
# === 03-31-2026 === Both btnSlip Lookup and btnTenant Lookup will use the SlipMasterIndex file.==========================================================================================================
$btnTenantLookup.Add_Click({

    $form.Hide()

    # ============================================
    # TENANT LOOKUP FORM
    # ============================================
    $tenantForm = New-Object System.Windows.Forms.Form
    $tenantForm.Text = "Tenant Lookup"
    $tenantForm.Size = New-Object System.Drawing.Size(350, 200)
    $tenantForm.StartPosition = "CenterScreen"

    function New-Label($text, $y) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point(20, $y)
        $lbl.Size = New-Object System.Drawing.Size(140, 20)
        return $lbl
    }

    function New-Textbox($y) {
        $txt = New-Object System.Windows.Forms.TextBox
        $txt.Location = New-Object System.Drawing.Point(160, $y)
        $txt.Size = New-Object System.Drawing.Size(150, 20)
        return $txt
    }

    # Search Input
    $tenantForm.Controls.Add((New-Label "Tenant Name" 30))
    $txtName = New-Textbox 30
    $tenantForm.Controls.Add($txtName)
    
    # ============================================
    # BUTTONS
    # ============================================
    $btnSearch = New-Object System.Windows.Forms.Button
    $btnSearch.Text = "Search"
    $btnSearch.Size = New-Object System.Drawing.Size(100, 30)
    $btnSearch.Location = New-Object System.Drawing.Point(60, 90)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(180, 90)
    
    $tenantForm.Controls.Add($btnSearch)
    $tenantForm.Controls.Add($btnCancel)

    # ============================================
    # EVENTS
    # ============================================
    $btnSearch.Add_Click({
        try {
            $name = $txtName.Text

            if ([string]::IsNullOrWhiteSpace($name)) {
                [System.Windows.Forms.MessageBox]::Show("Enter a tenant name.") | Out-Null
                return
            }
            # This is the SlipMasterIndex.csv
            $data = Import-SlipIndex
            
            $result = $data | Where-Object {
                $_.TenantName -like "*$name*"
            }

            if (-not $result -or $result.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("No matching tenants found.") | Out-Null
                Write-Status "No tenant results for [$name]."
            }
            else {
                Show-DataGridView -Data $result -Title "Tenant Lookup Result"
                Write-Status "Tenant lookup completed for [$name]."
            }

            $tenantForm.Close()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message) | Out-Null
        }
    })

    $btnCancel.Add_Click({
        $tenantForm.Close()
    })

    # Return to main form
    $tenantForm.Add_FormClosed({
        $form.Show()
    })
        
    $tenantForm.ShowDialog()
})
# ==== 03-31-2026 LOGIC ABOVE =
$btnSlipLookup.Add_Click({

    $form.Hide()

    # ============================================
    # SLIP LOOKUP FORM|
    # ============================================
    $slipForm = New-Object System.Windows.Forms.Form
    $slipForm.Text = "Slip Lookup"
    $slipForm.Size = New-Object System.Drawing.Size(320, 180)
    $slipForm.StartPosition = "CenterScreen"
    
    function New-Label($text, $y) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point(20, $y)
        $lbl.Size = New-Object System.Drawing.Size(120, 20)
        return $lbl
    }
    
    function New-Textbox($y) {
        $txt = New-Object System.Windows.Forms.TextBox
        $txt.Location = New-Object System.Drawing.Point(140, $y)
        $txt.Size = New-Object System.Drawing.Size(140,20)
        return $txt
    }

    # Slip Number Input
    $slipForm.Controls.Add((New-Label "Slip Number" 30))
    $txtSlip = New-Textbox 30
    $slipForm.Controls.Add($txtSlip)

    # ============================================
    # BUTTONS
    # ============================================
    $btnSearch = New-Object System.Windows.Forms.Button
    $btnSearch.Text = "Search"
    $btnSearch.Size = New-Object System.Drawing.Size(90, 30)
    $btnSearch.Location = New-Object System.Drawing.Point(60, 80)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = New-Object System.Drawing.Size(90, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(160, 80)
    
    $slipForm.Controls.Add($btnSearch)
    $slipForm.Controls.Add($btnCancel)
        
    # ============================================
    # EVENTS | Later add more error handle e.g. IsNumeric?
    # ============================================ 
    $btnSearch.Add_Click({
        try {
            $slip = $txtSlip.Text

            if ([string]::IsNullOrWhiteSpace($slip)) {
                [System.Windows.Forms.MessageBox]::Show("Slip Number is required.") | Out-Null
                return
            }
            # Here is where the `function Normalize-SlipNumber` would save time and lines
            $digits = ($slip -replace '[^\d]', '')
            if ([string]::IsNullOrWhiteSpace($digits)) {
                [System.Windows.Forms.MessageBox]::Show("Invalid Slip Number.") | Out-Null
                return
            }

            $slip = [int]$digits # important: compare as int
            # Not Using the $WeeklySlipFile change to $IndexFile
            if (-not (Test-Path $IndexFile)) {
                [System.Windows.Forms.MessageBox]::Show("Weekly slip file not found.") | Out-Null
                return
            }
# 03-31-2026 Decided to use the SlipMasterIndex file as the file to lookup data from so --------------> $data = Import-SlipIndex ----> This means update the .csv file will all records.
#           $data = Import-Csv $WeeklySlipFile #==========================================================================================================================
            $data = Import-SlipIndex

            $result = $data | Where-Object {
                [int]$_.SlipNumber -eq $slip
            }

            if (-not $result -or $result.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("Slip not found.") | Out-Null
                Write-Status "Slip lookup failed for [$slip]."
            }
            else {
                Show-DataGridView -Data $result -Title "Slip Lookup Result"
                Write-Status "Slip lookup completed for [$slip]."
            }

            $slipForm.Close()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message) | Out-Null
        }
    })
    
    $btnCancel.Add_Click({
        $slipForm.Close()
    })

    # Next return to the main form
     $slipForm.Add_FormClosed({
        $form.Show()
    })

    $slipForm.ShowDialog()
})
# === 03-31-2026 === Both btnSlip Lookup and btnTenant Lookup will use the SlipMasterIndex file.==========================================================================================================
# Below is logic written 03-21-2026
$btnAgreementEntry.Add_Click({

    $form.Hide()

    # ========================================
    # AGREEMENT ENTRY FORM
    # ========================================
    $agreementForm = New-Object System.Windows.Forms.Form
    $agreementForm.Text = "Agreement Entry"
    $agreementForm.Size = New-Object System.Drawing.Size(400, 500)
    $agreementForm.StartPosition = "CenterScreen"

    function New-Label($text, $y) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point(20, $y)
        $lbl.Size = New-Object System.Drawing.Size(150, 20)
        return $lbl
    }

    function New-Textbox($y) {
        $txt = New-Object System.Windows.Forms.TextBox
        $txt.Location = New-Object System.Drawing.Point(180, $y)
        $txt.Size = New-Object System.Drawing.Size(180, 20)
        return $txt
    }
    # y is the y - axis
    $y = 20

    $agreementForm.Controls.Add((New-Label "Slip Number" $y))
    $txtSlip = New-Textbox $y
    $agreementForm.Controls.Add($txtSlip)
    
    $y += 40
    $agreementForm.Controls.Add((New-Label "Tenant Name" $y))
    $txtTenant = New-Textbox $y
    $agreementForm.Controls.Add($txtTenant)

    $y += 40
    $agreementForm.Controls.Add((New-Label "Phone" $y))
    $txtPhone = New-Textbox $y
    $agreementForm.Controls.Add($txtPhone)

    $y += 40
    $agreementForm.Controls.Add((New-Label "Email" $y))
    $txtEmail = New-Textbox $y
    $agreementForm.Controls.Add($txtEmail)

    $y += 40
    $agreementForm.Controls.Add((New-Label "Agreement Date" $y))
    $txtADate = New-Textbox $y
    $txtADate.Text = (Get-Date -Format "yyyy-MM-dd")
    $agreementForm.Controls.Add($txtADate)

    $y += 40
    $agreementForm.Controls.Add((New-Label "Expiration Date" $y))
    $txtEDate = New-Textbox $y
    $agreementForm.Controls.Add($txtEDate)
    # Keep moving down by 40 points
    $y += 40
    $agreementForm.Controls.Add((New-Label "Status" $y))
    $txtStatusBox = New-Textbox $y
    $txtStatusBox.Text = "OCCUPIED"
    $agreementForm.Controls.Add($txtStatusBox)

    $y += 40
    $agreementForm.Controls.Add((New-Label "Notes" $y))
    $txtNotes = New-Textbox $y
    $agreementForm.Controls.Add($txtNotes)

    # ========================================
    # BUTTONS
    # ========================================
    $btnSubmit = New-Object System.Windows.Forms.Button
    $btnSubmit.Text = "Save"
    $btnSubmit.Size = New-Object System.Drawing.Size(100, 30)
    $btnSubmit.Location = New-Object System.Drawing.Point(80, 380)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(200, 380)

    $agreementForm.Controls.Add($btnSubmit)
    $agreementForm.Controls.Add($btnCancel)

    # ========================================
    # EVENTS
    # ========================================
    $btnSubmit.Add_Click({
        try {
            $slip = $txtSlip.Text
            if ([string]::IsNullOrWhiteSpace($slip)) {
                [System.Windows.Forms.MessageBox]::Show("Slip is required.") | Out-Null
                return
            }

            $digits = ($slip -replace '[^\d]', '')
            $slip = "{0:D3}" -f [int]$digits

            Ensure-SlipFolder -SlipNumber $slip | Out-Null

            $result = Add-AgreementEntry `
                -SlipNumber $slip `
                -TenantName $txtTenant.Text `
                -Phone $txtPhone.Text `
                -Email $txtEmail.Text `
                -AgreementDate $txtADate.Text `
                -ExpirationDate $txtEDate.Text `
                -Status $txtStatusBox.Text `
                -Notes $txtNotes.Text 
                
                [System.Windows.Forms.MessageBox]::Show("Saved ($result) for slip $slip") | Out-Null

                Write-Status "Agreement entry $result for slip [$slip]."

                $agreementForm.Close()
        }
        catch {
            [System.Windows.MessageBox]::Show($_.Exeception.Message) | Out-Null
        }
    })

    $btnCancel.Add_Click({
        $agreementForm.Close()
    })

    # When the form closes show the main form again
    $agreementForm.Add_FormClosed({
        $form.Show()
    })

    $agreementForm.ShowDialog()
})
# Stop Point 03-21-2026: Reminder - SlipMasterIndex.csv has to have text arranged in the builder script manner.
# If no data exist or an empty string is 1ST LINE - Exception.Message will 'Null Data Binding Exception' 
# 03-24-2026: The click event needs to use the show hide method. 03-24-2026 Adding the show hide...04-03-26 changed result to handle SlipMasterIndex.csv
$btnOpenSlips.Add_Click({

    try {
        # Hide the main form
        $form.Hide()
        
        # Get data
        $data = Import-SlipIndex
# =================================================================== 04-03-2026: Change Below: Get all possible slips  ==========================================> 
    $allSlips = 1..80

    $occupiedSlips = $data | ForEach-Object {
        [int]$_.SlipNumber
    }
    
    # Find open slips (difference)
    $openSlips = $allSlips | Where-Object { $_ -notin $occupiedSlips }

    # Convert to grid friendly object
    $result = $openSlips | ForEach-Object {
        [pscustomobject]@{
            SlipNumber  =  "{0:D3}" -F $_
            Status      =  "Open"
        }            
    }
# =================================================================== 04-03-2026: Change Below: Get all possible slips  ==========================================>
        if (-not $result) {
            [System.Windows.Forms.MessageBox]::Show("No open slips found.")
        }
        else {
            Show-DataGridView -Data $result -Title "Open Slips"
        }
    
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
    }
    finally {
        # Show main form again after the custom grid closes
        $form.Show()
        $form.Activate()
    }

})

# 03-21-2026: Above is logic written 03-21-2026, 03-24-2026 The above logic needs to use show hide method 
#     It's use is for looking for open slips WHEN TENANT WALKS IN FOR AN OVERNIGHT- Added 03-24-2026
# 04-03-2026: Added a drop in that uses basic math to prepare a clean list of open slips by subtracting out COMMERCIAL slips from open slips list.
# 04-03-2026: The slip map tool handle "WHEN TENANT WALKS IN FOR AN OVERNIGHT" - General Notes if used are already programmed.
# VIEW LEDGER BELOW
$btnViewLedger.Add_Click({
    try {
        $ledger = Import-IntegrityLedger
        Show-Grid -Data $ledger -Title "IntegrityLedger.csv"
        Write-Status "Integrity ledger opened in grid view."
    } catch {
        Write-Status "ERROR viewing ledger: $($_.Exception.Message)"
    }
})

$btnOpenRoot.Add_Click({
    try {
        Start-Process explorer.exe $RootPath
        Write-Status "Opened MarinaDB root."
    } catch {
        Write-Status "ERROR opening MarinaDB root: $($_.Exception.Message)"
    }
})

$btnQuit.Add_Click({
    try {
        Write-Status "Customer Service Communications Console."
        $form.Close()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Unable to close form: $($_.Exception.Message)", "Quit Error") | Out-Null
    }
})

$form.Add_Shown({
    $form.Activate()
    Write-Status "Customer Service Communications Console started."
    Write-Status "RootPath: $RootPath"
    Write-Status "Slip index: $IndexFile"
    Write-Status "Integrity ledger: $IntegrityLedgerFile"
})

# ============================================
# SHOW FORM
# ============================================
[void]$form.ShowDialog()
