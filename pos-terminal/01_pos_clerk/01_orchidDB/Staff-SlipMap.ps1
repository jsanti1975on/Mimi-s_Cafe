<#
=======================================================================================================================================================================
Purpose:                                            
	Replace marina map written in VBA. UI-Driven | If you read this you doubleclicked not left clicked - and run with PowerShell.
               
Authors:
    - Human in Loop: Jason Santiago, C.S.S.
    - AI Agent: PowershellKeith

Change Notes:
	Add no more changes. Only if more slips added. The Customer Service Communications Console holds the logic for any other notes.
=======================================================================================================================================================================
#>
# =====================================================================================================================================================================
# Loads the .NET Assemblies | GUI
#     REQUIRED for any WinForms app
# =====================================================================================================================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =====================================================================================================================================================================
# CONFIG 
# =====================================================================================================================================================================

$RootPath      = "F:\PropShop Accounting\CUSTOMER_SERVICE_SPECIALIST\01_CUST_SV_CONSOLE"
$SlipBoardFile = Join-Path $RootPath "SlipBoard.csv"
$IndexFile     = Join-Path $RootPath "SlipMasterIndex.csv" # Reminder: No need for both $IndexFile & $SlipMasterIndexFile
$SlipMasterIndexFile = "F:\PropShop Accounting\CUSTOMER_SERVICE_SPECIALIST\01_CUST_SV_CONSOLE\SlipMasterIndex.csv"

if (-not(Test-Path $RootPath)) {
    New-Item -Path $RootPath -ItemType Directory -Force | Out-Null
}
# =====================================================================================================================================================================
# DATA FUNCTIONS 
# =====================================================================================================================================================================

function Initialize-SlipBoardData {
    if (-not (Test-Path $SlipBoardFile)) {
        $rows = foreach ($i in 1..80) {
            [pscustomobject]@{
                SlipNumber = $i 
                Status     = "Open_Slip"
                Note       = ""
                User       = ""
                Timestamp  = ""
            }
        }

        # Initialize constant COMMERCIAL slip only
        foreach ($row in $rows)  {
            switch ($row.SlipNumber) {
                { $_ -in 43..50 } { $row.Status = "COMMERCIAL"; continue }
                { $_ -in 57..64 } { $row.Status = "COMMERCIAL"; continue }
                67               { $row.Status = "COMMERCIAL"; continue }
                68               { $row.Status = "COMMERCIAL"; continue } 
                { $_ -in 71..73 } { $row.Status = "COMMERCIAL"; continue }
            }
        }
        $rows | Export-Csv -Path $SlipBoardFile -NoTypeInformation -Encoding UTF8
    }
}

function Import-SlipBoardData {
    if (-not (Test-Path $SlipBoardFile)) {
        Initialize-SlipBoardData
    }

    $data = Import-Csv -Path $SlipBoardFile

    foreach ($row in $data) {
        $row.SlipNumber = [int]$row.SlipNumber
    }

    return $data | Sort-Object SlipNumber
}

function Import-SlipIndex {
    if (Test-Path $IndexFile) {
        return Import-Csv $IndexFile
    }
    return @()
}

# April 1st 2026: Drop In Below - Reason - Add Perm. Tenants and callouts. ==========================================>

function Sync-SlipBoardWithIndex {
    
    if (-not (Test-Path $SlipBoardFile)) { return }

    $board = Import-Csv $SlipBoardFile
    $index = Import-SlipIndex

    foreach ($row in $board) {
        
        $slip = [int]$row.SlipNumber

        $match = $index | Where-Object {
            [int]$_.SlipNumber -eq $slip -and
            -not [string]::IsNullOrWhiteSpace($_.TenantName)
        }

        if ($match) {
            $row.Status = "OCCUPIED"
        }
    }

    $board | Export-Csv -Path $SlipBoardFile -NoTypeInformation
}

