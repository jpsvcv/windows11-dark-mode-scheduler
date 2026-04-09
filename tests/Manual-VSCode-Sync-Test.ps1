#Requires -Version 5.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ VS Code Theme Sync - Manual Testing Guide                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "PREREQUISITES:" -ForegroundColor Yellow
Write-Host "  1. VS Code must be OPEN with a workspace loaded"
Write-Host "  2. Build a second VS Code window that is visible for observation"
Write-Host ""

Write-Host "TEST PROCEDURE:" -ForegroundColor Green
Write-Host ""
Write-Host "Step 1: Set VS Code theme to LIGHT" -ForegroundColor White
Write-Host "  Action: In VS Code, run Command Palette (Ctrl+Shift+P)"
Write-Host "          Type: 'Preferences: Color Theme'"
Write-Host "          Select: 'Quit Lite' or any light theme"
Write-Host ""

Write-Host "Step 2: Verify Windows is set to LIGHT mode" -ForegroundColor White
Write-Host "  Action: Settings > Personalization > Colors"
Write-Host "          Set to 'Light' mode"
Write-Host ""

Write-Host "Step 3: Run theme switch to DARK" -ForegroundColor White
Write-Host "  This will:"
Write-Host "    - Set Windows to dark mode"
Write-Host "    - Update VS Code settings.json"
Write-Host "    - Send reload command to all running VS Code instances"
Write-Host ""

# Get the config path
$installRoot = Join-Path $env:LOCALAPPDATA "Win11DarkMode"
if (-not (Test-Path $installRoot)) {
    Write-Host "ERROR: Win11DarkMode not installed at $installRoot" -ForegroundColor Red
    Write-Host "Run the installer first." -ForegroundColor Red
    exit 1
}

$configPath = Join-Path $installRoot "config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: Configuration not found at $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "Ready to test. Press Enter to switch to DARK theme..." -ForegroundColor Yellow
Read-Host

Write-Host ""
Write-Host "APPLYING DARK THEME..." -ForegroundColor Cyan

$invokeScript = Join-Path $installRoot "runtime" "Invoke-Win11ThemeMode.ps1"
if (-not (Test-Path $invokeScript)) {
    Write-Host "ERROR: Runtime script not found" -ForegroundColor Red
    exit 1
}

$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $invokeScript -ConfigPath $configPath -Mode Dark

Write-Host $output

Write-Host ""
Write-Host "OBSERVATION:" -ForegroundColor Yellow
Write-Host "  Watch the VS Code window(s) for theme changes:"
Write-Host "  - Did the theme change from light to dark? (GOOD!)"
Write-Host "  - Did the theme remain light? (BAD - needs manual reload)"
Write-Host ""

Write-Host "Step 4: If theme didn't change automatically:" -ForegroundColor White
Write-Host "  Solution A: Reload Window (Ctrl+Shift+P > Reload Window)"
Write-Host "  Solution B: Restart VS Code"
Write-Host ""

Read-Host "Press Enter to continue with LIGHT theme test"

Write-Host ""
Write-Host "APPLYING LIGHT THEME..." -ForegroundColor Cyan

$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $invokeScript -ConfigPath $configPath -Mode Light

Write-Host $output

Write-Host ""
Write-Host "FINAL OBSERVATION:" -ForegroundColor Yellow
Write-Host "  Did the theme switch back to light? (GOOD!)"
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ Test Complete                                                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host "TROUBLESHOOTING:" -ForegroundColor Magenta
Write-Host "  If themes don't sync automatically:"
Write-Host "  1. Verify VS Code version (1.60+) supports --command flag"
Write-Host "  2. Check settings.json was actually updated"
Write-Host "  3. Try manual reload: Ctrl+Shift+P > 'Reload Window'"
Write-Host "  4. Check theme names match exactly in configuration"
Write-Host ""
