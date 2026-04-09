# Troubleshooting Guide

## Common Issues and Solutions

### Installation Issues

#### "Noe foi possivel obter a localizacao automaticamente" / "Unable to detect the location automatically"

**Cause:** Windows Location is not enabled or the location service is unavailable.

**Solution:**
1. Open **Settings → Privacy & security → Location**
2. Toggle **Location** to **On**
3. Wait a moment for the location service to initialize
4. Re-run the installer

**Alternative:**
- Provide manual coordinates using `-Latitude` and `-Longitude`:
  ```powershell
  .\scripts\install.ps1 -Latitude 40.7128 -Longitude -74.0060 -LocationName "New York" -TimeZoneId "Eastern Standard Time"
  ```

#### "Requisitos críticos em falta" / "Critical requirements are still missing"

**Cause:** One or more required dependencies are missing (Windows 11, PowerShell 5.1+, or Task Scheduler integration).

**Solution:**
1. Review the requirement check output:
   ```powershell
   .\scripts\install.ps1 -Action Requirements
   ```
2. Address the missing requirement:
   - **Windows 11 < build 22000:** Upgrade to the latest Windows 11 version
   - **PowerShell < 5.1:** Install PowerShell 7+ from [GitHub](https://github.com/PowerShell/PowerShell/releases)
   - **Task Scheduler not available:** This is rare; try running PowerShell as Administrator

#### "SetupError: Script\install.ps1 exited with code 1"

**Cause:** The installer encountered an error during execution.

**Solution:**
1. Examine the error message for specific details
2. Common causes:
   - Insufficient disk space in `%LOCALAPPDATA%`
   - Mixed `Latitude`/`Longitude` arguments (both must be provided or neither)
   - Invalid timezone ID (check `Get-TimeZone -ListAvailable`)
3. Try re-running with explicit parameters:
   ```powershell
   .\scripts\install.ps1 -Language en-EN -Latitude 14.9330 -Longitude -23.5133 -TimeZoneId "Cape Verde Standard Time"
   ```

### Theme Switching Issues

#### Windows theme is not changing at the scheduled time

**Steps to diagnose:**
1. **Check if tasks were created:**
   ```powershell
   .\scripts\check-tasks.ps1
   ```
   Look for three tasks:
   - `Win11DarkMode_Refresh`
   - `Win11DarkMode_Dark`
   - `Win11DarkMode_Light`

2. **Check the config file:**
   ```powershell
   Get-Content "$env:LOCALAPPDATA\Win11DarkMode\config.json" | ConvertFrom-Json
   ```
   Verify coordinates, timezone, and times are correct.

3. **Check the log file:**
   ```powershell
   Get-Content "$env:LOCALAPPDATA\Win11DarkMode\theme-switch.log" -Tail 30
   ```
   Look for any error messages.

4. **Manually trigger the theme switch:**
   ```powershell
   & "$env:LOCALAPPDATA\Win11DarkMode\runtime\Invoke-Win11ThemeMode.ps1" -Mode Dark
   ```
   If this works, but the scheduled task doesn't, the Task Scheduler configuration may be misconfigured.

#### Registry access denied when switching themes

**Cause:** Permission issue or registry location is locked.

**Solution:**
1. Try running PowerShell as Administrator
2. Check that `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize` is accessible:
   ```powershell
   Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
   ```
3. If the registry path doesn't exist, create it:
   ```powershell
   New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Force
   ```

#### VS Code theme not changing with Windows theme

**Possible causes:**
1. **VS Code `autoDetectColorScheme` not enabled:**
   ```powershell
   Get-Content "$env:APPDATA\Code\User\settings.json" | Select-String "window.autoDetectColorScheme"
   ```

2. **Configured themes don't exist in VS Code:**
   - Open VS Code → **File → Preferences → Color Theme**
   - Verify the themes set during installation are available
   - If missing, re-run the installer and select different themes

3. **VS Code is running when theme changes:**
   - VS Code may cache theme settings at startup
   - Close and reopen VS Code to apply theme changes

**Force Update VS Code settings:**
```powershell
& "$env:LOCALAPPDATA\Win11DarkMode\runtime\Invoke-Win11ThemeMode.ps1"
```

### Uninstall Issues

#### Cannot uninstall (scheduled tasks still exist)

**Solution:**
1. Force uninstall with explicit task prefix:
   ```powershell
   .\scripts\uninstall.ps1
   ```

2. If tasks remain after uninstall, remove them manually:
   ```powershell
   Get-ScheduledTask -TaskName "Win11DarkMode*" | Unregister-ScheduledTask -Confirm:$false
   ```

3. Remove the installation directory:
   ```powershell
   Remove-Item -Path "$env:LOCALAPPDATA\Win11DarkMode" -Recurse -Force
   ```

#### Config file is locked or cannot be removed

**Cause:** The runtime may be executing at the moment of uninstall.

**Solution:**
1. Wait a moment and try again
2. Close any PowerShell windows running the theme script
3. Try uninstalling again:
   ```powershell
   .\scripts\uninstall.ps1
   ```

## Collecting Diagnostic Information

If you need to report an issue, gather this information:

```powershell
Write-Host "=== System Information ==="
Get-ComputerInfo | Select-Object OSName, OSVersion, OSBuildNumber

Write-Host "=== PowerShell Version ==="
$PSVersionTable

Write-Host "=== Installation Status ==="
if (Test-Path "$env:LOCALAPPDATA\Win11DarkMode\config.json") {
    Get-Content "$env:LOCALAPPDATA\Win11DarkMode\config.json" | ConvertFrom-Json
    Write-Host "Install Root exists: YES"
} else {
    Write-Host "Install Root exists: NO"
}

Write-Host "=== Scheduled Tasks ==="
Get-ScheduledTask -TaskName "Win11DarkMode*" -ErrorAction SilentlyContinue | Select-Object TaskName, State

Write-Host "=== Recent Logs ==="
if (Test-Path "$env:LOCALAPPDATA\Win11DarkMode\theme-switch.log") {
    Get-Content "$env:LOCALAPPDATA\Win11DarkMode\theme-switch.log" -Tail 50
}

Write-Host "=== Theme Registry Values ==="
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -ErrorAction SilentlyContinue
```

## Getting Help

1. **Check:** The [README.md](README.md) and [PREREQUISITES.md](PREREQUISITES.md) for common setup guidance
2. **Search:** Existing [GitHub Issues](../../issues) to see if your issue has been reported
3. **Report:** Open a new issue with diagnostic information from above
4. **Share:** Include your steps to reproduce and expected vs. actual behavior

## Performance and Logs

The tool writes logs to `%LOCALAPPDATA%\Win11DarkMode\theme-switch.log`. Review this file periodically to ensure smooth operation.

To reduce log file size:
```powershell
Clear-Content "$env:LOCALAPPDATA\Win11DarkMode\theme-switch.log"
```