# April 1st 2026: Drop In Above - Reason - Add Perm. Tenants and callouts. ==========================================>

function Save-SlipBoardData {
    param(
        [Parameter(Mandatory)]
        [array]$Data
    )

    $Data |
        Sort-Object SlipNumber |
        Select-Object SlipNumber, Status, Note, User, Timestamp |
        Export-Csv -Path $SlipBoardFile -NoTypeInformation -Encoding UTF8
}

function Get-SlipRecord {
    param(
        [Parameter(Mandatory)]
        [int]$SlipNumber
    )

    return $script:SlipData | Where-Object { $_.SlipNumber -eq $SlipNumber } | Select-Object -First 1
}

function Get-SlipColor {
    param(
        [Parameter(Mandatory)]
        [string]$Status
    )

    switch ($Status) {
        "Open_Slip"  { return [System.Drawing.Color]::Lime }
        "COMMERCIAL" { return [System.Drawing.Color]::Silver }
        "Overnight"  { return [System.Drawing.Color]::Yellow }
        "Follow-Up"   { return [System.Drawing.Color]::DodgerBlue }
        default      { return [System.Drawing.Color]::Red }
    }
}

function Get-DisplayTimestamp {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    try {
        return (Get-Date $Value -Format "MM/dd/yyyy hh:mm tt") 
    }
    catch {
        return $Value
    }
}

# =====================================================================================================================================================================
# STATE
# =====================================================================================================================================================================

$script:SlipData = @{}
$script:SlipButtons = @{}
$script:SelectedSlips = New-Object System.Collections.Generic.List[int]

# =====================================================================================================================================================================
# UI HELPERS
# =====================================================================================================================================================================

function Write-BoardStatus {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $txtStatus.AppendText("[$timestamp] $Message`r`n") # Carrage Return - New Line
    $txtStatus.SelectionStart = $txtStatus.Text.Length
    $txtStatus.ScrollToCaret()
}

function Update-DetailsPanel {
    param(
        [Parameter(Mandatory)]
        [int]$SlipNumber
    )

    $record = Get-SlipRecord -SlipNumber $SlipNumber
    if (-not $record) {
        $txtDetails.Text = "Slip $SlipNumber not found."
        return
    }

    $txtDetails.Text = @"
Slip $($record.SlipNumber)
Status: $($record.Status)
Note: $($record.Note)
By: $($record.User)
At: $(Get-DisplayTimestamp $record.Timestamp)
"@
}

function Update-SelectedSummary {
    if ($script:SelectedSlips.Count -eq 0) {
        $lblSelected.Text = "Selected Slips: none"
        return
    }

    $sorted = $script:SelectedSlips | Sort-Object
    $lblSelected.Text = "Selected slips: " + ($sorted -join ", ")
}

function Set-ButtonSelectionStyle {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.Button]$Button,

        [Parameter(Mandatory)]
        [bool]$Selected
    )

    if ($Selected) {
        $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $Button.FlatAppearance.BorderSize = 3
        $Button.FlatAppearance.BorderColor = [System.Drawing.Color]::Black
    }
    else {
        $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    }
}

