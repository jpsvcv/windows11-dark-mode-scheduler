# Publishing Guide

This repository is ready for GitHub publication and already organized for release.

## Pre-Publish Checklist

1. Run integration tests:
   - `.\tests\Invoke-IntegrationTests.ps1`
2. Validate docs:
   - `README.md`
   - `README.pt-PT.md`
3. Confirm repository metadata:
   - `.github/REPOSITORY_METADATA.md`
   - `.github/RELEASE_TEMPLATE.md`

## Suggested GitHub Repository Settings

- Visibility: `Private` or `Public` according to release stage
- Default branch: `main`
- About description:
  - `Bring a macOS-like automatic light/dark appearance schedule to Windows 11 using a fixed time or local sunrise and sunset detection.`
- Topics:
  - `windows11`
  - `dark-mode`
  - `light-mode`
  - `task-scheduler`
  - `powershell`
  - `vscode`
  - `sunrise-sunset`
  - `auto-appearance`

## Release Checklist

1. Update release notes from `.github/RELEASE_TEMPLATE.md`
2. Create a version tag (for example `v1.0.0`)
3. Publish release notes in both English and Portuguese when applicable
