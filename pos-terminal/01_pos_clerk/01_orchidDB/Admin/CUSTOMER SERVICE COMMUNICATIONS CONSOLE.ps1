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
# - Task Tracker
# ============================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================
# CONFIGURATION
# ============================================
$RootPath             = "H:\01_CUSTOMER_SERVICE_SPECIALIST\01_marinaDB"
$SlipRoot             = Join-Path $RootPath "SLIPS"
$AgreementRoot        = Join-Path $RootPath "Agreements"
#$SearchRoot           = "H:\PropShop Accounting\CUSTOMER_SERVICE_SPECIALIST\01_marinaDB\Agreements"
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

# ============================================
# TASK TRACKER CONFIG (EMBEDDED)
# ============================================
$TrackerRoot       = Join-Path $RootPath "Tracker"
$TrackerDataPath   = Join-Path $TrackerRoot "Data"
$TrackerLogPath    = Join-Path $TrackerRoot "Logs"

$ActiveTaskFile    = Join-Path $TrackerDataPath "ActiveTasks.json"
$SessionLogFile    = Join-Path $TrackerLogPath  "TaskSessions.csv"

# Ensure structure
foreach ($p in @($TrackerRoot, $TrackerDataPath, $TrackerLogPath)) {
    if (-not (Test-Path $p)) {
        New-Item -Path $p -ItemType Directory -Force | Out-Null
    }
}

# Initialize active slots
if (-not (Test-Path $ActiveTaskFile)) {
    @(
        [PSCustomObject]@{ Slot = 1; TaskName = ""; StartTime = $null; IsActive = $false }
        [PSCustomObject]@{ Slot = 2; TaskName = ""; StartTime = $null; IsActive = $false }
        [PSCustomObject]@{ Slot = 3; TaskName = ""; StartTime = $null; IsActive = $false }
    ) | ConvertTo-Json | Set-Content $ActiveTaskFile
}

# Initialize log
if (-not (Test-Path $SessionLogFile)) {
    "Slot,TaskName,StartTime,StopTime,DurationMinutes,DurationHours,WorkDate" |
        Set-Content $SessionLogFile
}

function Get-ActiveTasks {
    (Get-Content $ActiveTaskFile -Raw | ConvertFrom-Json)
}

function Save-ActiveTasks($tasks) {
    $tasks | ConvertTo-Json | Set-Content $ActiveTaskFile
}

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
# HELPER FUNCTIONS | TASK TRACKER FUNCTIONS
# ============================================

function Show-DailyTaskSummary {

    $today = (Get-Date).ToString("yyyy-MM-dd")

    $rows = Import-Csv $SessionLogFile |
        Where-Object { $_.WorkDate -eq $today }

    if (-not $rows) {
        Write-Status "No task data for today."
        return
    }

    $summary = $rows |
        Group-Object TaskName |
        ForEach-Object {
            $total = ($_.Group | Measure-Object DurationHours -Sum).Sum
            [PSCustomObject]@{
                TaskName = $_.Name
                Hours    = [math]::Round($total,2)
            }
        }

    Show-DataGridView -Data $summary -Title "Daily Task Summary"
}

