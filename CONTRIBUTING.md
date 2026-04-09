# Contributing to Win11 Auto Appearance Scheduler

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and inclusive. All contributors are expected to maintain a welcoming and supportive environment.

## How to Contribute

### Reporting Issues

- Check existing issues before opening a new one to avoid duplicates
- Provide a clear, descriptive title
- Include:
  - Your Windows 11 build number (`winver`)
  - PowerShell version (`$PSVersionTable.PSVersion`)
  - Steps to reproduce the issue
  - Expected behavior vs. actual behavior
  - Relevant configuration (location, timezone, VS Code version, etc.)

### Submitting Pull Requests

1. **Fork the repository** and create a feature branch from `main`
2. **Code changes:**
   - Follow the existing code style and conventions
   - Add comments explaining complex logic
   - Test your changes thoroughly
3. **Run validation before submitting:**
   ```powershell
   Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
   Invoke-ScriptAnalyzer -Path .\scripts\install.ps1,.\scripts\uninstall.ps1,.\scripts\check-tasks.ps1,.\src\Win11DarkMode.psm1
   .\tests\Invoke-IntegrationTests.ps1
   ```
4. **Write a clear commit message** that explains the purpose of your changes
5. **Link related issues** by referencing issue numbers in the PR description

## Development Setup

- **Requirements:** Windows 11, PowerShell 5.1+, and optionally VS Code
- **Test Location:** The integration tests default to **Praia, Cabo Verde** for reproducibility
- **Quick Test:** `.\tests\Invoke-IntegrationTests.ps1` validates the full workflow

## Documentation

- Update `README.md` and `README.pt-PT.md` when adding features or changing behavior
- Ensure examples work as documented
- Add inline comments for complex logic or non-obvious code

## Performance Considerations

- Avoid expensive operations in `Invoke-Win11ThemeMode.ps1` (runtime is called frequently)
- Minimize startup time in `Refresh-ThemeSchedule.ps1` (runs on logon)
- Test with actual Windows Location and Task Scheduler integration

## Release Process

- Ensure all tests pass: `.\tests\Invoke-IntegrationTests.ps1`
- Update version metadata if applicable
- Create a PR and ensure all CI checks pass before merging

Thank you for contributing!
