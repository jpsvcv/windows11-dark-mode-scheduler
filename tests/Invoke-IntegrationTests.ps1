[CmdletBinding()]
param(
    [double]$Latitude = 14.9330,

    [double]$Longitude = -23.5133,

    [string]$LocationName = "Praia, Cabo Verde",

    [string]$TimeZoneId = "Cape Verde Standard Time"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$installScript = Join-Path $projectRoot "scripts\install.ps1"
$uninstallScript = Join-Path $projectRoot "scripts\uninstall.ps1"
$modulePath = Join-Path $projectRoot "src\Win11DarkMode.psm1"
Import-Module $modulePath -Force

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Write-TestStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ("[test] {0}" -f $Message)
}

$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$previousAppsTheme = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
$previousSystemTheme = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme" -ErrorAction SilentlyContinue
$taskPrefix = "Win11DarkModeTest_{0}" -f ([guid]::NewGuid().ToString("N").Substring(0, 8))
$installRoot = Join-Path $env:TEMP $taskPrefix
$vscodeSettingsPath = Join-Path $installRoot "settings.json"

try {
    Write-TestStep "Preparing isolated test files"
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    Set-Content -Path $vscodeSettingsPath -Encoding UTF8 -Value "{`n  `"window.zoomLevel`": 0`n}"

    Write-TestStep "Running requirement check"
    $requirementResult = & $installScript -Action Requirements -Language en-EN -Latitude $Latitude -Longitude $Longitude -LocationName $LocationName -TimeZoneId $TimeZoneId -PassThru
    Assert-Condition -Condition ($null -ne $requirementResult) -Message "The requirement check did not return a result."
    Assert-Condition -Condition (@($requirementResult.Statuses | Where-Object { -not $_.IsMet -and $_.IsCritical }).Count -eq 0) -Message "Critical requirements are missing in this environment."

    Write-TestStep "Running a WhatIf install"
    & $installScript -Action Install -Language en-EN -Latitude $Latitude -Longitude $Longitude -LocationName $LocationName -TimeZoneId $TimeZoneId -TaskPrefix $taskPrefix -InstallRoot $installRoot -VSCodeSettingsPath $vscodeSettingsPath -WhatIf | Out-Null

    Write-TestStep "Running a real install"
    $installResult = & $installScript -Action Install -Language en-EN -Latitude $Latitude -Longitude $Longitude -LocationName $LocationName -TimeZoneId $TimeZoneId -TaskPrefix $taskPrefix -InstallRoot $installRoot -VSCodeSettingsPath $vscodeSettingsPath -PassThru
    Assert-Condition -Condition ($null -ne $installResult) -Message "The install step did not return a result."

    $configPath = Join-Path $installRoot "config.json"
    $runtimeDirectory = Join-Path $installRoot "runtime"
    $logPath = Join-Path $installRoot "theme-switch.log"
    $taskNames = Get-ThemeSwitchTaskNames -TaskPrefix $taskPrefix

    Write-TestStep "Validating installed files"
    Assert-Condition -Condition (Test-Path -LiteralPath $configPath) -Message "config.json was not created."
    Assert-Condition -Condition (Test-Path -LiteralPath $runtimeDirectory) -Message "The runtime directory was not created."
    Assert-Condition -Condition (Test-Path -LiteralPath (Join-Path $runtimeDirectory "Invoke-Win11ThemeMode.ps1")) -Message "Invoke-Win11ThemeMode.ps1 was not copied to the runtime directory."
    Assert-Condition -Condition (Test-Path -LiteralPath (Join-Path $runtimeDirectory "Refresh-ThemeSchedule.ps1")) -Message "Refresh-ThemeSchedule.ps1 was not copied to the runtime directory."

    Write-TestStep "Validating scheduled tasks"
    foreach ($taskName in @($taskNames.Refresh, $taskNames.Dark, $taskNames.Light)) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        Assert-Condition -Condition ($null -ne $task) -Message ("Scheduled task was not created: {0}" -f $taskName)
    }

    Write-TestStep "Refreshing the schedule from the installed runtime"
    & (Join-Path $runtimeDirectory "Refresh-ThemeSchedule.ps1") -ConfigPath $configPath
    Assert-Condition -Condition (Test-Path -LiteralPath $logPath) -Message "The log file was not created after the refresh run."

    Write-TestStep "Applying dark mode"
    & (Join-Path $runtimeDirectory "Invoke-Win11ThemeMode.ps1") -ConfigPath $configPath -Mode Dark
    $appsThemeAfterDark = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
    $systemThemeAfterDark = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme"
    Assert-Condition -Condition ($appsThemeAfterDark -eq 0 -and $systemThemeAfterDark -eq 0) -Message "The Windows theme was not switched to dark mode."

    Write-TestStep "Applying light mode"
    & (Join-Path $runtimeDirectory "Invoke-Win11ThemeMode.ps1") -ConfigPath $configPath -Mode Light
    $appsThemeAfterLight = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme"
    $systemThemeAfterLight = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme"
    Assert-Condition -Condition ($appsThemeAfterLight -eq 1 -and $systemThemeAfterLight -eq 1) -Message "The Windows theme was not switched back to light mode."

    Write-TestStep "Validating VS Code settings"
    $settingsText = Get-Content -Path $vscodeSettingsPath -Raw
    Assert-Condition -Condition ($settingsText -match '"window\.autoDetectColorScheme"\s*:\s*true') -Message "VS Code auto-detection was not enabled."
    Assert-Condition -Condition ($settingsText -match '"workbench\.preferredLightColorTheme"\s*:\s*"Quit Lite"') -Message "The configured VS Code light theme was not written."
    Assert-Condition -Condition ($settingsText -match '"workbench\.preferredDarkColorTheme"\s*:\s*"VS Code Dark"') -Message "The configured VS Code dark theme was not written."

    Write-TestStep "Running uninstall"
    & $uninstallScript -TaskPrefix $taskPrefix -InstallRoot $installRoot
    Assert-Condition -Condition (-not (Test-Path -LiteralPath $installRoot)) -Message "The install root still exists after uninstall."

    foreach ($taskName in @($taskNames.Refresh, $taskNames.Dark, $taskNames.Light)) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        Assert-Condition -Condition ($null -eq $task) -Message ("Scheduled task still exists after uninstall: {0}" -f $taskName)
    }

    Write-Host ""
    Write-Host "Integration tests completed successfully."
}
finally {
    try {
        & $uninstallScript -TaskPrefix $taskPrefix -InstallRoot $installRoot -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
    }

    if ($null -ne $previousAppsTheme) {
        Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value $previousAppsTheme -Type DWord
    }

    if ($null -ne $previousSystemTheme) {
        Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value $previousSystemTheme -Type DWord
    }
}
