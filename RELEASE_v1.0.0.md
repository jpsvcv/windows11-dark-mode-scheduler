# Release v1.0.0

**Release Date:** April 9, 2026

This is the initial public release of **Win11 Auto Appearance Scheduler**, a Windows 11 utility that brings macOS-style automatic light/dark theme switching to Windows.

## 🎉 What's Included

### Core Features
- **Automatic Theme Switching:** Transitions between light and dark modes based on sunset/sunrise or a fixed schedule
- **Solar Calculations:** Uses latitude, longitude, and timezone to calculate local sunrise and sunset times
- **VS Code Integration:** Automatically synchronizes light and dark theme preferences in Visual Studio Code
- **Bilingual Installer:** English (en-EN) and Portuguese (pt-PT) support
- **Windows Task Scheduler Integration:** Autonomous operation with three scheduled tasks

### Quality & Documentation
- **Comprehensive Documentation:**
  - README with quick-start examples
  - System requirements and prerequisites guide
  - Complete troubleshooting guide
  - Security and privacy policy
  - Contributing guidelines and Code of Conduct
  - Quality standards documentation

- **Automated Testing:**
  - Full integration test suite covering install, theme switching, and uninstall
  - GitHub Actions CI/CD pipeline with PowerShell Script Analyzer validation
  - All tests pass on Windows 11

- **Code Quality:**
  - PowerShell Script Analyzer compliance
  - Proper error handling with `Set-StrictMode` and `$ErrorActionPreference = "Stop"`
  - All approved PowerShell naming conventions
  - CmdletBinding attributes where needed

## 🔧 Technical Improvements (Pre-Release)

- Fixed PowerShell analyzer warnings (verb naming)
- Added CI/CD pipeline for continuous validation
- Created issue and PR templates for community contributions
- Added release notes template for future releases

## 📦 Installation

```powershell
# Interactive installation with menu
.\scripts\install.ps1

# With explicit coordinates
.\scripts\install.ps1 -Language en-EN -Latitude 40.7128 -Longitude -74.0060 -TimeZoneId "Eastern Standard Time"

# With fixed dark-mode start time
.\scripts\install.ps1 -DarkModeTime 19:30
```

For detailed instructions, see [README.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/README.md) and [PREREQUISITES.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/PREREQUISITES.md).

## 🐛 Known Limitations

None reported. Please file issues if you encounter problems.

## 📊 Release Statistics

| Metric | Value |
|--------|-------|
| Files Created | 12 |
| Documentation | ~32 KB |
| PowerShell Scripts | 5 |
| Integration Tests | ✅ All Pass |
| CI/CD Validation | ✅ Enabled |
| Community Guidelines | ✅ In Place |

## 🙏 Credits

This project represents the culmination of careful planning, testing, and documentation to ensure a high-quality experience for Windows 11 users who prefer automatic theme scheduling similar to macOS.

## 📖 Full Documentation

- [README.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler#readme)
- [PREREQUISITES.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/PREREQUISITES.md)
- [TROUBLESHOOTING.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/TROUBLESHOOTING.md)
- [SECURITY.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/SECURITY.md)
- [CONTRIBUTING.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/CONTRIBUTING.md)
- [QUALITY_STANDARDS.md](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/QUALITY_STANDARDS.md)

## 🔗 Links

- **GitHub Repository:** [jpsvcv/windows11-dark-mode-scheduler](https://github.com/jpsvcv/windows11-dark-mode-scheduler)
- **Issues & Discussions:** [GitHub Issues](https://github.com/jpsvcv/windows11-dark-mode-scheduler/issues)
- **License:** MIT ([LICENSE](https://github.com/jpsvcv/windows11-dark-mode-scheduler/blob/main/LICENSE))

---

**Status:** ✅ Ready for Production Use

Thank you for using Win11 Auto Appearance Scheduler! We welcome feedback and contributions from the community.
