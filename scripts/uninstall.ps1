[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TaskPrefix,

    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "Win11DarkMode")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path $projectRoot "src\Win11DarkMode.psm1"
Import-Module $modulePath -Force

$installRootPath = [System.IO.Path]::GetFullPath($InstallRoot)
$configPath = Get-ThemeSwitchConfigPath -InstallRoot $installRootPath

if ([string]::IsNullOrWhiteSpace($TaskPrefix) -and (Test-Path -LiteralPath $configPath)) {
    try {
        $TaskPrefix = (Read-ThemeSwitchConfig -Path $configPath).TaskPrefix
    }
    catch {
        $TaskPrefix = "Win11DarkMode"
    }
}

if ([string]::IsNullOrWhiteSpace($TaskPrefix)) {
    $TaskPrefix = "Win11DarkMode"
}

if ($PSCmdlet.ShouldProcess($installRootPath, "Remove the tool and its Task Scheduler jobs")) {
    Unregister-ThemeSwitchTasks -TaskPrefix $TaskPrefix

    # Reset the Windows theme to light before removing the tool.
    try {
        Set-WindowsThemeMode -Mode Light -Force | Out-Null
    }
    catch {
        # Ignore theme reset errors during removal.
    }

    if (Test-Path -LiteralPath $installRootPath) {
        Remove-Item -LiteralPath $installRootPath -Recurse -Force
    }

    Write-Host "Tool removed."
}
