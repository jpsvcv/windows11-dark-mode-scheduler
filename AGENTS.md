# Repository Memory

## Project Identity

- Project name: `Win11 Auto Appearance Scheduler`
- Primary goal: bring a macOS-like automatic appearance cycle to Windows 11
- Core behavior:
  - switch to dark mode at a user-defined time, or by default at local sunset
  - switch back to light mode at local sunrise
  - run autonomously through Windows Task Scheduler
- Primary target location used in documentation and tests: Praia, Cabo Verde
- Default time zone used in examples and integration tests: `Cape Verde Standard Time`

## User Experience Rules

- The installer is bilingual and supports `pt-PT` and `en-EN`.
- The installer should feel guided and friendly in a terminal session.
- Interactive menu flow should clear the screen between major steps.
- When automatic Windows location is unavailable, the installer should fail gracefully and offer manual coordinates in interactive mode.
- If VS Code is installed and dark theme selection is needed, the fallback theme is `VS Code Dark`.
- Default VS Code light theme is `Quit Lite`.

## Repository Layout

- `src/`
  - `Win11DarkMode.psm1`: core logic for solar calculations, Windows theme switching, VS Code settings updates, config handling, and Task Scheduler integration
  - `Invoke-Win11ThemeMode.ps1`: runtime entry point that applies the current theme
  - `Refresh-ThemeSchedule.ps1`: runtime entry point that recalculates upcoming transitions and refreshes the scheduled tasks
- `scripts/`
  - `install.ps1`: main installer, requirements assistant, menu flow, and VS Code theme selection
  - `uninstall.ps1`: removal flow for tasks and installed runtime
  - `check-tasks.ps1`: diagnostic helper for inspecting the installed config and scheduled tasks
- `tests/`
  - `Invoke-IntegrationTests.ps1`: isolated end-to-end tests using a temporary install root and unique task prefix
- `docs/archive/`
  - historical notes, diagnostics, and earlier analysis files retained for reference

## Structural Constraints

- No scripts should live in the repository root.
- Root should stay limited to documentation, metadata, configuration files, and top-level directories.
- Keep comments in code in English.
- Prefer ASCII in edited files unless there is a strong reason not to.

## Testing Expectations

- Parse-check the main scripts after changes.
- Run `.\tests\Invoke-IntegrationTests.ps1` before publishing meaningful installer or runtime changes.
- The integration test is expected to validate:
  - requirement check
  - `-WhatIf` install path
  - real install into a temporary directory
  - config and runtime file creation
  - Task Scheduler registration
  - runtime refresh execution
  - dark and light theme application
  - VS Code settings update in a temporary `settings.json`
  - uninstall cleanup for files and tasks
- The integration test restores the previous Windows light/dark registry values at the end.

## Known Design Decisions

- The tool writes Windows appearance settings under `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`.
- Installed runtime files are copied to `%LOCALAPPDATA%\Win11DarkMode\runtime` by default.
- Scheduled tasks are created per-user and rely on the current user context because the theme lives under `HKCU`.
- Automatic location detection is optional; manual coordinates are a supported first-class path.
- Legacy analysis files from earlier debugging sessions are archived instead of being used as active documentation.
