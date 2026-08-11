<#
.SYNOPSIS
    Academic / Technical Archive Evidence Console

.DESCRIPTION
    Phase 1:
        Select a root directory.
        Recursively inventory files.
        Capture filesystem timestamps.
        Export a chronological raw timeline CSV.

    Phase 2:
        Select a Phase 1 CSV using OpenFileDialog.
        Classify records into academic / technical / personal /
        software-tooling / unknown categories.
        Assign likely subject, evidence type, and evidence strength.
        Display results in Out-GridView.
        Export enriched evidence CSV.
        08-10-2026 => Drop-Ins ready for the year format and SessionID
.NOTES
    Read-only against source files.
    Windows PowerShell 5.1.
    No external modules required.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =====================================================================================
# SCRIPT VARIABLES
# =====================================================================================

$script:LastOutputFolder = $null

# =====================================================================================
# GUI LOG
# =====================================================================================

function Add-ConsoleMessage {

    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $time = Get-Date -Format 'HH:mm:ss'

    $script:lstConsole.Items.Add(
        "[$time] $Message"
    ) | Out-Null

    $script:lstConsole.TopIndex =
        $script:lstConsole.Items.Count - 1

    [System.Windows.Forms.Application]::DoEvents()
}

# =====================================================================================
# PHASE 1
# BUILD RAW FILESYSTEM TIMELINE
# =====================================================================================

