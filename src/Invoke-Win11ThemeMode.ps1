[CmdletBinding()]
param(
    [string]$ConfigPath,

    [ValidateSet("Dark", "Light")]
    [string]$Mode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) "config.json"
}

$modulePath = Join-Path $PSScriptRoot "Win11DarkMode.psm1"
Import-Module $modulePath -Force

try {
    # When no explicit mode is provided, the module derives it from the schedule.
    $invokeParameters = @{
        ConfigPath = $ConfigPath
    }

    if (-not [string]::IsNullOrWhiteSpace($Mode)) {
        $invokeParameters["Mode"] = $Mode
    }

    Invoke-ThemeSwitch @invokeParameters | Out-Null
}
catch {
    $fallbackLogPath = Join-Path (Split-Path -Path $ConfigPath -Parent) "theme-switch.log"
    try {
        Write-ThemeSwitchLog -LogPath $fallbackLogPath -Message ("ERROR while applying the theme: {0}" -f $_.Exception.Message)
    }
    catch {
    }

    throw
}
