#Requires -Version 5.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "[DEBUG] Testing VS Code --command support..." -ForegroundColor Cyan

# Check if VS Code is installed
$codeCmd = Get-Command code -ErrorAction SilentlyContinue

if (-not $codeCmd) {
    Write-Host "VS Code not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "[DEBUG] VS Code found at: $($codeCmd.Source)" -ForegroundColor Green

# Test 1: Check VS Code version
Write-Host "[DEBUG] Checking VS Code version..." -ForegroundColor Cyan
$versionOutput = & code --version 2>&1 | Select-Object -First 1
Write-Host "[DEBUG] Version: $versionOutput" -ForegroundColor Green

# Test 2: Try listing extensions (should work in all versions)
Write-Host "[DEBUG] Testing --list-extensions command..." -ForegroundColor Cyan
try {
    $extOutput = & code --list-extensions 2>&1
    Write-Host "[DEBUG] Extension listing works" -ForegroundColor Green
}
catch {
    Write-Host "[DEBUG] Extension listing failed: $_" -ForegroundColor Yellow
}

# Test 3: Try the reload command (only works in VS Code 1.60+)
Write-Host "[DEBUG] Testing --command support for reload..." -ForegroundColor Cyan
try {
    # This command should not output anything if it works
    $result = & code --command workbench.action.reloadWindow 2>&1
    if ($result) {
        Write-Host "[DEBUG] Command output: $result" -ForegroundColor Yellow
    }
    else {
        Write-Host "[DEBUG] Reload command executed (no output - success!)" -ForegroundColor Green
    }
}
catch {
    Write-Host "[DEBUG] Reload command failed: $_" -ForegroundColor Red
}

# Test 4: Try alternate command format
Write-Host "[DEBUG] Testing --command with quoted argument..." -ForegroundColor Cyan
try {
    $cmd = "code --command `"workbench.action.reloadWindow`""
    Write-Host "[DEBUG] Running: $cmd"
    Invoke-Expression $cmd 2>&1 | Out-Null
    Write-Host "[DEBUG] Command executed" -ForegroundColor Green
}
catch {
    Write-Host "[DEBUG] Command failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "SUMMARY:" -ForegroundColor Yellow
Write-Host "- If you see reload command errors above, the --command flag may not be supported"
Write-Host "- VS Code versions 1.60+ should support --command"
Write-Host "- For older versions, manual reload (Ctrl+Shift+P > Reload Window) is needed"
