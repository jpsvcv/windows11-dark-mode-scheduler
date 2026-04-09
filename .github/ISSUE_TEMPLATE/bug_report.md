---
name: Bug Report
about: Report a bug or unexpected behavior
title: "[BUG] "
labels: bug
assignees: ''

---

## Description

A clear and concise description of what the bug is.

## Steps to Reproduce

1. Step 1
2. Step 2
3. ...

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened instead.

## Screenshots

If applicable, add screenshots or log excerpts to help explain the issue.

## Environment

- **Windows Build:** (e.g., Windows 11 build 22631)
  - Check with: `winver`
- **PowerShell Version:** (e.g., 5.1 or 7.4.0)
  - Check with: `$PSVersionTable.PSVersion`
- **Tool Version:** (e.g., 1.0.0 from GitHub release date)
- **Location:** (e.g., Praia, Cabo Verde)
- **Time Zone:** (e.g., Cape Verde Standard Time)
- **VS Code Installed:** Yes/No
- **Windows Location Enabled:** Yes/No

## Logs

Attach relevant log output from `$env:LOCALAPPDATA\Win11DarkMode\theme-switch.log`:

```
[Paste last 30 lines of theme-switch.log here]
```

## Diagnostic Output

Run this and paste the output:

```powershell
.\scripts\check-tasks.ps1
```

## Additional Context

Add any other context about the problem here.

---

**Please check:**
- [ ] I have read [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md)
- [ ] I have checked existing issues to avoid duplicates
- [ ] I have verified all [prerequisites](../../PREREQUISITES.md) are met
