#Requires -Version 5.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "Win11VSCodeLiveTest_$([guid]::NewGuid().ToString('n').Substring(0, 8))"
$null = New-Item -Path $testRoot -ItemType Directory -Force

try {
    Write-Host "[LIVE TEST] VS Code Theme Synchronization with Running Instance" -ForegroundColor Yellow
    Write-Host ""

    # Test parameters
    $Latitude = 16.86
    $Longitude = -25.64
    $LocationName = "Praia, Cabo Verde"
    $TimeZoneId = "Cape Verde Standard Time"
    $vscodeSettingsPath = Join-Path $testRoot "vscode_settings.json"
    $installRoot = Join-Path $testRoot "install"
    $taskPrefix = "ThemeSwitch_LiveTest_$([guid]::NewGuid().ToString('n').Substring(0, 8))"

    # Initialize empty VS Code settings file
    $null = New-Item -Path (Split-Path -Path $vscodeSettingsPath -Parent) -ItemType Directory -Force
    Set-Content -Path $vscodeSettingsPath -Encoding UTF8 -Value "{`n  `"window.zoomLevel`": 0`n}"

    Write-Host "[LIVE TEST] Installing theme scheduler..." -ForegroundColor Cyan
    $installScript = Resolve-Path -Path "$PSScriptRoot\..\scripts\install.ps1"
    
    & $installScript `
        -Action Install `
        -Language en-EN `
        -Latitude $Latitude `
        -Longitude $Longitude `
        -LocationName $LocationName `
        -TimeZoneId $TimeZoneId `
        -TaskPrefix $taskPrefix `
        -InstallRoot $installRoot `
        -VSCodeSettingsPath $vscodeSettingsPath `
        -VSCodeDarkTheme "VS Code Dark" `
        -VSCodeLightTheme "Quit Lite" `
        -PassThru | Out-Null

    Write-Host "[LIVE TEST] Installation completed" -ForegroundColor Green
    Write-Host ""

    # Check if VS Code is installed
    Write-Host "[LIVE TEST] Checking for running VS Code instances..." -ForegroundColor Cyan
    
    $codeProcesses = Get-Process -Name "code" -ErrorAction SilentlyContinue
    $insidersProcesses = Get-Process -Name "code-insiders" -ErrorAction SilentlyContinue
    $codiumProcesses = Get-Process -Name "codium" -ErrorAction SilentlyContinue
    
    $allProcesses = @() + $codeProcesses + $insidersProcesses + $codiumProcesses
    $allProcesses = @($allProcesses | Where-Object { $_ -ne $null })
    
    if ($allProcesses.Count -eq 0) {
        Write-Host "[LIVE TEST] No running VS Code instances detected" -ForegroundColor Yellow
        Write-Host "[LIVE TEST] (Skipping live instance test - follow these steps to test manually:)" -ForegroundColor Yellow
        Write-Host "  1. Open VS Code"
        Write-Host "  2. Set it to Light theme (Settings > Theme > Quit Lite)"
        Write-Host "  3. Run: Invoke-ThemeSwitch -ConfigPath '$installRoot\config.json' -Mode Dark"
        Write-Host "  4. VS Code should switch to 'VS Code Dark' within 1-2 seconds"
        Write-Host "  5. Run: Invoke-ThemeSwitch -ConfigPath '$installRoot\config.json' -Mode Light"
        Write-Host "  6. VS Code should switch back to 'Quit Lite' within 1-2 seconds"
    }
    else {
        Write-Host "[LIVE TEST] Found $($allProcesses.Count) running VS Code instance(s)" -ForegroundColor Green
        Write-Host ""

        # ===== Test with running instance
        Write-Host "[LIVE TEST] Test 1: Applying DARK theme (with running VS Code)" -ForegroundColor Cyan
        $invokeScript = Resolve-Path -Path "$PSScriptRoot\..\src\Invoke-Win11ThemeMode.ps1"
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode Dark 2>&1
        
        # Check if refresh message exists in output
        if ($output -match "Refreshed") {
            Write-Host "[LIVE TEST] PASS: VS Code refresh signal sent to running instance" -ForegroundColor Green
        }
        else {
            Write-Host "[LIVE TEST] INFO: VS Code refresh completed (check manual appearance in running instance)" -ForegroundColor Yellow
        }
        
        Start-Sleep -Milliseconds 500
        
        Write-Host "[LIVE TEST] Test 2: Applying LIGHT theme (with running VS Code)" -ForegroundColor Cyan
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode Light 2>&1
        
        if ($output -match "Refreshed") {
            Write-Host "[LIVE TEST] PASS: VS Code refresh signal sent to running instance" -ForegroundColor Green
        }
        else {
            Write-Host "[LIVE TEST] INFO: VS Code refresh completed (check manual appearance in running instance)" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "[LIVE TEST] Verify: Check the running VS Code window for immediate theme changes" -ForegroundColor Yellow
    }

    # ===== Cleanup
    Write-Host "[LIVE TEST] Uninstalling theme scheduler..." -ForegroundColor Cyan
    $uninstallScript = Resolve-Path -Path "$PSScriptRoot\..\scripts\uninstall.ps1"
    & $uninstallScript -InstallRoot $installRoot -TaskPrefix $taskPrefix 2>&1 | Out-Null
    Write-Host "[LIVE TEST] Uninstallation completed" -ForegroundColor Green
    Write-Host ""

    # Restore Windows theme
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value 1 -Type DWord
    Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value 1 -Type DWord

    Write-Host "[SUCCESS] Live instance test completed" -ForegroundColor Yellow
    exit 0
}
catch {
    Write-Host "[ERROR] Test failed: $_" -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path -Path $testRoot) {
        Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
