# START OF AUDITS

### Get SMB

```PowerShell

#requires -Version 5.1
#requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates a read-only file-server audit package.

.DESCRIPTION
    Does not create, delete, or modify shares, groups, permissions,
    quotas, or files outside the audit output directory.
#>

$TimeStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$AuditRoot = "C:\FileServerAudit\FSRM01_$TimeStamp"

New-Item -Path $AuditRoot -ItemType Directory -Force | Out-Null

Write-Host "Starting audit of $env:COMPUTERNAME..." -ForegroundColor Cyan

# ------------------------------------------------------------
# 1. Host identity and network configuration
# ------------------------------------------------------------

$ComputerSystem = Get-CimInstance Win32_ComputerSystem
$OperatingSystem = Get-CimInstance Win32_OperatingSystem

[pscustomobject]@{
    ComputerName    = $env:COMPUTERNAME
    FQDN            = "$($ComputerSystem.DNSHostName).$($ComputerSystem.Domain)"
    Domain          = $ComputerSystem.Domain
    DomainRole      = $ComputerSystem.DomainRole
    Manufacturer    = $ComputerSystem.Manufacturer
    Model           = $ComputerSystem.Model
    OperatingSystem = $OperatingSystem.Caption
    OSVersion       = $OperatingSystem.Version
    LastBootTime    = $OperatingSystem.LastBootUpTime
} |
    Export-Csv "$AuditRoot\01_Host_Identity.csv" -NoTypeInformation

Get-NetIPConfiguration |
    Select-Object InterfaceAlias,
        InterfaceDescription,
        @{Name = 'IPv4Address'; Expression = {$_.IPv4Address.IPAddress -join '; '}},
        @{Name = 'IPv4Gateway'; Expression = {$_.IPv4DefaultGateway.NextHop -join '; '}},
        @{Name = 'DNSServers'; Expression = {$_.DNSServer.ServerAddresses -join '; '}} |
    Export-Csv "$AuditRoot\02_Network_Configuration.csv" -NoTypeInformation

# ------------------------------------------------------------
# 2. SMB share inventory
# Includes administrative shares such as C$, ADMIN$, and IPC$
# ------------------------------------------------------------

$AllShares = Get-SmbShare | Sort-Object Name

$AllShares |
    Select-Object Name, Path, Description, ScopeName,
        ShareState, FolderEnumerationMode,
        CachingMode, EncryptData, ContinuouslyAvailable,
        ConcurrentUserLimit, Special |
    Export-Csv "$AuditRoot\03_All_SMB_Shares.csv" -NoTypeInformation

$AllShares |
    Where-Object {$_.Special -eq $false} |
    Select-Object Name, Path, Description, ScopeName,
        ShareState, FolderEnumerationMode,
        CachingMode, EncryptData |
    Export-Csv "$AuditRoot\04_Custom_SMB_Shares.csv" -NoTypeInformation

# ------------------------------------------------------------
# 3. SMB share-level permissions
# ------------------------------------------------------------

$ShareAccess = foreach ($Share in $AllShares) {
    try {
        Get-SmbShareAccess -Name $Share.Name -ErrorAction Stop |
            Select-Object @{Name = 'ShareName'; Expression = {$Share.Name}},
                AccountName, AccessControlType, AccessRight
    }
    catch {
        [pscustomobject]@{
            ShareName        = $Share.Name
            AccountName      = '[Unable to read]'
            AccessControlType = $null
            AccessRight      = $_.Exception.Message
        }
    }
}

$ShareAccess |
    Export-Csv "$AuditRoot\05_SMB_Share_Permissions.csv" -NoTypeInformation

# ------------------------------------------------------------
# 4. NTFS permissions on each custom share root
# ------------------------------------------------------------

$NtfsAccess = foreach ($Share in ($AllShares | Where-Object {
    $_.Special -eq $false -and $_.Path
})) {
    if (Test-Path -LiteralPath $Share.Path) {
        try {
            $Acl = Get-Acl -LiteralPath $Share.Path -ErrorAction Stop

            foreach ($Entry in $Acl.Access) {
                [pscustomobject]@{
                    ShareName        = $Share.Name
                    Path             = $Share.Path
                    Owner            = $Acl.Owner
                    Identity         = $Entry.IdentityReference.Value
                    FileSystemRights = $Entry.FileSystemRights
                    AccessType       = $Entry.AccessControlType
                    IsInherited      = $Entry.IsInherited
                    InheritanceFlags = $Entry.InheritanceFlags
                    PropagationFlags = $Entry.PropagationFlags
                }
            }
        }
        catch {
            [pscustomobject]@{
                ShareName        = $Share.Name
                Path             = $Share.Path
                Owner            = '[Unable to read]'
                Identity         = $null
                FileSystemRights = $_.Exception.Message
                AccessType       = $null
                IsInherited      = $null
                InheritanceFlags = $null
                PropagationFlags = $null
            }
        }
    }
    else {
        [pscustomobject]@{
            ShareName        = $Share.Name
            Path             = $Share.Path
            Owner            = '[Path not found]'
            Identity         = $null
            FileSystemRights = $null
            AccessType       = $null
            IsInherited      = $null
            InheritanceFlags = $null
            PropagationFlags = $null
        }
    }
}

$NtfsAccess |
    Export-Csv "$AuditRoot\06_NTFS_Share_Root_Permissions.csv" -NoTypeInformation

# ------------------------------------------------------------
# 5. Local users and groups
# ------------------------------------------------------------

Get-LocalUser |
    Select-Object Name, Enabled, Description,
        LastLogon, PasswordExpires, UserMayChangePassword |
    Export-Csv "$AuditRoot\07_Local_Users.csv" -NoTypeInformation

Get-LocalGroup |
    Select-Object Name, Description, SID |
    Export-Csv "$AuditRoot\08_Local_Groups.csv" -NoTypeInformation

$LocalGroupMembers = foreach ($Group in Get-LocalGroup) {
    try {
        Get-LocalGroupMember -Group $Group.Name -ErrorAction Stop |
            Select-Object @{Name = 'LocalGroup'; Expression = {$Group.Name}},
                Name, ObjectClass, PrincipalSource, SID
    }
    catch {
        [pscustomobject]@{
            LocalGroup     = $Group.Name
            Name           = '[Unable to enumerate]'
            ObjectClass    = $null
            PrincipalSource = $null
            SID            = $_.Exception.Message
        }
    }
}

$LocalGroupMembers |
    Export-Csv "$AuditRoot\09_Local_Group_Members.csv" -NoTypeInformation

# ------------------------------------------------------------
# 6. Volumes, disks, and storage
# ------------------------------------------------------------

Get-Volume |
    Select-Object DriveLetter, FileSystemLabel, FileSystem,
        HealthStatus, OperationalStatus,
        @{Name = 'SizeGB'; Expression = {[math]::Round($_.Size / 1GB, 2)}},
        @{Name = 'FreeGB'; Expression = {[math]::Round($_.SizeRemaining / 1GB, 2)}},
        @{Name = 'PercentFree'; Expression = {
            if ($_.Size) {
                [math]::Round(($_.SizeRemaining / $_.Size) * 100, 2)
            }
        }} |
    Export-Csv "$AuditRoot\10_Volumes.csv" -NoTypeInformation

Get-Disk |
    Select-Object Number, FriendlyName, SerialNumber,
        PartitionStyle, OperationalStatus, HealthStatus,
        IsBoot, IsSystem, IsOffline, IsReadOnly,
        @{Name = 'SizeGB'; Expression = {[math]::Round($_.Size / 1GB, 2)}} |
    Export-Csv "$AuditRoot\11_Disks.csv" -NoTypeInformation

# ------------------------------------------------------------
# 7. Current SMB sessions and open files
# ------------------------------------------------------------

Get-SmbSession |
    Select-Object ClientComputerName, ClientUserName,
        NumOpens, SecondsExists, SecondsIdle |
    Export-Csv "$AuditRoot\12_Current_SMB_Sessions.csv" -NoTypeInformation

Get-SmbOpenFile |
    Select-Object ClientComputerName, ClientUserName,
        Path, ShareRelativePath, Permissions, Locks |
    Export-Csv "$AuditRoot\13_Current_SMB_Open_Files.csv" -NoTypeInformation

# ------------------------------------------------------------
# 8. Installed roles and features
# ------------------------------------------------------------

Get-WindowsFeature |
    Where-Object Installed |
    Select-Object Name, DisplayName, InstallState |
    Export-Csv "$AuditRoot\14_Installed_Roles_Features.csv" -NoTypeInformation

# ------------------------------------------------------------
# 9. FSRM quotas, templates, screens, and file groups
# ------------------------------------------------------------

if (Get-Module -ListAvailable -Name FileServerResourceManager) {
    Import-Module FileServerResourceManager

    Get-FsrmQuota |
        Select-Object Path, Size, Usage, Disabled, SoftLimit,
            Template, MatchesTemplate |
        Export-Csv "$AuditRoot\15_FSRM_Quotas.csv" -NoTypeInformation

    Get-FsrmQuotaTemplate |
        Select-Object Name, Description, Size, SoftLimit |
        Export-Csv "$AuditRoot\16_FSRM_Quota_Templates.csv" -NoTypeInformation

    Get-FsrmFileScreen |
        Select-Object Path, Description, Active, Template,
            IncludeGroup, ExcludeGroup |
        Export-Csv "$AuditRoot\17_FSRM_File_Screens.csv" -NoTypeInformation

    Get-FsrmFileGroup |
        Select-Object Name, Description,
            @{Name = 'IncludePattern'; Expression = {$_.IncludePattern -join '; '}},
            @{Name = 'ExcludePattern'; Expression = {$_.ExcludePattern -join '; '}} |
        Export-Csv "$AuditRoot\18_FSRM_File_Groups.csv" -NoTypeInformation
}

# ------------------------------------------------------------
# 10. Share-path duplication and missing-path review
# ------------------------------------------------------------

$CustomShares = $AllShares | Where-Object {
    $_.Special -eq $false -and $_.Path
}

$PathReview = foreach ($Share in $CustomShares) {
    $SharesAtSamePath = $CustomShares |
        Where-Object {$_.Path -ieq $Share.Path}

    [pscustomobject]@{
        ShareName         = $Share.Name
        LocalPath         = $Share.Path
        PathExists        = Test-Path -LiteralPath $Share.Path
        SharesAtSamePath  = ($SharesAtSamePath.Name -join '; ')
        DuplicatePath     = $SharesAtSamePath.Count -gt 1
    }
}

$PathReview |
    Export-Csv "$AuditRoot\19_Share_Path_Review.csv" -NoTypeInformation

# ------------------------------------------------------------
# 11. Generate a readable text summary
# ------------------------------------------------------------

$Summary = @"
FILE SERVER AUDIT
=================
Audit time:       $(Get-Date)
Computer name:    $env:COMPUTERNAME
FQDN:             $($ComputerSystem.DNSHostName).$($ComputerSystem.Domain)
Custom shares:    $($CustomShares.Count)
Local users:      $((Get-LocalUser).Count)
Local groups:     $((Get-LocalGroup).Count)
SMB sessions:     $((Get-SmbSession).Count)
SMB open files:   $((Get-SmbOpenFile).Count)
Audit directory:  $AuditRoot
"@

$Summary | Set-Content "$AuditRoot\00_Audit_Summary.txt"

Write-Host ""
Write-Host "Audit complete." -ForegroundColor Green
Write-Host "Reports saved to: $AuditRoot" -ForegroundColor Yellow
```

# Locate the other ones using the evidence tool
