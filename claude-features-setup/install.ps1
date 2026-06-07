# Claude Code Features Setup Script
# Compatible with Windows 10/11
# This script installs: StatusLine + Smart Notification

$ErrorActionPreference = "Continue"
$claudeDir = "$env:USERPROFILE\.claude"
$scriptDir = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Code Features Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================
# Step 0: Environment Check
# ============================================
Write-Host "`n[Step 0] Checking environment..." -ForegroundColor Yellow

# Check Python
$pythonExists = $null -ne (Get-Command python -ErrorAction SilentlyContinue)
if ($pythonExists) {
    $pythonVersion = python --version 2>&1
    Write-Host "  Python: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  Python: NOT FOUND" -ForegroundColor Red
    Write-Host "  StatusLine feature requires Python. Install from: https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "  Continuing with notification setup only..." -ForegroundColor Yellow
}

# Check Bash (Git for Windows)
$bashExists = $null -ne (Get-Command bash -ErrorAction SilentlyContinue)
if ($bashExists) {
    Write-Host "  Bash: Available" -ForegroundColor Green
} else {
    Write-Host "  Bash: NOT FOUND" -ForegroundColor Red
    Write-Host "  Hooks require Git for Windows (provides bash). Install from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "  Continuing with notification setup only..." -ForegroundColor Yellow
}

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion.Major
Write-Host "  PowerShell: $psVersion" -ForegroundColor Green

# ============================================
# Step 1: Install BurntToast module
# ============================================
Write-Host "`n[Step 1] Installing BurntToast module..." -ForegroundColor Yellow

try {
    # Check if NuGet provider is available
    $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    if (-not $nuget) {
        Write-Host "  Installing NuGet provider..." -ForegroundColor Cyan
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
    }

    # Install BurntToast
    Import-Module BurntToast -ErrorAction Stop
    Write-Host "  BurntToast: Already installed" -ForegroundColor Green
} catch {
    Write-Host "  Installing BurntToast..." -ForegroundColor Cyan
    try {
        Install-Module -Name BurntToast -Force -Scope CurrentUser -AllowClobber
        Import-Module BurntToast -ErrorAction Stop
        Write-Host "  BurntToast: Installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  BurntToast: Installation failed, will use beep fallback" -ForegroundColor Yellow
    }
}

# ============================================
# Step 2: Copy notify.ps1
# ============================================
Write-Host "`n[Step 2] Installing notify.ps1..." -ForegroundColor Yellow

try {
    Copy-Item "$scriptDir\notify.ps1" "$claudeDir\notify.ps1" -Force
    Write-Host "  notify.ps1: Installed" -ForegroundColor Green
} catch {
    Write-Host "  notify.ps1: Failed - $_" -ForegroundColor Red
}

# ============================================
# Step 3: Copy statusline.sh (if Python available)
# ============================================
Write-Host "`n[Step 3] Installing statusline.sh..." -ForegroundColor Yellow

if ($pythonExists) {
    try {
        Copy-Item "$scriptDir\statusline.sh" "$claudeDir\statusline.sh" -Force
        Write-Host "  statusline.sh: Installed" -ForegroundColor Green
    } catch {
        Write-Host "  statusline.sh: Failed - $_" -ForegroundColor Red
    }
} else {
    Write-Host "  statusline.sh: Skipped (Python not available)" -ForegroundColor Yellow
}

# ============================================
# Step 4: Update settings.json
# ============================================
Write-Host "`n[Step 4] Updating settings.json..." -ForegroundColor Yellow

$settingsPath = "$claudeDir\settings.json"

try {
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        Write-Host "  Existing settings.json found, preserving current config" -ForegroundColor Cyan
    } else {
        $settings = @{} | ConvertTo-Json | ConvertFrom-Json
        Write-Host "  Creating new settings.json" -ForegroundColor Cyan
    }

    # Add statusLine (only if Python and Bash available)
    if ($pythonExists -and $bashExists) {
        $statusLineConfig = @{
            type = "command"
            command = "bash ~/.claude/statusline.sh"
            refreshInterval = 5
        }
        $settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue $statusLineConfig -Force
        Write-Host "  Added statusLine config" -ForegroundColor Green
    } else {
        Write-Host "  Skipped statusLine (missing Python or Bash)" -ForegroundColor Yellow
    }

    # Add hooks (only if Bash available)
    if ($bashExists) {
        $hooks = @{
            Stop = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File ~/.claude/notify.ps1 -Title 'Claude Code' -Message 'Task completed, please check'"; timeout = 10 }) })
            PermissionRequest = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File ~/.claude/notify.ps1 -Title 'Claude Code' -Message 'Permission needed, please confirm'"; timeout = 10 }) })
            Elicitation = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File ~/.claude/notify.ps1 -Title 'Claude Code' -Message 'Question needs your answer'"; timeout = 10 }) })
            Notification = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File ~/.claude/notify.ps1 -Title 'Claude Code' -Message 'Needs your attention'"; timeout = 10 }) })
        }
        $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $hooks -Force
        Write-Host "  Added hooks config" -ForegroundColor Green
    } else {
        Write-Host "  Skipped hooks (missing Bash)" -ForegroundColor Yellow
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "  settings.json: Updated" -ForegroundColor Green
} catch {
    Write-Host "  settings.json: Failed - $_" -ForegroundColor Red
}

# ============================================
# Step 5: Verification
# ============================================
Write-Host "`n[Step 5] Verification..." -ForegroundColor Yellow

Write-Host "  Files installed:" -ForegroundColor Cyan
Write-Host "    notify.ps1: $(if(Test-Path "$claudeDir\notify.ps1"){'OK'}else{'MISSING'})"
Write-Host "    statusline.sh: $(if(Test-Path "$claudeDir\statusline.sh"){'OK'}else{'SKIPPED'})"
Write-Host "    settings.json: $(if(Test-Path "$settingsPath"){'OK'}else{'MISSING'})"

# Test notification
Write-Host "`n  Sending test notification..." -ForegroundColor Cyan
try {
    Import-Module BurntToast -ErrorAction Stop
    New-BurntToastNotification -Text "Claude Code", "Setup complete!"
    Write-Host "  Toast notification sent (check notification center)" -ForegroundColor Green
} catch {
    Write-Host "  Using beep fallback..." -ForegroundColor Yellow
    [console]::beep(1000, 200)
    [console]::beep(1200, 200)
    [console]::beep(1500, 400)
}

# ============================================
# Summary
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($pythonExists -and $bashExists) {
    Write-Host "All features installed:" -ForegroundColor Green
    Write-Host "  [OK] StatusLine (directory + model + context bar)"
    Write-Host "  [OK] Notifications (when you are away)"
} elseif ($bashExists) {
    Write-Host "Partial features installed:" -ForegroundColor Yellow
    Write-Host "  [SKIP] StatusLine (requires Python)"
    Write-Host "  [OK] Notifications (when you are away)"
} else {
    Write-Host "Limited features installed:" -ForegroundColor Yellow
    Write-Host "  [SKIP] StatusLine (requires Python + Bash)"
    Write-Host "  [SKIP] Hooks (requires Bash)"
    Write-Host "  [OK] notify.ps1 script ready"
    Write-Host "`n  Install Git for Windows to enable hooks:" -ForegroundColor Cyan
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor White
    if (-not $pythonExists) {
        Write-Host "`n  Install Python to enable StatusLine:" -ForegroundColor Cyan
        Write-Host "  https://www.python.org/downloads/" -ForegroundColor White
    }
}

Write-Host "`nRestart Claude Code to apply changes." -ForegroundColor Green
