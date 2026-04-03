[CmdletBinding()]
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
$config = $null

if (Test-Path -LiteralPath $configPath) {
    $config = Read-ThemeSwitchConfig -Path $configPath
}

if ([string]::IsNullOrWhiteSpace($TaskPrefix)) {
    if ($null -ne $config -and -not [string]::IsNullOrWhiteSpace($config.TaskPrefix)) {
        $TaskPrefix = $config.TaskPrefix
    }
    else {
        $TaskPrefix = "Win11DarkMode"
    }
}

$taskNames = Get-ThemeSwitchTaskNames -TaskPrefix $TaskPrefix

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host $Title
    Write-Host ("=" * $Title.Length)
}

function Get-TaskSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($null -eq $task) {
        return [pscustomobject]@{
            TaskName      = $TaskName
            Exists        = $false
            State         = "Missing"
            StartBoundary = $null
            Command       = $null
            Arguments     = $null
        }
    }

    $firstTrigger = @($task.Triggers | Where-Object { $_.StartBoundary } | Select-Object -First 1)[0]
    $firstAction = @($task.Actions | Select-Object -First 1)[0]

    return [pscustomobject]@{
        TaskName      = $TaskName
        Exists        = $true
        State         = $task.State
        StartBoundary = if ($null -ne $firstTrigger) { $firstTrigger.StartBoundary } else { $null }
        Command       = if ($null -ne $firstAction) { $firstAction.Execute } else { $null }
        Arguments     = if ($null -ne $firstAction) { $firstAction.Arguments } else { $null }
    }
}

Write-Section -Title "Task Scheduler status"
foreach ($taskName in @($taskNames.Refresh, $taskNames.Dark, $taskNames.Light)) {
    $summary = Get-TaskSummary -TaskName $taskName
    if (-not $summary.Exists) {
        Write-Host ("- {0}: missing" -f $summary.TaskName)
        continue
    }

    Write-Host ("- {0}: {1}" -f $summary.TaskName, $summary.State)
    if (-not [string]::IsNullOrWhiteSpace($summary.StartBoundary)) {
        Write-Host ("  Run at: {0}" -f $summary.StartBoundary)
    }
    if (-not [string]::IsNullOrWhiteSpace($summary.Command)) {
        Write-Host ("  Command: {0}" -f $summary.Command)
    }
}

Write-Section -Title "Configuration"
if ($null -eq $config) {
    Write-Host ("Config file not found: {0}" -f $configPath)
}
else {
    Write-Host ("- Install root: {0}" -f $installRootPath)
    Write-Host ("- Location: {0}" -f $config.LocationName)
    Write-Host ("- Coordinates: {0}, {1}" -f $config.Latitude, $config.Longitude)
    Write-Host ("- Time zone: {0}" -f $config.TimeZoneId)
    Write-Host ("- Dark mode time: {0}" -f $(if ([string]::IsNullOrWhiteSpace($config.DarkModeTime)) { "sunset" } else { $config.DarkModeTime }))
    Write-Host ("- VS Code sync: {0}" -f $config.EnableVSCodeThemeSwitch)
}
