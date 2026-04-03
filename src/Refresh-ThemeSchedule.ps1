[CmdletBinding()]
param(
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) "config.json"
}

$modulePath = Join-Path $PSScriptRoot "Win11DarkMode.psm1"
Import-Module $modulePath -Force

try {
    # Refresh the one-shot jobs so they always track the next sunrise and dark event.
    $config = Read-ThemeSwitchConfig -Path $ConfigPath
    $transitions = Update-ThemeEventTasks -ConfigPath $ConfigPath -RuntimeDirectory $PSScriptRoot -TaskPrefix $config.TaskPrefix
    Invoke-ThemeSwitch -ConfigPath $ConfigPath | Out-Null

    $logPath = if ([string]::IsNullOrWhiteSpace($config.LogPath)) {
        Join-Path (Split-Path -Path $ConfigPath -Parent) "theme-switch.log"
    }
    else {
        $config.LogPath
    }

    Write-ThemeSwitchLog -LogPath $logPath -Message (
        "Next scheduled events: dark at {0}, light at {1}." -f
        $transitions.NextDarkEventLocal.ToString("yyyy-MM-dd HH:mm:ss"),
        $transitions.NextLightEventLocal.ToString("yyyy-MM-dd HH:mm:ss")
    )
}
catch {
    $fallbackLogPath = Join-Path (Split-Path -Path $ConfigPath -Parent) "theme-switch.log"
    try {
        Write-ThemeSwitchLog -LogPath $fallbackLogPath -Message ("ERROR while refreshing the schedule: {0}" -f $_.Exception.Message)
    }
    catch {
    }

    throw
}
