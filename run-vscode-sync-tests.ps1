#!/usr/bin/env pwsh
Set-Location 'C:\Users\jakso\OneDrive - Electra\projetos\win11-dark-mode'
& '.\tests\Invoke-VSCodeSyncTests.ps1'
exit $LASTEXITCODE