function Refresh-SlipBoard {
    $script:SlipData = Import-SlipBoardData

    foreach ($slip in $script:SlipButtons.Keys) {
        $button = $script:SlipButtons[$slip]
        $record = Get-SlipRecord -SlipNumber $slip

        if ($record) {
            $button.BackColor = Get-SlipColor -Status $record.Status
            $button.ForeColor = if ($record.Status -eq "Follow-Up") { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
            $button.Text  = [string]$slip
        }
    }

    Update-SelectedSummary 
    Write-BoardStatus "Slip board refreshed."
}

function Clear-Selection {
    foreach ($slip in @($script:SelectedSlips)) {
        if ($script:SlipButtons.ContainsKey($slip)) {
            Set-ButtonSelectionStyle -Button $script:SlipButtons[$slip] -Selected $false
        }
    }

    $script:SelectedSlips.Clear()
    Update-SelectedSummary
    Write-BoardStatus "Selections cleared."
}
#  
function Toggle-SlipSelection {
    param(
        [Parameter(Mandatory)]
        [int]$SlipNumber
    )

    $button = $script:SlipButtons[$SlipNumber]
    if (-not $button) { return }
# April 1st 2026: Drop In Below - Reason - Add Perm. Tenants and callouts. ==========================================>

    $record = Get-SlipRecord -SlipNumber $SlipNumber
    if (-not $record) { return }
    # Show Tenant in the Status Log.
    if ($record.Status -eq "OCCUPIED") {
# April 1st 2026: The below line will handle padding e.g.001 
        $tenant = ($script:SlipMasterIndex | Where-Object { [int]$_.SlipNumber -eq $SlipNumber } | Select-Object -First 1).TenantName
        
        if ($tenant) {
            Write-BoardStatus "Slip $SlipNumber is OCCUPIED by $tenant."
        }
        else {
            Write-BoardStatus "Slip $SlipNumber is OCCUPIED."
        }                 

        return
    }
# Lock the OCCUPIED slips
    if  ($record.Status -eq "OCCUPIED") {
        Write-BoardStatus "Slip $SlipNumber is OCCUPIED and cannot be modified."
        return
    }
# April 1st 2026: Drop In Above - Reason - Add Perm. Tenants and callouts. ==========================================> 

    if ($script:SelectedSlips.Contains($SlipNumber)) {
        [void]$script:SelectedSlips.Remove($SlipNumber)
        Set-ButtonSelectionStyle -Button $button -Selected $false
    }
    else {
        if ($script:SelectedSlips.Count -ge 3) {
            [System.Windows.Forms.MessageBox]::Show(
                "More than 3 slips can not be selected at once.",
                "Selection Limit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        [void]$script:SelectedSlips.Add($SlipNumber)
        Set-ButtonSelectionStyle -Button $button -Selected $true
    }

    Update-SelectedSummary
    Update-DetailsPanel -SlipNumber $SlipNumber
}

function Update-SelectedSlipStatus {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Overnight", "Follow-Up")]
        [string]$TargetStatus
    )

    if ($script:SelectedSlips.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Select at least one slip first.",
            "No Selection",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $note = $txtNewNote.Text.Trim()

    foreach ($slip in $script:SelectedSlips) {
        $record = Get-SlipRecord -SlipNumber $slip
        if (-not $record) { continue }

        $record.Status    = $TargetStatus
        $record.Note      = $note
        $record.User      = $env:USERNAME
        $record.Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    Save-SlipBoardData -Data $script:SlipData
    Write-BoardStatus "Updated slips [$($script:SelectedSlips -join ', ')] to [$TargetStatus]."

    if (-not [string]::IsNullOrWhiteSpace($note)) {
        Write-BoardStatus "Note saved: $note"
    }

    Refresh-SlipBoard
    
    $lastSelected = $script:SelectedSlips | Select-Object -Last 1
    Clear-Selection
    $txtNewNote.Clear()

    if ($lastSelected) {
        Update-DetailsPanel -SlipNumber $lastSelected
    }

    [System.Windows.Forms.MessageBox]::Show(
        "Selected slips updated to $TargetStatus.",
        "Update Complete",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Set-SlipOpen {
    if ($script:SelectedSlips.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Select at least one slip first.",
            "No Selection",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    foreach ($slip in $script:SelectedSlips) {
        $record = Get-SlipRecord -SlipNumber $slip
        if (-not $record) { continue }

        $record.Status    = "Open_Slip"
        $record.Note      = ""
        $record.User      = ""
        $record.Timestamp = ""
    }
    
    Save-SlipBoardData -Data $script:SlipData
    Write-BoardStatus "Marked slips [$($script:SelectedSlips -join ', ')] as Open_Slip."
                
    $lastSelected = $script:SelectedSlips | Select-Object -Last 1

    Refresh-SlipBoard
    Clear-Selection
    $txtNewNote.Clear()

    if ($lastSelected) {
        Update-DetailsPanel -SlipNumber $lastSelected
    }

    [System.Windows.Forms.MessageBox]::Show(
        "Selected slips marked open.",
        "Update Complete",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )| Out-Null
}

function Show-SlipContextMenu {
    param(
        [Parameter(Mandatory)]
        [int]$SlipNumber,
                
        [Parameter(Mandatory)]
        [System.Drawing.Point]$ScreenPoint
    )
    # Instructions on the form for staff
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    
    $miDetails = $menu.Items.Add("Show Details")
    $miSelect  = $menu.Items.Add("Toggle Selection")
    $miOpen    = $menu.Items.Add("Mark Open")
    $miOver    = $menu.Items.Add("Set Overnight")
    $miFollow  = $menu.Items.Add("Set Follow-Up")

    $miDetails.Add_Click({
        Update-DetailsPanel -SlipNumber $SlipNumber
    })

    $miSelect.Add_Click({
        Toggle-SlipSelection -SlipNumber $SlipNumber
    })

    $miOpen.Add_Click({
        Clear-Selection
        Toggle-SlipSelection -SlipNumber $SlipNumber
        Set-SlipOpen
    })
    
    $miOver.Add_Click({
        Clear-Selection 
        Toggle-SlipSelection -SlipNumber $SlipNumber
        Update-SelectedSlipStatus -TargetStatus "Overnight"
    })

    $miFollow.Add_Click({
        Clear-Selection
        Toggle-SlipSelection -SlipNumber $SlipNumber
        Update-SelectedSlipStatus -TargetStatus "Follow-Up"
    })

    $menu.Show($ScreenPoint)
}

# =====================================================================================================================================================================
# FORM 
# =====================================================================================================================================================================

Initialize-SlipBoardData
Sync-SlipBoardWithIndex
$script:SlipData = Import-SlipBoardData
$script:SlipMasterIndex = Import-SlipIndex

$form = New-Object System.Windows.Forms.Form
$form.Text = "Marina Slip Board"
$form.Size = New-Object System.Drawing.Size(1300, 900) # (1280, 900) <-- Origional size using exact Specra Monitor 
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::LightSteelBlue
$form.TopMost = $true
#==== [tool tip Added 04-01-2026] ====
$toolTip = New-Object System.Windows.Forms.ToolTip
# Title --> I am leaving the title out for now but left place holders
#$lblTitle
#$lblTitle
#$lblTitle
#$lblTitle
#$lblTitle
#$lblTitle
# I left the wood part of the dock out for now - but another set of lables can be used. The trick is position - All the slips/buttons are set just like the marina and check box logic version written in VBA
#$lblSub
#$lblSub
#$lblSub
#$lblSub
#$lblSub
#$lblSub
# This entire next section is what AI Agent: PowershellKeith could not do
# Slip Area ->> Important for adjusting the frames around the sections of the form "Design"

$grpBoard = New-Object System.Windows.Forms.GroupBox
$grpBoard.Text = "Slip Board"
$grpBoard.Size = New-Object System.Drawing.Size(900, 500)

$grpBoard.Location = New-Object System.Drawing.Point(20, 90)
$form.Controls.Add($grpBoard)

# Right ops panel "Operations"
$grpOps = New-Object System.Windows.Forms.GroupBox
$grpOps.Text = "Operations"
$grpOps.Size = New-Object System.Drawing.Size(320, 730) # Note the grouped section are programmed for the form size (1300, 900)
$grpOps.Location = New-Object System.Drawing.Point(930, 90)
# Author Notes: The 910, 85 --> ajust 85 to 80 to bring closer to the top of the form.
$form.Controls.Add($grpOps)


#$grpStatus = New-Object System.Windows.Forms.GroupBox
#$grpStatus.Text = "Status Log"
#$grpStatus.Size = New-Object System.Drawing.Size(450, 110)
#$grpStatus.Location = New-Object System.Drawing.Point(790, 610)
#$form.Controls.Add($grpStatus)

$grpStatus = New-Object System.Windows.Forms.GroupBox
$grpStatus.Text = "Status Log"
$grpStatus.Size = New-Object System.Drawing.Size(900, 200)
$grpStatus.Location = New-Object System.Drawing.Point(20, 620)
$form.Controls.Add($grpStatus)

# =====================================================================================================================================================================
# NEW DYNAMIC LAYOUT SYSTEM | The system used made the design more managable using anchor points | New, based on logic written on home training range 2026
# =====================================================================================================================================================================
$slipLayout = @{} # The grid layout engine.
# Also have logic to locate X and Y points by clicking the sides of the form, this helped some but not much.
function Add-SlipRowFromAnchor {
    param(
        [int[]]$SlipNumbers,
        [int]$StartX,
        [int]$Y,
        [int]$Step = 30,
        [string]$Direction = "Left"
    )

    $currentX = $StartX

    foreach ($slip in $SlipNumbers) {

        $script:slipLayout[$slip] = @{
            X = $currentX
            Y = $Y
        }

        if ($Direction -eq "Left") {
            $currentX -= $Step
        }
        else {
            $currentX += $Step
        }
    }
}
# ==== [Grid Engine Above] ====
# =====================================================================================================================================================================
# BUILD LAYOUT | 04-03-2026 -> Add no more changes. Only if more slips added. The Customer Service Communications Console holds the logic for any other notes.
# =====================================================================================================================================================================

# Top Rows
# Add-SlipRowFromAnchor -SlipNumbers (43..56) -StartX 400 -Y 120 -Direction Left # 1st Version
Add-SlipRowFromAnchor -SlipNumbers (43..56) -StartX 400 -Y 75 #Jason Edit
# Move to the right 
Add-SlipRowFromAnchor -SlipNumbers (57..70) -StartX 450 -Y 75 -Direction Right

# Bottom Rows
Add-SlipRowFromAnchor -SlipNumbers (1..10)  -StartX 400 -Y 350 -Step 30 -Direction Left
Add-SlipRowFromAnchor -SlipNumbers (20..11) -StartX 400 -Y 320 -Step 30 -Direction Left

# Middle Rows
Add-SlipRowFromAnchor -SlipNumbers (21..32) -StartX 400 -Y 230 -Step 30 -Direction Left
Add-SlipRowFromAnchor -SlipNumbers (42..33) -StartX 400 -Y 200 -Direction Left
# Move to the right
Add-SlipRowFromAnchor -SlipNumbers (71..80) -StartX 450 -Y 200 -Direction Right

$pnlBoard = New-Object System.Windows.Forms.Panel
$pnlBoard.Location = New-Object System.Drawing.Point(10, 20) 
$pnlBoard.Size = New-Object System.Drawing.Size(900, 600) 
$pnlBoard.BackColor = [System.Drawing.Color]::LightSteelBlue 
$grpBoard.Controls.Add($pnlBoard)


foreach ($i in $slipLayout.Keys) {

    $pos = $slipLayout[$i]
    
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = [string]$i
    $btn.Tag = $i

    # Size Control (new compact buttons) | Using buttons not checkboxes
    $btn.Size = New-Object System.Drawing.Size(28, 18)

    $btn.Location = New-Object System.Drawing.Point($pos.X, $pos.Y)

    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 6, [System.Drawing.FontStyle]::Bold)
    $btn.UseVisualStyleBackColor = $false

    # Default color (will be overridden by Refresh)
    $btn.BackColor = [System.Drawing.Color]::Lime

    # LEFT CLICK (selection logic stays)
    $btn.Add_Click({
        Toggle-SlipSelection -SlipNumber ([int]$this.Tag)
    })

    # RIGHT CLICK (context menu stays)
    $btn.Add_MouseUp({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            Show-SlipContextMenu `
                -SlipNumber ([int]$this.Tag) `
                -ScreenPoint ([System.Windows.Forms.Control]::MousePosition)
        }
    })
# April 1st 2026: Drop In Below - Reason - Add Perm. Tenants and callouts. 						   ==========================================>
# TOOLTIP LOGIC: Call Outs for the OCCUPIED SLIPS -> Calls out the Tenant Name for quik ref.
    $record = Get-SlipRecord -SlipNumber $i 

    if ($record.Status -eq "OCCUPIED") {

        $tenant = ($script:SlipMasterIndex | Where-Object { [int]$_.SlipNumber -eq $i } | Select-Object -First 1).TenantName

        if ($tenant) {
                $toolTip.SetToolTip($btn, "Occupied: $tenant")
            }
            else {
                $toolTip.SetToolTip($btn, "Occupied") # Yes these are lower case Occupied - quik look REF. to the occupied slip
        }
    }
# April 1st 2026: Drop In Above - Reason - Add Perm. Tenants and callouts. 						   ==========================================>
    $script:SlipButtons[$i] = $btn
    $pnlBoard.Controls.Add($btn)
}

# =====================================================================================================================================================================
# OPS PANEL CONTROLS 
# =====================================================================================================================================================================
$lblIntructions = New-Object System.Windows.Forms.Label
$lblIntructions.Text = "1. Click up to 3 slips`r`n2. Chose status`r`n3. Optional note`r`n4. Update"
$lblIntructions.Location = New-Object System.Drawing.Point(20, 30)
$lblIntructions.Size = New-Object System.Drawing.Size(380, 70)
$lblIntructions.Font = New-Object System.Drawing.Font("Segoe UI", 09, [System.Drawing.FontStyle]::Bold)
$grpOps.Controls.Add($lblIntructions)

$lblSelected = New-Object System.Windows.Forms.Label
$lblSelected.Text = "Selected Slips: none"
$lblSelected.Location = New-Object System.Drawing.Point(20, 195)
$lblSelected.Size = New-Object System.Drawing.Size(390, 25)
$lblSelected.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$grpOps.Controls.Add($lblSelected)

$lblDetailsTitle = New-Object System.Windows.Forms.Label
$lblDetailsTitle.Text = "Slip Details"
$lblDetailsTitle.Location = New-Object System.Drawing.Point(20, 220)
$lblDetailsTitle.Size = New-Object System.Drawing.Point(200, 20)
$lblDetailsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$grpOps.Controls.Add($lblDetailsTitle)

$txtDetails = New-Object System.Windows.Forms.TextBox
$txtDetails.Location = New-Object System.Drawing.Point(20, 250)
$txtDetails.Size = New-Object System.Drawing.Size(290, 130)
$txtDetails.Multiline = $true
$txtDetails.ReadOnly = $true
$txtDetails.ScrollBars = "Vertical"
$txtDetails.Font = New-Object System.Drawing.Font("Consolas", 10)
$grpOps.Controls.Add($txtDetails)

$lblNewNote = New-Object System.Windows.Forms.Label
$lblNewNote.Text = "Shared note for selected slips"
$lblNewNote.Location = New-Object System.Drawing.Point(20, 400)
$lblNewNote.Size = New-Object System.Drawing.Size(250, 20)
$lblNewNote.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$grpOps.Controls.Add($lblNewNote)

$txtNewNote = New-Object System.Windows.Forms.TextBox
$txtNewNote.Location = New-Object System.Drawing.Point(20, 445) # Adjustment Point
$txtNewNote.Size = New-Object System.Drawing.Point(290, 60)
$txtNewNote.Multiline = $true
$txtNewNote.ScrollBars = "Vertical"
$txtNewNote.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$grpOps.Controls.Add($txtNewNote)

$btnOvernight = New-Object System.Windows.Forms.Button
$btnOvernight.Text = "Set Overnight"
$btnOvernight.Size = New-Object System.Drawing.Size(100, 30)
$btnOvernight.Location = New-Object System.Drawing.Point(20, 525)
$btnOvernight.BackColor = [System.Drawing.Color]::Khaki
$grpOps.Controls.Add($btnOvernight)

$btnFollowUp = New-Object System.Windows.Forms.Button
$btnFollowUp.Text = "Set Follow Up"
$btnFollowUp.Size = New-Object System.Drawing.Size(100, 30)
$btnFollowUp.Location = New-Object System.Drawing.Point(120, 525)
$btnFollowUp.BackColor = [System.Drawing.Color]::DodgerBlue
$btnFollowUp.ForeColor = [System.Drawing.Color]::White
$grpOps.Controls.Add($btnFollowUp)

$btnMarkOpen = New-Object System.Windows.Forms.Button
$btnMarkOpen.Text = "Mark Open"
$btnMarkOpen.Size = New-Object System.Drawing.Size(100, 30)
$btnMarkOpen.Location = New-Object System.Drawing.Point(210, 525)
$btnMarkOpen.BackColor = [System.Drawing.Color]::PaleGreen
$grpOps.Controls.Add($btnMarkOpen)

$btnClearSelection = New-Object System.Windows.Forms.Button
$btnClearSelection.Text = "Clear Selection"
$btnClearSelection.Size = New-Object System.Drawing.Size(100, 30)
$btnClearSelection.Location = New-Object System.Drawing.Point(20, 600)
$grpOps.Controls.Add($btnClearSelection)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Refresh Board"
$btnRefresh.Size = New-Object System.Drawing.Size(100, 30)
$btnRefresh.Location = New-Object System.Drawing.Point(210, 600)
$grpOps.controls.Add($btnRefresh)

# =====================================================================================================================================================================
# LEGEND | => Removed the legend. Not Needed ==> The legent area could hold the math involved with the (Cost * Tax)
# =====================================================================================================================================================================

# =====================================================================================================================================================================
# STATUS BOX
# =====================================================================================================================================================================
$txtStatus = New-Object System.Windows.Forms.TextBox
$txtStatus.Location = New-Object System.Drawing.Point(15, 22)
$txtStatus.Size = New-Object System.Drawing.Size(870, 150)
#$txtStatus.Size = New-Object System.Drawing.Size(800, 75)
$txtStatus.Multiline = $true
$txtStatus.ReadOnly = $true
$txtStatus.ScrollBars = "Vertical"
$txtStatus.Font = New-Object System.Drawing.Font("Consolas", 9)
$grpStatus.Controls.Add($txtStatus)

# =====================================================================================================================================================================
# EVENTS
# =====================================================================================================================================================================
$btnOvernight.Add_Click({
    Update-SelectedSlipStatus -TargetStatus "Overnight"
})

$btnFollowUp.Add_Click({
    Update-SelectedSlipStatus -TargetStatus "Follow-Up"
})

$btnMarkOpen.Add_Click({
    Set-SlipOpen
})

$btnClearSelection.Add_Click({
    Clear-Selection
})

$btnRefresh.Add_Click({
    Refresh-SlipBoard
})

$form.Add_Shown({
    Refresh-SlipBoard
    Update-SelectedSummary
    $txtDetails.Text = "Click a slip to view details."
    Write-BoardStatus "Slip board started."
    Write-BoardStatus "Data file: $SlipBoardFile"
})

# =====================================================================================================================================================================
# Show Form
# =====================================================================================================================================================================
[void]$form.ShowDialog()
# End
# =====================================================================================================================================================================
