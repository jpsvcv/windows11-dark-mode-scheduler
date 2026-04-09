Push-Location 'c:\Users\jakso\OneDrive - Electra\projetos\win11-dark-mode'

$version = "v1.0.0"
$releaseDate = (Get-Date).ToString("yyyy-MM-dd")

Write-Host "Creating release tag $version..." -ForegroundColor Green
git tag -a $version -m "Release $version - Initial public release with full documentation and CI/CD

This is the first public release of Win11 Auto Appearance Scheduler. The project
is now ready for community use and contributions.

Features:
- Automatic Windows 11 theme switching based on sunset/sunrise
- Support for VS Code theme synchronization
- Bilingual installer (English and Portuguese)
- Full PowerShell script quality validation via GitHub Actions
- Comprehensive documentation and community guidelines

All integration tests pass and the project meets publication quality standards."

Write-Host "`nPushing tag to GitHub..." -ForegroundColor Green
git push origin $version

Write-Host "`nRelease tag created successfully!" -ForegroundColor Green
Write-Host "Tag: $version"
Write-Host "Date: $releaseDate"

Write-Host "`nNext step: Create GitHub Release at:"
Write-Host "https://github.com/jpsvcv/windows11-dark-mode-scheduler/releases/new?tag=$version"

Pop-Location