function Invoke-PhaseOne {

    try {

        Add-ConsoleMessage 'PHASE 1 started.'

        # -------------------------------------------------------------------------
        # Select root directory
        # -------------------------------------------------------------------------

        $folderDialog =
            New-Object System.Windows.Forms.FolderBrowserDialog

        $folderDialog.Description =
            'Select the root directory to inventory'

        $folderDialog.ShowNewFolderButton = $false

        if (
            $folderDialog.ShowDialog() -ne
            [System.Windows.Forms.DialogResult]::OK
        ) {
            Add-ConsoleMessage 'PHASE 1 cancelled.'
            return
        }

        $rootPath = $folderDialog.SelectedPath

        Add-ConsoleMessage "Selected directory: $rootPath"
        Add-ConsoleMessage 'Recursively scanning files...'

        # -------------------------------------------------------------------------
        # Read filesystem
        # -------------------------------------------------------------------------

        $results = foreach (
            $file in Get-ChildItem `
                -LiteralPath $rootPath `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue
        ) {

            [pscustomobject][ordered]@{
                FileName      = $file.Name
                Directory     = $file.DirectoryName
                FullPath      = $file.FullName
                Extension     = $file.Extension
                CreationTime  = $file.CreationTime
                LastWriteTime = $file.LastWriteTime
                SizeKB        = [math]::Round(
                    $file.Length / 1KB,
                    2
                )
            }
        }

        # -------------------------------------------------------------------------
        # Sort oldest LastWriteTime first
        # -------------------------------------------------------------------------

        $results = @(
            $results |
                Sort-Object LastWriteTime, CreationTime
        )

        Add-ConsoleMessage "Files inventoried: $($results.Count)"

        # -------------------------------------------------------------------------
        # Export Phase 1
        # -------------------------------------------------------------------------

        $runTime =
            Get-Date -Format 'yyyy-MM-dd_HHmmss'

        $csvPath =
            Join-Path `
                -Path $rootPath `
                -ChildPath "Historical_File_Timeline_$runTime.csv"

        $results |
            Export-Csv `
                -LiteralPath $csvPath `
                -NoTypeInformation `
                -Encoding UTF8

        $script:LastOutputFolder = $rootPath

        Add-ConsoleMessage 'PHASE 1 complete.'
        Add-ConsoleMessage "Created: $csvPath"

        # -------------------------------------------------------------------------
        # Display
        # -------------------------------------------------------------------------

        $results |
            Out-GridView `
                -Title "Phase 1 - Historical File Timeline"

    }
    catch {

        Add-ConsoleMessage "PHASE 1 ERROR: $($_.Exception.Message)"

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'Phase 1 Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

# =====================================================================================
# PHASE 2
# CLASSIFICATION LOGIC
# =====================================================================================

function Get-EvidenceClassification {

    param(
        [Parameter(Mandatory)]
        [object]$Record
    )

    $fileName =
        ([string]$Record.FileName).ToUpperInvariant()

    $directory =
        ([string]$Record.Directory).ToUpperInvariant()

    $fullText =
        "$fileName $directory"

    $classification = 'Unknown'
    $subject        = 'Unknown'
    $evidenceType   = 'General File'
    $academicSignal = 'No'
    $technicalSignal = 'No'
    $strength       = 'Weak'

    # -------------------------------------------------------------------------
    # Valencia / academic
    # -------------------------------------------------------------------------

    if (
        $fullText -match
        'VALENCIA|COLLEGE|COURSE|ASSIGNMENT|MODULE|LAB|MIDTERM|FINAL PROJECT'
    ) {

        $academicSignal = 'Yes'
        $classification = 'Academic'
        $strength = 'Strong'
    }

    # -------------------------------------------------------------------------
    # Cybersecurity / networking
    # -------------------------------------------------------------------------

    if (
        $fullText -match
        'CYBER|SECURITY\+|SECURITY PLUS|NETWORK SECURITY|ETHICAL HACK|PENETRATION|PENTEST|PEN TEST|THREAT ACTOR|THREAT VECTOR|FORENSIC|WIRESHARK|FIREWALL|AUTHENTICATION|AUTHORIZATION|NVD|MSFVENOM'
    ) {

        $subject = 'Cybersecurity'
        $technicalSignal = 'Yes'

        if ($academicSignal -eq 'Yes') {
            $classification = 'Academic / Technical'
        }
        else {
            $classification = 'Technical'
        }

        $strength = 'Strong'
    }

    # -------------------------------------------------------------------------
    # Networking
    # -------------------------------------------------------------------------

    if (
        $fullText -match
        'NETWORK|ROUTER|SWITCH|TOPOLOGY|TOPO|TCP|UDP|DNS|DHCP|SUBNET|CISCO'
    ) {

        if ($subject -eq 'Unknown') {
            $subject = 'Network Engineering'
        }

        $technicalSignal = 'Yes'

        if ($academicSignal -eq 'Yes') {
            $classification = 'Academic / Technical'
        }
        else {
            $classification = 'Technical'
        }

        $strength = 'Strong'
    }

    # -------------------------------------------------------------------------
    # PowerShell
    # -------------------------------------------------------------------------

    if (
        $fullText -match
        'POWERSHELL|\.PS1$|\.PSM1$|\.PSD1$'
    ) {

        $subject = 'PowerShell'
        $technicalSignal = 'Yes'

        if ($academicSignal -eq 'Yes') {
            $classification = 'Academic / Technical'
        }
        else {
            $classification = 'Technical'
        }

        $strength = 'Strong'
    }

    # -------------------------------------------------------------------------
    # VBA / Excel automation
    # -------------------------------------------------------------------------

    if (
        $fullText -match
        'VBA|MACRO|\.XLSM$|EXCEL AUTOMATION'
    ) {

        $subject = 'VBA / Excel Automation'
        $technicalSignal = 'Yes'

        if ($academicSignal -eq 'Yes') {
            $classification = 'Academic / Technical'
        }
        else {
            $classification = 'Technical'
        }

        if ($strength -eq 'Weak') {
            $strength = 'Moderate'
        }
    }

    # -------------------------------------------------------------------------
    # Linux / server / infrastructure
    # -------------------------------------------------------------------------

    if (
        $fullText -match
        'LINUX|RHEL|RED HAT|ANSIBLE|ACTIVE DIRECTORY|SERVER|PUTTY|SSH'
    ) {

        if ($subject -eq 'Unknown') {
            $subject = 'Systems Administration'
        }

        $technicalSignal = 'Yes'

        if ($classification -eq 'Unknown') {
            $classification = 'Technical'
        }

        if ($strength -eq 'Weak') {
            $strength = 'Moderate'
        }
    }

    # -------------------------------------------------------------------------
    # Determine evidence type
    # -------------------------------------------------------------------------

    if ($fullText -match 'LAB') {
        $evidenceType = 'Lab'
    }
    elseif ($fullText -match 'ASSIGNMENT') {
        $evidenceType = 'Assignment'
    }
    elseif ($fullText -match 'MIDTERM') {
        $evidenceType = 'Midterm'
    }
    elseif ($fullText -match 'FINAL') {
        $evidenceType = 'Final / Project'
    }
    elseif ($fullText -match 'NOTES|OUTLINE') {
        $evidenceType = 'Notes / Study Material'
    }
    elseif ($Record.Extension -match '\.ps1|\.psm1') {
        $evidenceType = 'PowerShell Script'
    }
    elseif ($Record.Extension -match '\.odt|\.doc|\.docx') {
        $evidenceType = 'Document'
    }
    elseif ($Record.Extension -match '\.pdf') {
        $evidenceType = 'PDF'
    }
    elseif ($Record.Extension -match '\.png|\.jpg|\.jpeg') {
        $evidenceType = 'Screenshot / Image'
    }

    # -------------------------------------------------------------------------
    # Personal media
    # -------------------------------------------------------------------------

    if (
        $Record.Extension -match
        '\.wav|\.mp3|\.flac|\.aac|\.m4a'
    ) {

        if (
            $academicSignal -eq 'No' -and
            $technicalSignal -eq 'No'
        ) {
            $classification = 'Personal / Media'
            $subject = 'Personal Media'
            $strength = 'Excluded'
        }
    }

    # -------------------------------------------------------------------------
    # Portable application / software distribution noise
    # -------------------------------------------------------------------------

    if (
        $fullText -match
        'PORTABLEAPPS|7-ZIPPORTABLE|RUFUSPORTABLE|PUTTYPORTABLE'
    ) {

        if (
            $academicSignal -eq 'No' -and
            $technicalSignal -eq 'No'
        ) {
            $classification = 'Software / Tooling'
            $subject = 'Software Distribution'
            $strength = 'Excluded'
        }
    }

    return [pscustomobject][ordered]@{
        Classification  = $classification
        LikelySubject   = $subject
        EvidenceType    = $evidenceType
        AcademicSignal  = $academicSignal
        TechnicalSignal = $technicalSignal
        EvidenceStrength = $strength
    }
}

# =====================================================================================
# PHASE 2
# SELECT PHASE 1 CSV AND ENRICH IT
# =====================================================================================

function Invoke-PhaseTwo {

    try {

        Add-ConsoleMessage 'PHASE 2 started.'

        # -------------------------------------------------------------------------
        # Select Phase 1 CSV
        # -------------------------------------------------------------------------

        $fileDialog =
            New-Object System.Windows.Forms.OpenFileDialog

        $fileDialog.Title =
            'Select the Phase 1 Historical File Timeline CSV'

        $fileDialog.Filter =
            'CSV Files (*.csv)|*.csv'

        $fileDialog.Multiselect = $false
        $fileDialog.CheckFileExists = $true

        if (
            $fileDialog.ShowDialog() -ne
            [System.Windows.Forms.DialogResult]::OK
        ) {
            Add-ConsoleMessage 'PHASE 2 cancelled.'
            return
        }

        $csvPath = $fileDialog.FileName

        Add-ConsoleMessage "Selected CSV: $csvPath"
        Add-ConsoleMessage 'Importing Phase 1 records...'

        # -------------------------------------------------------------------------
        # Import
        # -------------------------------------------------------------------------

        $records = @(
            Import-Csv `
                -LiteralPath $csvPath
        )

        if ($records.Count -eq 0) {
            throw 'The selected CSV contains no records.'
        }

        Add-ConsoleMessage "Records imported: $($records.Count)"
        Add-ConsoleMessage 'Classifying evidence...'

        # -------------------------------------------------------------------------
        # Enrich
        # -------------------------------------------------------------------------

        $classifiedRecords = foreach ($record in $records) {

            $classification =
                Get-EvidenceClassification `
                    -Record $record

            $lastWrite =
                [datetime]$record.LastWriteTime

            $creation =
                [datetime]$record.CreationTime

            [pscustomobject][ordered]@{

                Year =
                    $lastWrite.Year

                Classification =
                    $classification.Classification

                LikelySubject =
                    $classification.LikelySubject

                EvidenceType =
                    $classification.EvidenceType

                AcademicSignal =
                    $classification.AcademicSignal

                TechnicalSignal =
                    $classification.TechnicalSignal

                EvidenceStrength =
                    $classification.EvidenceStrength

                FileName =
                    $record.FileName

                Extension =
                    $record.Extension

                Directory =
                    $record.Directory

                FullPath =
                    $record.FullPath

                CreationTime =
                    $creation

                LastWriteTime =
                    $lastWrite

                SizeKB =
                    $record.SizeKB
            }
        }

        # -------------------------------------------------------------------------
        # Sort
        # -------------------------------------------------------------------------

        $classifiedRecords = @(
            $classifiedRecords |
                Sort-Object `
                    Year,
                    LastWriteTime,
                    FileName
        )

        # -------------------------------------------------------------------------
        # Export
        # -------------------------------------------------------------------------

        $sourceFolder =
            Split-Path `
                -Path $csvPath `
                -Parent

        $runTime =
            Get-Date -Format 'yyyy-MM-dd_HHmmss'

        $outputPath =
            Join-Path `
                -Path $sourceFolder `
                -ChildPath "Academic_Technical_Evidence_$runTime.csv"

        $classifiedRecords |
            Export-Csv `
                -LiteralPath $outputPath `
                -NoTypeInformation `
                -Encoding UTF8

        $script:LastOutputFolder = $sourceFolder

        # -------------------------------------------------------------------------
        # Statistics
        # -------------------------------------------------------------------------

        $academicCount = @(
            $classifiedRecords |
                Where-Object {
                    $_.AcademicSignal -eq 'Yes'
                }
        ).Count

        $technicalCount = @(
            $classifiedRecords |
                Where-Object {
                    $_.TechnicalSignal -eq 'Yes'
                }
        ).Count

        $strongCount = @(
            $classifiedRecords |
                Where-Object {
                    $_.EvidenceStrength -eq 'Strong'
                }
        ).Count

        Add-ConsoleMessage 'PHASE 2 complete.'
        Add-ConsoleMessage "Academic evidence records: $academicCount"
        Add-ConsoleMessage "Technical evidence records: $technicalCount"
        Add-ConsoleMessage "Strong evidence records: $strongCount"
        Add-ConsoleMessage "Created: $outputPath"

        # -------------------------------------------------------------------------
        # Display useful records first
        # -------------------------------------------------------------------------

        $classifiedRecords |
            Where-Object {
                $_.EvidenceStrength -ne 'Excluded'
            } |
            Out-GridView `
                -Title 'Phase 2 - Academic and Technical Evidence'

    }
    catch {

        Add-ConsoleMessage "PHASE 2 ERROR: $($_.Exception.Message)"

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'Phase 2 Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

# =====================================================================================
# OPEN LAST OUTPUT FOLDER
# =====================================================================================

function Open-LastOutputFolder {

    if (
        [string]::IsNullOrWhiteSpace(
            $script:LastOutputFolder
        )
    ) {

        [System.Windows.Forms.MessageBox]::Show(
            'No output folder has been created yet.',
            'Archive Evidence Console',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null

        return
    }

    Start-Process `
        -FilePath 'explorer.exe' `
        -ArgumentList $script:LastOutputFolder
}

# =====================================================================================
# BUILD GUI
# =====================================================================================

$form =
    New-Object System.Windows.Forms.Form

$form.Text =
    'Academic and Technical Archive Evidence Console'

$form.StartPosition =
    [System.Windows.Forms.FormStartPosition]::CenterScreen

$form.Size =
    New-Object System.Drawing.Size(900, 620)

$form.MinimumSize =
    New-Object System.Drawing.Size(800, 550)

$form.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        10
    )

# =====================================================================================
# TITLE
# =====================================================================================

$lblTitle =
    New-Object System.Windows.Forms.Label

$lblTitle.Text =
    'Academic and Technical Archive Evidence Console'

$lblTitle.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        16,
        [System.Drawing.FontStyle]::Bold
    )

$lblTitle.AutoSize = $true
$lblTitle.Location =
    New-Object System.Drawing.Point(20, 20)

$form.Controls.Add($lblTitle)

# =====================================================================================
# DESCRIPTION
# =====================================================================================

$lblDescription =
    New-Object System.Windows.Forms.Label

$lblDescription.Text = @'
Phase 1 inventories the filesystem.
Phase 2 classifies the Phase 1 CSV into academic and technical evidence.
Source files are never modified.
'@

$lblDescription.AutoSize = $true
$lblDescription.Location =
    New-Object System.Drawing.Point(22, 60)

$form.Controls.Add($lblDescription)

# =====================================================================================
# BUTTONS
# =====================================================================================

$btnPhaseOne =
    New-Object System.Windows.Forms.Button

$btnPhaseOne.Text =
    'Phase 1 - Build Timeline'

$btnPhaseOne.Size =
    New-Object System.Drawing.Size(200, 45)

$btnPhaseOne.Location =
    New-Object System.Drawing.Point(22, 125)

$btnPhaseOne.Add_Click({
    Invoke-PhaseOne
})

$form.Controls.Add($btnPhaseOne)

# -------------------------------------------------------------------------------------

$btnPhaseTwo =
    New-Object System.Windows.Forms.Button

$btnPhaseTwo.Text =
    'Phase 2 - Classify Evidence'

$btnPhaseTwo.Size =
    New-Object System.Drawing.Size(200, 45)

$btnPhaseTwo.Location =
    New-Object System.Drawing.Point(235, 125)

$btnPhaseTwo.Add_Click({
    Invoke-PhaseTwo
})

$form.Controls.Add($btnPhaseTwo)

# -------------------------------------------------------------------------------------

$btnOpenFolder =
    New-Object System.Windows.Forms.Button

$btnOpenFolder.Text =
    'Open Output Folder'

$btnOpenFolder.Size =
    New-Object System.Drawing.Size(180, 45)

$btnOpenFolder.Location =
    New-Object System.Drawing.Point(448, 125)

$btnOpenFolder.Add_Click({
    Open-LastOutputFolder
})

$form.Controls.Add($btnOpenFolder)

# -------------------------------------------------------------------------------------

$btnExit =
    New-Object System.Windows.Forms.Button

$btnExit.Text =
    'Exit'

$btnExit.Size =
    New-Object System.Drawing.Size(110, 45)

$btnExit.Location =
    New-Object System.Drawing.Point(640, 125)

$btnExit.Add_Click({
    $form.Close()
})

$form.Controls.Add($btnExit)

# =====================================================================================
# ACTIVITY CONSOLE LISTBOX
# =====================================================================================

$lblConsole =
    New-Object System.Windows.Forms.Label

$lblConsole.Text =
    'Activity Console'

$lblConsole.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        10,
        [System.Drawing.FontStyle]::Bold
    )

$lblConsole.AutoSize = $true
$lblConsole.Location =
    New-Object System.Drawing.Point(22, 195)

$form.Controls.Add($lblConsole)

# -------------------------------------------------------------------------------------

$script:lstConsole =
    New-Object System.Windows.Forms.ListBox

$script:lstConsole.Location =
    New-Object System.Drawing.Point(22, 220)

$script:lstConsole.Size =
    New-Object System.Drawing.Size(835, 300)

$script:lstConsole.Anchor =
    [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right

$script:lstConsole.Font =
    New-Object System.Drawing.Font(
        'Consolas',
        10
    )

$form.Controls.Add($script:lstConsole)

# =====================================================================================
# START MESSAGE
# =====================================================================================

Add-ConsoleMessage 'Archive Evidence Console ready.'
Add-ConsoleMessage 'Select Phase 1 to inventory a directory.'
Add-ConsoleMessage 'Select Phase 2 to classify an existing Phase 1 CSV.'

# =====================================================================================
# SHOW GUI
# =====================================================================================

[void]$form.ShowDialog()
