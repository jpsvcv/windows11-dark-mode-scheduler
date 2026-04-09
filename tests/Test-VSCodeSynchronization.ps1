#Requires -Version 5.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "Win11ThemeTest_$([guid]::NewGuid().ToString('n').Substring(0, 8))"
$null = New-Item -Path $testRoot -ItemType Directory -Force

try {
    Write-Host "[TEST] VS Code Theme Synchronization Tests" -ForegroundColor Yellow
    Write-Host ""

    # Test parameters
    $Latitude = 16.86
    $Longitude = -25.64
    $LocationName = "Praia, Cabo Verde"
    $TimeZoneId = "Cape Verde Standard Time"
    $vscodeSettingsPath = Join-Path $testRoot "vscode_settings.json"
    $installRoot = Join-Path $testRoot "install"
    $taskPrefix = "ThemeSwitch_Test_$([guid]::NewGuid().ToString('n').Substring(0, 8))"

    # Initialize empty VS Code settings file
    $null = New-Item -Path (Split-Path -Path $vscodeSettingsPath -Parent) -ItemType Directory -Force
    Set-Content -Path $vscodeSettingsPath -Encoding UTF8 -Value "{`n  `"window.zoomLevel`": 0`n}"

    Write-Host "[TEST] Installing theme scheduler with VS Code integration..."
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

    Write-Host "[TEST] PASS: Installation completed" -ForegroundColor Green
    Write-Host ""

    # ===== TEST 1: Verify initial VS Code settings
    Write-Host "[TEST] Test 1: Verifying VS Code settings after installation" -ForegroundColor Cyan
    $settings = Get-Content -Path $vscodeSettingsPath -Raw
    
    $hasAutoDetect = $settings -match '"window\.autoDetectColorScheme"\s*:\s*true'
    $hasLightTheme = $settings -match '"workbench\.preferredLightColorTheme"\s*:\s*"Quit Lite"'
    $hasDarkTheme = $settings -match '"workbench\.preferredDarkColorTheme"\s*:\s*"VS Code Dark"'
    $hasNoExplicitColorTheme = -not ($settings -match '"workbench\.colorTheme"\s*:')

    if ($hasAutoDetect -and $hasLightTheme -and $hasDarkTheme -and $hasNoExplicitColorTheme) {
        Write-Host "[TEST] PASS: VS Code settings configured correctly:" -ForegroundColor Green
        Write-Host "       - window.autoDetectColorScheme = true"
        Write-Host "       - workbench.preferredLightColorTheme = 'Quit Lite'"
        Write-Host "       - workbench.preferredDarkColorTheme = 'VS Code Dark'"
        Write-Host "       - workbench.colorTheme NOT set (good! avoids conflicts)"
    }
    else {
        Write-Host "[TEST] FAIL: VS Code settings verification failed!" -ForegroundColor Red
        Write-Host "       hasAutoDetect=$hasAutoDetect"
        Write-Host "       hasLightTheme=$hasLightTheme"
        Write-Host "       hasDarkTheme=$hasDarkTheme"
        Write-Host "       hasNoExplicitColorTheme=$hasNoExplicitColorTheme"
        throw "VS Code settings not configured correctly"
    }
    Write-Host ""

    # ===== TEST 2: Apply Dark theme and verify
    Write-Host "[TEST] Test 2: Applying DARK theme" -ForegroundColor Cyan
    $invokeScript = Resolve-Path -Path "$PSScriptRoot\..\src\Invoke-Win11ThemeMode.ps1"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode Dark 2>&1 | Out-Null
    
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $appsLight = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
    $systemLight = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme"
    
    if ($appsLight -eq 0 -and $systemLight -eq 0) {
        Write-Host "[TEST] PASS: Dark theme applied to Windows (AppsUseLightTheme=0, SystemUsesLightTheme=0)" -ForegroundColor Green
    } else {
        throw "Dark theme not applied correctly to Windows"
    }
    Write-Host ""

    # ===== TEST 3: Apply Light theme and verify
    Write-Host "[TEST] Test 3: Applying LIGHT theme" -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode Light 2>&1 | Out-Null
    
    $appsLight = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
    $systemLight = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme"
    
    if ($appsLight -eq 1 -and $systemLight -eq 1) {
        Write-Host "[TEST] PASS: Light theme applied to Windows (AppsUseLightTheme=1, SystemUsesLightTheme=1)" -ForegroundColor Green
    } else {
        throw "Light theme not applied correctly to Windows"
    }
    Write-Host ""

    # ===== TEST 4: Verify VS Code settings remain stable
    Write-Host "[TEST] Test 4: Verifying VS Code settings remain stable after theme switches" -ForegroundColor Cyan
    $settings = Get-Content -Path $vscodeSettingsPath -Raw
    
    $hasAutoDetect = $settings -match '"window\.autoDetectColorScheme"\s*:\s*true'
    $hasLightTheme = $settings -match '"workbench\.preferredLightColorTheme"\s*:\s*"Quit Lite"'
    $hasDarkTheme = $settings -match '"workbench\.preferredDarkColorTheme"\s*:\s*"VS Code Dark"'
    $hasNoExplicitColorTheme = -not ($settings -match '"workbench\.colorTheme"')
    
    if ($hasAutoDetect -and $hasLightTheme -and $hasDarkTheme -and $hasNoExplicitColorTheme) {
        Write-Host "[TEST] PASS: VS Code settings remain stable and correct" -ForegroundColor Green
    } else {
        throw "VS Code settings were modified or corrupted"
    }
    Write-Host ""

    # ===== TEST 5: Rapid switching test
    Write-Host "[TEST] Test 5: Rapid theme switching (Dark->Light->Dark->Light)" -ForegroundColor Cyan
    $modes = @("Dark", "Light", "Dark", "Light")
    foreach ($mode in $modes) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode $mode 2>&1 | Out-Null
        $appsLight = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
        $expectedValue = if ($mode -eq "Dark") { 0 } else { 1 }
        if ($appsLight -ne $expectedValue) {
            throw "Theme $mode failed to apply correctly"
        }
    }
    Write-Host "[TEST] PASS: Rapid switching completed successfully" -ForegroundColor Green
    Write-Host ""

    # ===== Cleanup
    Write-Host "[TEST] Uninstalling theme scheduler..."
    $uninstallScript = Resolve-Path -Path "$PSScriptRoot\..\scripts\uninstall.ps1"
    & $uninstallScript -InstallRoot $installRoot -TaskPrefix $taskPrefix 2>&1 | Out-Null
    Write-Host "[TEST] PASS: Uninstallation completed" -ForegroundColor Green
    Write-Host ""

    # Restore Windows theme
    Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value 1 -Type DWord
    Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value 1 -Type DWord

    Write-Host "[SUCCESS] All VS Code synchronization tests passed!" -ForegroundColor Yellow
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
