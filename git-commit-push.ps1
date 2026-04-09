Push-Location 'c:\Users\jakso\OneDrive - Electra\projetos\win11-dark-mode'

Write-Host "Adding all changes to git..." -ForegroundColor Green
git add -A

Write-Host "`nCreating commit..." -ForegroundColor Green
git commit -m "feat: Add GitHub publication package

- Fix PowerShell Script Analyzer warnings (Pause-Installer -> Wait-Installer)
- Add CmdletBinding(SupportsShouldProcess) to Invoke-InstallAction
- Add comprehensive documentation (8 new files)
- Add GitHub Actions CI/CD workflow
- Add issue and PR templates
- Update README with badges and doc index
- Fix integration tests for non-interactive execution
- All integration tests pass successfully

This release prepares the project for public GitHub publication with full
documentation, community guidelines, security policy, and automated testing."

Write-Host "`nPushing to main branch..." -ForegroundColor Green
git push origin main

Write-Host "`nGit operations completed!" -ForegroundColor Green
git log --oneline -1

Pop-Location
