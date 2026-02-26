# ============================================
# MFA Self-Check Logger (Production)
# ============================================
# Purpose:
# Performs a user-initiated MFA self-verification
# prior to accessing secure Microsoft resources.
# Logs declared user identity, execution context,
# and security awareness checks for audit purposes.
#
# Note:
# This system uses a declared-user model due to
# shared OS accounts. Designed for future RBAC
# on my home cyber-range/POS terminal
# ============================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MFA Self-Check Logger"

$Denied = $false

# ----------------------------
# Identity Check
# ----------------------------
$userCheck = Read-Host "Are you Jason Santiago? [yes/no]"
$declaredUser = Read-Host "Enter your full name (for audit logging)"

if ($userCheck.ToLower() -ne "yes") {
    Write-Host " You are not authorized to run this script." -ForegroundColor Red
    Pause
    exit
}

# ----------------------------
# Timestamp + Environment
# ----------------------------
$timestamp    = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$runTime      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$currentUser  = $env:USERNAME
$computerName = $env:COMPUTERNAME

# ----------------------------
# Log Folder
# ----------------------------
$logFolder = "D:\Batch\MFA_Log"
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

$logFile = Join-Path $logFolder "MFA_Log_$timestamp.txt"

function Write-Log {
    param ([string]$Message)
    Add-Content -Path $logFile -Value $Message
}

# ----------------------------
# Begin Log (Authoritative Header)
# ----------------------------
Write-Log "Security+ MFA Self-Check"
Write-Log "Declared User: $declaredUser"
Write-Log "OS Account: $currentUser"
Write-Log "Computer: $computerName"
Write-Log "Timestamp: $runTime"
Write-Log "Identity Model: Declared user (RBAC pending)"
Write-Log ""

# ----------------------------
# MFA Checks
# ----------------------------
function Ask-YesNo {
    param (
        [string]$Question,
        [string]$LogLabel
    )

    $response = Read-Host $Question
    Write-Log "$LogLabel $response"

    if ($response.ToLower() -ne "yes") {
        return $false
    }
    return $true
}

if (-not (Ask-YesNo "Do you have something you know? (password) [yes/no]" "Something you know:")) { $Denied = $true }
if (-not (Ask-YesNo "Do you have something you have? (phone/token) [yes/no]" "Something you have:")) { $Denied = $true }
if (-not (Ask-YesNo "Do you have something you are? (biometric) [yes/no]" "Something you are:")) { $Denied = $true }
if (-not (Ask-YesNo "Are you in an authorized location (work/VPN)? [yes/no]" "Authorized location:")) { $Denied = $true }

if ($Denied) {
    Write-Log " MFA Self-Check FAILED"
    Write-Host " MFA Self-Check Failed. Portal not launched." -ForegroundColor Red
    Pause
    exit
}

# ----------------------------
# NIST Awareness Check
# ----------------------------
$nist = Read-Host "What NIST standard does MFA authentication practice?"
if ($nist -notmatch "800-53") {
    Write-Host " Incorrect. Correct answer: SP 800-53" -ForegroundColor Red
    Write-Log "NIST Awareness Check FAILED"
    Pause
    exit
}
Write-Log "NIST Standard confirmed: $nist"

# ----------------------------
# Security+ Knowledge Check
# ----------------------------
Write-Host ""
Write-Host "Security+ Knowledge Check" -ForegroundColor Cyan
Write-Host "--------------------------------"
Write-Host "What is the BEST way to secure a multi-user workstation in a public setting?"
Write-Host ""
Write-Host "A. Require users to sign a shared usage policy form and use a common login"
Write-Host "B. Implement individual user accounts with role-based access controls"
Write-Host "C. Enable auto-login and screen lock after inactivity"
Write-Host "D. Create a shared daily password"
Write-Host ""

Write-Log ""
Write-Log "[Security+ Knowledge Check]"
Write-Log "Correct answer: B"

$answer = Read-Host "Your answer [A/B/C/D]"
Write-Log "Answer given: $answer"

if ($answer.ToUpper() -ne "B") {
    Write-Host " Incorrect. Correct answer is B." -ForegroundColor Red
    Write-Log " Knowledge Check FAILED"
    Pause
    exit
}

Write-Host " Correct. Access control principles confirmed." -ForegroundColor Green
Write-Log " Knowledge Check PASSED"

# ----------------------------
# Launch Secure Portal
# ----------------------------
Write-Host "Launching secure Microsoft portal..." -ForegroundColor Green
Start-Process "https://mysignins.microsoft.com/security-info"

Write-Host "Log saved to: $logFile"
Pause
