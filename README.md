# Win11 Auto Appearance Scheduler

Windows 11 utility designed to bring a macOS-like automatic appearance schedule to Windows 11.

The goal is to make Windows 11 behave more like macOS, automatically transitioning between light mode and dark mode either from a user-defined schedule or from local sunrise and sunset detection.

The switch can be driven by:

- a user-defined time for entering dark mode
- or, by default, the sunset time for the configured location
- the local sunrise time for returning to light mode

If Visual Studio Code is installed, the installer can also list every dark theme available on the machine and let the user choose the default dark theme to follow the Windows schedule. If no choice is made, the installer falls back to `VS Code Dark` and, when needed, to the closest built-in dark theme available locally.

## Features

- Brings a macOS-style automatic light/dark appearance workflow to Windows 11
- Switches the Windows 11 app and system theme automatically
- Uses sunrise/sunset calculations from latitude, longitude, and Windows timezone IDs
- Supports a fixed dark-mode start time if the user prefers a manual schedule
- Registers autonomous jobs in Windows Task Scheduler
- Detects VS Code and configures:
  - `window.autoDetectColorScheme`
  - `workbench.preferredLightColorTheme`
  - `workbench.preferredDarkColorTheme`
- Offers localized installer interaction in `pt-PT` or `en-EN`

## Requirements

- Windows 11
- PowerShell 5.1 or later
- Permission to create tasks in Windows Task Scheduler for the current user
- Windows Location enabled if you want automatic coordinate detection

If one of the relevant requirements is missing, the installer now includes an interactive requirements assistant that can:

- open Windows Location settings when automatic location detection is not ready
- install or open the download flow for VS Code when editor theme syncing is enabled
- guide the user through the missing dependency before installation continues

## Quick Start

Run the installer and let it prompt for the installation language:

```powershell
.\scripts\install.ps1
```

The main menu offers:

- `Install or update`
- `Uninstall`
- `Check requirements`
- `Exit`

Install with explicit coordinates for Praia, Cabo Verde:

```powershell
.\scripts\install.ps1 -Language en-EN -Latitude 14.9330 -Longitude -23.5133 -LocationName "Praia, Cabo Verde" -TimeZoneId "Cape Verde Standard Time"
```

Install with a fixed dark-mode start time:

```powershell
.\scripts\install.ps1 -Language en-EN -Latitude 14.9330 -Longitude -23.5133 -LocationName "Praia, Cabo Verde" -TimeZoneId "Cape Verde Standard Time" -DarkModeTime 19:30
```

Preview the installation without applying changes:

```powershell
.\scripts\install.ps1 -Language en-EN -Latitude 14.9330 -Longitude -23.5133 -TimeZoneId "Cape Verde Standard Time" -WhatIf
```

## VS Code Theme Selection

When VS Code is detected and `-VSCodeDarkTheme` is not provided, the installer:

1. lists every dark theme discovered from built-in and installed VS Code extensions
2. asks the user which dark theme should be used by default
3. falls back to `VS Code Dark` when the user presses Enter without choosing

The default light theme remains `Quit Lite` unless overridden with `-VSCodeLightTheme`.

## How It Works

The installer copies the runtime scripts to `%LOCALAPPDATA%\Win11DarkMode`, writes a persistent `config.json`, and creates three scheduled tasks:

- one daily/logon refresh job
- one one-shot task for the next dark transition
- one one-shot task for the next light transition

The runtime updates Windows theme values in:

- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`

Because the theme is stored under `HKCU`, the scheduled tasks run in the current user context.

In practice, this gives Windows 11 a macOS-style automatic appearance cycle: light during the day, dark at night, based either on a fixed schedule or on the sun events for the configured location.

The installer acts as the main entry point for the project, so installation, uninstallation, and assisted requirement checks all happen from the same menu-driven experience.

## Useful Commands

Apply the theme immediately from the installed runtime:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Win11DarkMode\runtime\Invoke-Win11ThemeMode.ps1"
```

Refresh the scheduled tasks manually:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Win11DarkMode\runtime\Refresh-ThemeSchedule.ps1"
```

Remove the tool:

```powershell
.\scripts\uninstall.ps1
```

Inspect the installed schedule:

```powershell
.\scripts\check-tasks.ps1
```

Run the end-to-end integration tests:

```powershell
.\tests\Invoke-IntegrationTests.ps1
```

## Project Structure

- `src/Win11DarkMode.psm1`: core logic, VS Code theme discovery, sunrise/sunset calculation, scheduling helpers
- `src/Invoke-Win11ThemeMode.ps1`: applies the light or dark theme immediately
- `src/Refresh-ThemeSchedule.ps1`: recalculates the next transitions and refreshes the Task Scheduler jobs
- `scripts/install.ps1`: localized installer and VS Code theme selector
- `scripts/uninstall.ps1`: removes the installed files and scheduled tasks
- `scripts/check-tasks.ps1`: inspects the installed configuration and scheduled tasks
- `tests/Invoke-IntegrationTests.ps1`: runs isolated end-to-end integration tests

## Notes

- If automatic location detection fails, rerun the installer with `-Latitude` and `-Longitude`.
- If the configured location does not use the current Windows timezone, pass `-TimeZoneId` explicitly.
- By default, VS Code settings are written to the first detected settings file among standard VS Code paths. You can override that with `-VSCodeSettingsPath`.
- Logs are written to `%LOCALAPPDATA%\Win11DarkMode\theme-switch.log`.

## Portuguese Documentation

Portuguese documentation is available in [README.pt-PT.md](README.pt-PT.md).
