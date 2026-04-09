# Prerequisites

This document describes the prerequisites and how to meet them before using Win11 Auto Appearance Scheduler.

## Required

### Windows 11

- **Version:** Windows 11 (build 22000 or later)
- **Check Your Version:** Press `Win + R`, type `winver`, and press Enter
- **Why:** The theme settings are under `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`, a Windows 11 registry location

### PowerShell 5.1 or Later

- **Version:** PowerShell 5.1 or PowerShell 7+
- **Check Your Version:** Open PowerShell and run `$PSVersionTable.PSVersion`
- **Pre-installed:** Windows 11 ships with at least PowerShell 5.1
- **Upgrade:** Download from [Microsoft PowerShell Releases](https://github.com/PowerShell/PowerShell/releases) if needed

### Windows Task Scheduler Integration

- **Requirement:** Ability to create and modify tasks via PowerShell cmdlets
- **Typical Status:** Works out-of-the-box on personal machines
- **Enterprise Note:** Some Active Directory policies may restrict task creation; contact your IT administrator

## Optional but Recommended

### Windows Location (for automatic sunset/sunrise)

If you want to use automatic sunrise and sunset detection instead of a fixed schedule:

1. **Enable Windows Location:**
   - Open **Settings → Privacy & security → Location**
   - Toggle **Location** to **On**
   - Ensure location services are enabled for your user

2. **What the Installer Does:**
   - The installer can detect your location automatically if Windows Location is enabled
   - If not enabled, the installer will prompt you to enable it or offer manual coordinates

3. **Alternative:**
   - You can always provide coordinates manually (decimal degrees format) with no location service required

### Visual Studio Code (Optional)

If you use VS Code and want automatic theme syncing:

- **Installation:** Download from [code.visualstudio.com](https://code.visualstudio.com)
- **What the Installer Does:**
   - Detects if VS Code is installed
   - Lists available dark themes on your machine
   - Lets you choose which theme follows the schedule
   - Updates `settings.json` with theme preferences

- **Cannot Install VS Code?**
   - The tool works fine without it
   - Windows theme switching continues to work
   - Only VS Code theme syncing is skipped

## How the Installer Assists

The installer includes a **Requirements Assistant** that:

- Checks if all critical prerequisites are met
- Opens Windows Location settings if needed
- Offers to install VS Code if preferred
- Provides clear guidance for any missing dependencies
- Allows you to proceed with manual coordinates if automatic location is unavailable

## Troubleshooting

### PowerShell Execution Policy

If you cannot run `.ps1` files:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Windows Location Not Working

1. Check that Location is enabled in **Settings → Privacy & security → Location**
2. Restart Windows Location Service: Open PowerShell as Administrator and run:
   ```powershell
   Restart-Service -Name lfsvc
   ```

### VS Code Not Detected

- Verify VS Code is installed for the current user (not just a system-wide install)
- Check that the VS Code command is accessible in PowerShell:
  ```powershell
  Get-Command code
  ```
- If not found, try reinstalling VS Code with the "Add to PATH" option enabled

### Cannot Create Task Scheduler Tasks

- Verify your user account has permission to create tasks
- Try running the installer from an **Administrator** PowerShell session if needed
- For domain-managed machines, contact your IT service desk

## Quick Start Without Meeting All Prerequisites

**Minimum setup:**

```powershell
.\scripts\install.ps1 -Language en-EN -Latitude 40.7128 -Longitude -74.0060 -LocationName "New York" -TimeZoneId "Eastern Standard Time"
```

This works with just PowerShell 5.1 and Windows 11, no location service or VS Code needed.
