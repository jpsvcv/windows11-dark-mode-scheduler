#Requires -Version 5.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"

# Test parameters
$Latitude = 16.86
$Longitude = -25.64
$LocationName = "Praia, Cabo Verde"
$TimeZoneId = "Cape Verde Standard Time"

# Create temp test directory
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "Win11DarkModeVSCodeTests_$([guid]::NewGuid().ToString('n').Substring(0, 8))"
$null = New-Item -Path $testRoot -ItemType Directory -Force

function Write-TestStep {
    param([string]$Message)
    Write-Host -ForegroundColor Cyan "[test] $Message"
}

function Write-TestSuccess {
    param([string]$Message)
    Write-Host -ForegroundColor Green "✓ $Message"
}

function Write-TestError {
    param([string]$Message)
    Write-Host -ForegroundColor Red "✗ $Message"
}

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-VSCodeSettings {
    param([string]$SettingsPath)

    if (-not (Test-Path -LiteralPath $SettingsPath)) {
        return $null
    }

    $content = Get-Content -LiteralPath $SettingsPath -Raw
    return $content
}

function Test-VSCodeThemeSynchronization {
    Write-TestStep "Beginning comprehensive VS Code theme synchronization tests"

    try {
        # Paths
        $installRoot = Join-Path $testRoot "install"
        $runtimeDir = Join-Path $installRoot "runtime"
        $vscodeSettingsPath = Join-Path $testRoot "vscode_settings.json"
        $installScript = Resolve-Path -Path "$PSScriptRoot\..\scripts\install.ps1"
        $taskPrefix = "ThemeSwitch_VSCodeTest_$([guid]::NewGuid().ToString('n').Substring(0, 8))"
        
        # Initialize empty VS Code settings
        New-Item -Path (Split-Path -Path $vscodeSettingsPath -Parent) -ItemType Directory -Force | Out-Null
        Set-Content -Path $vscodeSettingsPath -Encoding UTF8 -Value "{`n  `"window.zoomLevel`": 0`n}"

        # Install the theme scheduler
        Write-TestStep "Installing theme scheduler with VS Code integration"
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
        Write-TestSuccess "Installation completed"

        # Verify initial VS Code settings
        Write-TestStep "Verifying initial VS Code settings"
        $settings = Get-VSCodeSettings -SettingsPath $vscodeSettingsPath
        Assert-Condition -Condition ($settings -match '"window\.autoDetectColorScheme"\s*:\s*true') -Message "Auto-detect not enabled"
        Assert-Condition -Condition ($settings -match '"workbench\.preferredLightColorTheme"\s*:\s*"Quit Lite"') -Message "Light theme not set"
        Assert-Condition -Condition ($settings -match '"workbench\.preferredDarkColorTheme"\s*:\s*"VS Code Dark"') -Message "Dark theme not set"
        Assert-Condition -Condition -not ($settings -match '"workbench\.colorTheme"') -Message "workbench.colorTheme should not be set (conflicts with auto-detect)"
        Write-TestSuccess "Initial VS Code settings verified - auto-detect enabled, themes configured, no explicit colorTheme"

        # Test 1: Apply Dark theme and verify
        Write-TestStep "Test 1: Applying DARK theme via Invoke-Win11ThemeMode"
        $invokeScript = Join-Path $runtimeDir "Invoke-Win11ThemeMode.ps1"
        & powershell -NoProfile -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode Dark | Out-Null
        
        # Get Windows theme state
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $appsLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
        $systemLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme"
        
        Assert-Condition -Condition ($appsLightTheme -eq 0) -Message "Windows apps theme not set to Dark"
        Assert-Condition -Condition ($systemLightTheme -eq 0) -Message "Windows system theme not set to Dark"
        Write-TestSuccess "Dark mode applied - Windows registry confirms AppsUseLightTheme=0, SystemUsesLightTheme=0"

        # Verify VS Code settings reflect dark mode choices
        $settings = Get-VSCodeSettings -SettingsPath $vscodeSettingsPath
        Assert-Condition -Condition ($settings -match '"workbench\.preferredDarkColorTheme"\s*:\s*"VS Code Dark"') -Message "Dark theme preference missing"
        Assert-Condition -Condition -not ($settings -match '"window\.autoDetectColorScheme"\s*:\s*false') -Message "Auto-detect was disabled"
        Write-TestSuccess "Dark mode: VS Code settings still have auto-detect enabled and dark theme configured"

        # Test 2: Apply Light theme and verify
        Write-TestStep "Test 2: Applying LIGHT theme via Invoke-Win11ThemeMode"
        & powershell -NoProfile -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode Light | Out-Null
        
        $appsLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
        $systemLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme"
        
        Assert-Condition -Condition ($appsLightTheme -eq 1) -Message "Windows apps theme not set to Light"
        Assert-Condition -Condition ($systemLightTheme -eq 1) -Message "Windows system theme not set to Light"
        Write-TestSuccess "Light mode applied - Windows registry confirms AppsUseLightTheme=1, SystemUsesLightTheme=1"

        # Verify VS Code settings reflect light mode choices
        $settings = Get-VSCodeSettings -SettingsPath $vscodeSettingsPath
        Assert-Condition -Condition ($settings -match '"workbench\.preferredLightColorTheme"\s*:\s*"Quit Lite"') -Message "Light theme preference missing"
        Assert-Condition -Condition ($settings -match '"window\.autoDetectColorScheme"\s*:\s*true') -Message "Auto-detect was disabled"
        Write-TestSuccess "Light mode: VS Code settings still have auto-detect enabled and light theme configured"

        # Test 3: Rapid theme switching (stress test)
        Write-TestStep "Test 3: Rapid theme switching (stress test) - Dark->Light->Dark->Light"
        @("Dark", "Light", "Dark", "Light") | ForEach-Object {
            & powershell -NoProfile -File $invokeScript -ConfigPath "$installRoot\config.json" -Mode $_ | Out-Null
            
            $appsLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
            $expectedValue = if ($_ -eq "Dark") { 0 } else { 1 }
            
            if ($appsLightTheme -ne $expectedValue) {
                throw "Theme $_  failed to apply correctly"
            }
        }
        Write-TestSuccess "Rapid switching test passed - all transitions completed successfully"

        # Test 4: Verify auto-detect remains enabled throughout
        Write-TestStep "Test 4: Verifying auto-detect consistency"
        $settings = Get-VSCodeSettings -SettingsPath $vscodeSettingsPath
        Assert-Condition -Condition ($settings -match '"window\.autoDetectColorScheme"\s*:\s*true') -Message "Auto-detect was disabled during tests"
        Assert-Condition -Condition -not ($settings -match '"workbench\.colorTheme"\s*:\s*"(?!Quit Lite|VS Code Dark)"') -Message "workbench.colorTheme was set to an unexpected value"
        Write-TestSuccess "Auto-detect consistency verified - no conflicts detected"

        # Test 5: Verify VS Code theme preferences haven't changed
        Write-TestStep "Test 5: Verifying theme preferences remain stable"
        $settings = Get-VSCodeSettings -SettingsPath $vscodeSettingsPath
        Assert-Condition -Condition ($settings -match '"workbench\.preferredLightColorTheme"\s*:\s*"Quit Lite"') -Message "Light theme preference changed"
        Assert-Condition -Condition ($settings -match '"workbench\.preferredDarkColorTheme"\s*:\s*"VS Code Dark"') -Message "Dark theme preference changed"
        Write-TestSuccess "Theme preferences stable - configurations persist correctly"

        Write-TestStep "Uninstalling theme scheduler"
        $uninstallScript = Resolve-Path -Path "$PSScriptRoot\..\scripts\uninstall.ps1"
        & $uninstallScript -InstallRoot $installRoot -TaskPrefix $taskPrefix -Force | Out-Null
        Write-TestSuccess "Uninstallation completed"

        # Restore Windows theme
        Write-TestStep "Restoring Windows theme to original state"
        Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value 1 -Type DWord
        Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value 1 -Type DWord
        Write-TestSuccess "Windows theme restored to Light"

        Write-Host -ForegroundColor Green "`n✓ All VS Code sync tests passed successfully!`n"
        return 0
    }
    catch {
        Write-Host -ForegroundColor Red "`n✗ Test failed: $_`n"
        return 1
    }
    finally {
        # Cleanup
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

exit (Test-VSCodeThemeSynchronization)
