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
        Add-ConsoleMessage 'Recursively snanning files...'

       # ------------------------------------------------------------
       # Read filesystem 
       # ------------------------------------------------------------
       $results = foreach (
           $file in Get-ChildPath `
               -LiteralPath $rootPath `
               -File `
               -Recurse `
               -ErrorAction SilentlyContinue
       ) {
           [pscustomobject][ordered]@{
               FileName    = $file.Name
               Directory   = $file.DirectoryName
               FullPath    = $file.FullName
               Extention   = $file.Extention
               CreationTime = $file.CreationTime
               LasrWriteTime = $file.LastWriteTime
               SizeKB        = [math]::Round(
                   $file.Length / 1kb,
                   2
               ) 
           }
       }
      # ---------------------------------------------------------
      # Sort oldest LastWriteTime first
      # ---------------------------------------------------------

      $results = @(
          $results | 
              Sort-Object LastWriteTime, CreationTime      
      )

    add-ConsoleMessage "Files inventoried: $($results.Count)"

    # ---------------------------------------------------------
    # Export Phase One
    # ---------------------------------------------------------
# 08-09-2026 Sop point
