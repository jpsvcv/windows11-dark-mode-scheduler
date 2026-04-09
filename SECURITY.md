# Security Policy

## Reporting Security Vulnerabilities

**Do not** open a public GitHub issue to report security vulnerabilities. Instead, email your security concern directly to the project maintainer or use the GitHub Security Advisory feature.

Our goal is to address security issues promptly and ensure users are protected before public disclosure.

## Supported Versions

| Version | Status          |
|---------|-----------------|
| Latest  | ✅ Supported    |
| Older   | ⚠️  No updates  |

## Security Considerations

### Registry Access

This tool modifies Windows registry values under:
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`

Only **user-specific** settings are modified, not system-wide settings. The installer always creates tasks in the user's Task Scheduler context.

### Windows Location

The tool reads Windows Location settings if enabled, but does not transmit location data externally. All calculations (sunrise/sunset) occur locally.

### VS Code Settings

If VS Code integration is enabled, the tool modifies:
- `window.autoDetectColorScheme`
- `workbench.preferredLightColorTheme`
- `workbench.preferredDarkColorTheme`

These are user-specific settings in your local `settings.json` file.

### Task Scheduler

Tasks are created with the following properties:
- Run in the **current user context** (not system-wide)
- Use **stored credentials** for the current user only
- Restricted to paths in `%LOCALAPPDATA%\Win11DarkMode`

### No Network Communication

This tool does **not**:
- Contact external servers
- Upload any user data
- Monitor usage patterns
- Require internet access

All functionality is local to your machine.

## Best Practices for Users

1. **Keep PowerShell Updated:** Use PowerShell 7+ when possible
2. **Run from Trusted Sources:** Only use this tool from GitHub releases or trusted repositories
3. **Review Before Running:** Read scripts before executing them, or at least verify the hash
4. **Monitor Logs:** Check `%LOCALAPPDATA%\Win11DarkMode\theme-switch.log` for unexpected activity
5. **Verify Uninstall:** Confirm tasks are removed with `.\scripts\check-tasks.ps1` after uninstall

## Compliance

This project:
- ✅ Does not require elevated privileges for normal operation
- ✅ Does not extract or share personal data
- ✅ Respects Windows Registry access control
- ✅ Uses only local Task Scheduler integration
- ✅ Includes installation/uninstall cleanup

## Future Security Updates

We will notify users of security patches through GitHub Releases. Always keep the tool updated to receive security fixes.