function Add-OvernightEntry {
# Reminder to add file field or create the file if not exist: 03-27-2026 Added a builder script to handle file creation if not exist.
    param(
        [string]$SlipNumber,
        [string]$StaffName,
        [string]$Note
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

    return [pscustomobject]@{
        Result = "Logged"
        Hash   = $hash
        Match  = $null
    }
}

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

        # Next try the SlipNumber 04-09-2026 slipNumber cganged to SlipNumber
        if ($row.Cells["SlipNumber"] -and $row.Cells["SlipNumber"].Value) {
            $slip = $row.Cells["SlipNumber"].Value
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
# LOOKUP BUTTONS 
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

$btnMarkOpen = New-Object System.Windows.Forms.Button
$btnMarkOpen.Text = "Quik Note"
$btnMarkOpen.Size = New-Object System.Drawing.Size(140, 40)
$btnMarkOpen.Location = New-Object System.Drawing.Point(20, 95)
$btnMarkOpen.BackColor = [System.Drawing.Color]::CadetBlue
$btnMarkOpen.ForeColor = [System.Drawing.Color]::White
$grpOps.Controls.Add($btnMarkOpen)

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
# TASK TRACKER BUTTONS
# ============================================
$btnStartTask = New-Object System.Windows.Forms.Button
$btnStartTask.Text = "Task Tracker"
$btnStartTask.Size = New-Object System.Drawing.Size(140, 40)
$btnStartTask.Location = New-Object System.Drawing.Point(20, 155)
$btnStartTask.BackColor = [System.Drawing.Color]::LightGreen
$grpOps.Controls.Add($btnStartTask)

$btnStopTask = New-Object System.Windows.Forms.Button
$btnStopTask.Text = "Stop Task"
$btnStopTask.Size = New-Object System.Drawing.Size(140, 40)
$btnStopTask.Location = New-Object System.Drawing.Point(170, 155)
$grpOps.Controls.Add($btnStopTask)

$btnTaskSummary = New-Object System.Windows.Forms.Button
$btnTaskSummary.Text = "Daily Summary"
$btnTaskSummary.Size = New-Object System.Drawing.Size(140, 40)
$btnTaskSummary.Location = New-Object System.Drawing.Point(320, 155)
$grpOps.Controls.Add($btnTaskSummary)

# ============================================
# FOLDERS BUTTONS
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
# EVENT HANDLERS 
# ============================================

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
    # FILE SELECTION 
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
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message) | Out-Null
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
    # EVENTS
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
            [System.Windows.MessageBox]::Show($_.Exception.Message) | Out-Null
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

$btnOpenSlips.Add_Click({

    try {
        # Hide the main form
        $form.Hide()
        
        # Get data
        $data = Import-SlipIndex

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

$btnViewLedger.Add_Click({
    try {
        $ledger = Import-IntegrityLedger
        Show-DataGridView -Data $ledger -Title "IntegrityLedger.csv"
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
# TASK TRACKER EVENTS
# ============================================
# BUTTON START TASK ==========================
$btnStartTask.Add_Click({

    $form.Hide()

    # ========================================
    # TASK TRACKER FORM
    # ========================================
    $taskForm = New-Object System.Windows.Forms.Form
    $taskForm.Text = "Start Task"
    $taskForm.Size = New-Object System.Drawing.Size(400, 220)
    $taskForm.StartPosition = "CenterScreen"

    function New-Label($text, $y) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point(20, $y)
        $lbl.Size = New-Object System.Drawing.Size(120, 20)
        return $lbl
    }

    function New-Textbox($y) {
        $txt = New-Object System.Windows.Forms.TextBox
        $txt.Location = New-Object System.Drawing.Point(150, $y)
        $txt.Size = New-Object System.Drawing.Size(200, 20)
        return $txt
    }

    # Task Name Input
    $taskForm.Controls.Add((New-Label "Task Name" 40))
    $txtTask = New-Textbox 40
    $taskForm.Controls.Add($txtTask)

    # Buttons
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Text = "Start Task"
    $btnStart.Size = New-Object System.Drawing.Size(120, 30)
    $btnStart.Location = New-Object System.Drawing.Point(60, 100)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = New-Object System.Drawing.Size(120, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(200, 100)

    $taskForm.Controls.Add($btnStart)
    $taskForm.Controls.Add($btnCancel)

    # ========================================
    # EVENTS
    # ========================================
    $btnStart.Add_Click({
        $taskName = $txtTask.Text

        if ([string]::IsNullOrWhiteSpace($taskName)) {
            [System.Windows.Forms.MessageBox]::Show("Task name required.") | Out-Null
            return
        }

        $tasks = Get-ActiveTasks

        if ($tasks | Where-Object { $_.IsActive -and $_.TaskName -eq $taskName }) {
            [System.Windows.Forms.MessageBox]::Show("Task already active.") | Out-Null
            return
        }

        $slot = $tasks | Where-Object { -not $_.IsActive } | Select-Object -First 1

        if (-not $slot) {
            [System.Windows.Forms.MessageBox]::Show("All task slots are in use.") | Out-Null
            return
        }

        $slot.TaskName  = $taskName
        $slot.StartTime = (Get-Date).ToString("o")
        $slot.IsActive  = $true

        Save-ActiveTasks $tasks

        Write-Status "TASK STARTED → Slot $($slot.Slot) | $taskName"

        $taskForm.Close()
    })

    $btnCancel.Add_Click({
        $taskForm.Close()
    })

    $taskForm.Add_FormClosed({
        $form.Show()
    })

    $taskForm.ShowDialog()
})
#===== button to stop task 
$btnStopTask.Add_Click({

    $form.Hide()

    # ========================================
    # STOP TASK FORM
    # ========================================
    $stopForm = New-Object System.Windows.Forms.Form
    $stopForm.Text = "Stop Task"
    $stopForm.Size = New-Object System.Drawing.Size(420, 260)
    $stopForm.StartPosition = "CenterScreen"

    function New-Label($text, $y) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point(20, $y)
        $lbl.Size = New-Object System.Drawing.Size(150, 20)
        return $lbl
    }

    # ========================================
    # DROPDOWN (SLOT SELECTOR)
    # ========================================
    $stopForm.Controls.Add((New-Label "Select Slot" 30))

    $cmbSlots = New-Object System.Windows.Forms.ComboBox
    $cmbSlots.Location = New-Object System.Drawing.Point(180, 30)
    $cmbSlots.Size = New-Object System.Drawing.Size(180, 20)
    $cmbSlots.DropDownStyle = "DropDownList"
    $stopForm.Controls.Add($cmbSlots)

    # ========================================
    # ACTIVE TASK PREVIEW
    # ========================================
    $stopForm.Controls.Add((New-Label "Active Task" 70))

    $lblTaskName = New-Object System.Windows.Forms.Label
    $lblTaskName.Location = New-Object System.Drawing.Point(180, 70)
    $lblTaskName.Size = New-Object System.Drawing.Size(200, 20)
    $lblTaskName.Text = "-"
    $stopForm.Controls.Add($lblTaskName)

    $stopForm.Controls.Add((New-Label "Start Time" 100))

    $lblStartTime = New-Object System.Windows.Forms.Label
    $lblStartTime.Location = New-Object System.Drawing.Point(180, 100)
    $lblStartTime.Size = New-Object System.Drawing.Size(200, 20)
    $lblStartTime.Text = "-"
    $stopForm.Controls.Add($lblStartTime)

    # ========================================
    # BUTTONS
    # ========================================
    $btnStop = New-Object System.Windows.Forms.Button
    $btnStop.Text = "Stop Task"
    $btnStop.Size = New-Object System.Drawing.Size(120, 30)
    $btnStop.Location = New-Object System.Drawing.Point(70, 150)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = New-Object System.Drawing.Size(120, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(220, 150)

    $stopForm.Controls.Add($btnStop)
    $stopForm.Controls.Add($btnCancel)

    # ========================================
    # LOAD ACTIVE TASKS INTO DROPDOWN
    # ========================================
    $tasks = Get-ActiveTasks

    $activeTasks = $tasks | Where-Object { $_.IsActive }

    if (-not $activeTasks -or $activeTasks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No active tasks to stop.") | Out-Null
        $form.Show()
        return
    }

    foreach ($t in $activeTasks) {
        $cmbSlots.Items.Add("Slot $($t.Slot)")
    }

    # ========================================
    # DROPDOWN CHANGE EVENT (PREVIEW UPDATE)
    # ========================================
    $cmbSlots.Add_SelectedIndexChanged({

        $selectedText = $cmbSlots.SelectedItem

        if (-not $selectedText) { return }

        $slotNumber = [int]($selectedText -replace '[^\d]', '')

        $task = $tasks | Where-Object { $_.Slot -eq $slotNumber }

        if ($task) {
            $lblTaskName.Text = $task.TaskName
            $lblStartTime.Text = (Get-Date $task.StartTime).ToString("yyyy-MM-dd HH:mm:ss")
        }
    })

    # Auto-select first item
    if ($cmbSlots.Items.Count -gt 0) {
        $cmbSlots.SelectedIndex = 0
    }

    # ========================================
    # STOP BUTTON LOGIC
    # ========================================
    $btnStop.Add_Click({

        $selectedText = $cmbSlots.SelectedItem

        if (-not $selectedText) {
            [System.Windows.Forms.MessageBox]::Show("Select a slot.") | Out-Null
            return
        }

        $slotNumber = [int]($selectedText -replace '[^\d]', '')

        $tasks = Get-ActiveTasks
        $task  = $tasks | Where-Object { $_.Slot -eq $slotNumber }

        if (-not $task.IsActive) {
            [System.Windows.Forms.MessageBox]::Show("Task is not active.") | Out-Null
            return
        }

        $start = Get-Date $task.StartTime
        $stop  = Get-Date

        $mins  = [math]::Round(($stop - $start).TotalMinutes, 2)
        $hours = [math]::Round(($stop - $start).TotalHours, 2)

        [PSCustomObject]@{
            Slot            = $task.Slot
            TaskName        = $task.TaskName
            StartTime       = $start
            StopTime        = $stop
            DurationMinutes = $mins
            DurationHours   = $hours
            WorkDate        = $start.ToString("yyyy-MM-dd")
        } | Export-Csv $SessionLogFile -Append -NoTypeInformation

        Write-Status "TASK STOPPED → Slot $slotNumber | $($task.TaskName) | $hours hrs"

        # Reset slot
        $task.TaskName  = ""
        $task.StartTime = $null
        $task.IsActive  = $false

        Save-ActiveTasks $tasks

        [System.Windows.Forms.MessageBox]::Show("Task stopped successfully.") | Out-Null

        $stopForm.Close()
    })

    $btnCancel.Add_Click({
        $stopForm.Close()
    })

    $stopForm.Add_FormClosed({
        $form.Show()
    })

    $stopForm.ShowDialog()
})

$btnTaskSummary.Add_Click({

    try {
        # Hide main form
        $form.Hide()

        # Run summary (this opens DataGridView form)
        Show-DailyTaskSummary
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error: $($_.Exception.Message)"
        ) | Out-Null
    }
    finally {
        # ALWAYS restore main form
        $form.Show()
        $form.Activate()
    }

})
# ============================================
# SHOW FORM
# ============================================
[void]$form.ShowDialog()
