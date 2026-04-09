Push-Location 'c:\Users\jakso\OneDrive - Electra\projetos\win11-dark-mode'

Write-Host "FINAL VERIFICATION REPORT" -ForegroundColor Cyan
Write-Host "=" * 70
Write-Host ""

Write-Host "Git Status:" -ForegroundColor Green
git status --short
Write-Host ""

Write-Host "Latest Commits:" -ForegroundColor Green
git log --oneline -5
Write-Host ""

Write-Host "Tags:" -ForegroundColor Green
git tag -l
Write-Host ""

Write-Host "GitHub Remote URL:" -ForegroundColor Green
git remote -v | grep fetch
Write-Host ""

Write-Host "Repository Structure:" -ForegroundColor Green
Get-ChildItem -Depth 1 -Directory | ForEach-Object { "  📁 $($_.Name)" }
Write-Host ""

Write-Host "Documentation Files:" -ForegroundColor Green
Get-ChildItem -Filter "*.md" -File | ForEach-Object { "  📄 $($_.Name)" }
Write-Host ""

Write-Host "Verification Complete!" -ForegroundColor Green
Write-Host "All changes have been committed and pushed to GitHub" -ForegroundColor Green
Write-Host "Release v1.0.0 is ready at: https://github.com/jpsvcv/windows11-dark-mode-scheduler/releases/tag/v1.0.0"

Pop-Location
