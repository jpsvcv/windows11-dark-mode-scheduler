# Quality Standards

This document defines the quality expectations and testing requirements for the Win11 Auto Appearance Scheduler project.

## Code Quality

### PowerShell Standards

All PowerShell scripts must:

- ✅ Pass `Invoke-ScriptAnalyzer` with no errors and minimal warnings
- ✅ Use `Set-StrictMode -Version Latest` for strong error detection
- ✅ Set `$ErrorActionPreference = "Stop"` to fail fast on errors
- ✅ Include `[CmdletBinding()]` attributes where appropriate
- ✅ Declare `[Parameter()]` attributes for all parameters
- ✅ Include help comments or documentation

### Naming Conventions

- Functions use approved PowerShell verbs (e.g., `Get-`, `Set-`, `Test-`, `Invoke-`)
- Names are descriptive and context-specific
- Constants and internal names avoid abbreviations where possible

### Code Comments

- Complex logic includes inline comments explaining the "why"
- Do not state the obvious; focus on intent and non-obvious behavior
- Keep comments in English

## Testing Requirements

### Automated Testing

**Integration Tests:** `.\tests\Invoke-IntegrationTests.ps1`

Validates:
- ✅ Requirement checks pass in the environment
- ✅ WhatIf install shows expected behavior
- ✅ Real install creates config, runtime files, and scheduled tasks
- ✅ Dark and light theme switching works
- ✅ VS Code settings are updated correctly
- ✅ Uninstall removes files and tasks cleanly
- ✅ All registry changes are rolled back after tests

**CI/CD Pipeline:** GitHub Actions

- ✅ Runs on `windows-latest` (Windows 11)
- ✅ PowerShell Script Analyzer validation
- ✅ Syntax validation for all `.ps1` and `.psm1` files

### Manual Testing Checklist

Before releasing, test:

- [ ] Interactive install with menu (no arguments)
- [ ] Install with manual coordinates
- [ ] Install with fixed dark-mode time
- [ ] Install with WhatIf preview
- [ ] Uninstall and verify removal
- [ ] Theme switching works at scheduled times
- [ ] VS Code theme changes (if applicable)
- [ ] Check tasks show correct configuration
- [ ] Log file is created and readable

## Documentation Quality

### README
- ✅ Up-to-date examples that work as documented
- ✅ Clear hierarchy and organization
- ✅ Links to related documentation
- ✅ Portuguese translation available

### Supplementary Docs
- ✅ PREREQUISITES.md covers system requirements
- ✅ TROUBLESHOOTING.md addresses common issues
- ✅ SECURITY.md documents privacy and security considerations
- ✅ CONTRIBUTING.md explains how to contribute
- ✅ CODE_OF_CONDUCT.md establishes community standards

### Code Documentation
- ✅ Functions have descriptive comments
- ✅ Complex algorithms are explained
- ✅ Parameter descriptions are accurate

## Release Quality

Before releasing a new version:

1. **Code Quality**
   ```powershell
   Invoke-ScriptAnalyzer -Path .\scripts\*.ps1,.\src\*.psm1,.\src\*.ps1
   ```
   - No errors
   - Warnings are acceptable if documented or by design

2. **Integration Tests**
   ```powershell
   .\tests\Invoke-IntegrationTests.ps1
   ```
   - All tests pass
   - No exceptions or role-back issues

3. **Manual Verification**
   - [ ] Test on a clean Windows 11 install
   - [ ] Verify installer UX (menu, prompts, confirmations)
   - [ ] Confirm theme switching at expected times
   - [ ] Uninstall and verify complete cleanup

4. **Documentation**
   - [ ] README.md is current
   - [ ] TROUBLESHOOTING.md covers recent issues
   - [ ] PREREQUISITES.md lists correct requirements
   - [ ] Portuguese translation is synchronized

5. **Git and GitHub**
   - [ ] Commit messages are clear and descriptive
   - [ ] No unintended files committed
   - [ ] PR reviews are complete
   - [ ] Branch is ready to merge

## Versioning

Follow [Semantic Versioning](https://semver.org/):

- **Major (X.0.0):** Breaking changes or major features
- **Minor (0.X.0):** New features, backward compatible
- **Patch (0.0.X):** Bug fixes and minor improvements

Example: `v1.2.3`

## Performance Expectations

### Runtime Performance

- `Invoke-Win11ThemeMode.ps1` should complete in < 2 seconds
- `Refresh-ThemeSchedule.ps1` should complete in < 5 seconds (including sunrise/sunset calculations)
- Theme changes should be perceived as instantaneous

### Resource Usage

- Scheduled tasks consume minimal CPU
- Registry modifications are minimal and efficient
- Log files do not grow excessively (< 10 MB per month typical)

## Accessibility and Localization

- ✅ Installer supports `pt-PT` and `en-EN` languages
- ✅ Messages are clear and user-friendly
- ✅ Error messages guide users toward solutions
- ✅ Documentation is available in multiple languages

## Security Compliance

- ✅ No external network calls
- ✅ No data collection or telemetry
- ✅ Registry access is user-scoped only
- ✅ Scheduled tasks run in user context only
- ✅ Installation can be inspected before execution (`-WhatIf`)
- ✅ Complete uninstall removes all artifacts

## Continuous Improvement

Quality standards are reviewed and updated as the project evolves. Contributors are encouraged to:

- Report issues that affect quality
- Suggest improvements to testing or processes
- Help maintain documentation accuracy
- Review pull requests for quality compliance

---

For questions about quality standards, refer to [CONTRIBUTING.md](../../CONTRIBUTING.md) or open an issue on GitHub.
