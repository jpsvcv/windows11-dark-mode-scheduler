[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet("Menu", "Install", "Uninstall", "Requirements")]
    [string]$Action,

    [switch]$PassThru,

    [ValidateSet("pt-PT", "en-EN")]
    [string]$Language,

    [double]$Latitude,

    [double]$Longitude,

    [string]$LocationName,

    [string]$TimeZoneId = ([TimeZoneInfo]::Local.Id),

    [string]$DarkModeTime,

    [bool]$EnableVSCodeThemeSwitch = $true,

    [string]$VSCodeLightTheme = "Quit Lite",

    [string]$VSCodeDarkTheme,

    [string]$VSCodeSettingsPath,

    [string]$TaskPrefix = "Win11DarkMode",

    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "Win11DarkMode")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$sourceRoot = Join-Path $projectRoot "src"
$modulePath = Join-Path $sourceRoot "Win11DarkMode.psm1"
Import-Module $modulePath -Force
$script:InstallerBoundParameters = @{} + $PSBoundParameters

function Write-InstallerBlankLine {
    Write-Host ""
}

function Write-InstallerSection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-InstallerBlankLine
    Write-Host $Title
    Write-Host ("=" * $Title.Length)
}

function Clear-InstallerScreen {
    if (Test-InteractiveInstallerSession -and -not $WhatIfPreference) {
        Clear-Host
    }
}

function Test-InteractiveInstallerSession {
    return [Environment]::UserInteractive
}

function Get-DefaultInstallerLanguage {
    if ((Get-Culture).Name -like "pt*") {
        return "pt-PT"
    }

    return "en-EN"
}

function Resolve-InstallerLanguage {
    param(
        [AllowNull()]
        [string]$RequestedLanguage
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedLanguage)) {
        return $RequestedLanguage
    }

    $defaultLanguage = Get-DefaultInstallerLanguage
    if (-not (Test-InteractiveInstallerSession) -or $WhatIfPreference) {
        return $defaultLanguage
    }

    while ($true) {
        Clear-InstallerScreen
        Write-InstallerSection -Title "Installer language / Idioma do instalador"
        Write-Host "Select the installer language / Selecione o idioma do instalador:"
        Write-Host "[1] pt-PT"
        Write-Host "[2] en-EN"

        $choice = Read-Host "Choice / Escolha [$defaultLanguage]"
        if ([string]::IsNullOrWhiteSpace($choice)) {
            return $defaultLanguage
        }

        switch ($choice.Trim()) {
            "1" { return "pt-PT" }
            "2" { return "en-EN" }
            "pt-PT" { return "pt-PT" }
            "en-EN" { return "en-EN" }
            default { Write-Host "Invalid choice / Escolha invalida." }
        }
    }
}

function Get-InstallerMessages {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("pt-PT", "en-EN")]
        [string]$Language
    )

    if ($Language -eq "pt-PT") {
        return @{
            MenuHeader                       = "Menu principal"
            MenuInstall                      = "Instalar ou atualizar"
            MenuUninstall                    = "Desinstalar"
            MenuRequirements                 = "Verificar requisitos"
            MenuExit                         = "Sair"
            MenuPrompt                       = "Escolha uma opcao"
            CoordinatesPairRequired          = "Forneca Latitude e Longitude em conjunto."
            AutoLocationFailed               = "Nao foi possivel obter a localizacao automaticamente. Execute novamente com -Latitude e -Longitude."
            AutoLocationManualPrompt         = "Pretende introduzir as coordenadas manualmente agora? [Y/n]"
            DetectedLocationName             = "Localizacao detetada pelo Windows"
            ManualLocationName               = "Localizacao configurada manualmente"
            ManualLocationHeader             = "Coordenadas manuais"
            ManualLatitudePrompt             = "Latitude"
            ManualLongitudePrompt            = "Longitude"
            ManualLocationNamePrompt         = "Nome da localizacao (opcional)"
            ManualCoordinateInvalid          = "Valor invalido para {0}. Introduza um numero valido."
            VSCodeDiscoveryStart             = "VS Code detetado. A recolher temas escuros disponiveis..."
            VSCodeDarkThemeListHeader        = "Temas escuros disponiveis no VS Code:"
            VSCodeDarkThemePrompt            = "Escolha o numero do tema escuro para usar por defeito. Prima Enter para usar {0}."
            VSCodeDarkThemeInvalidChoice     = "Escolha invalida. Sera usado o tema predefinido {0}."
            VSCodeDefaultThemeSelected       = "Tema escuro do VS Code selecionado: {0}"
            VSCodeSkipped                    = "VS Code nao foi encontrado. A configuracao do VS Code sera ignorada."
            InstallAction                    = "Instalar a ferramenta e registar as tarefas no Task Scheduler"
            InstalledAt                      = "Ferramenta instalada em {0}"
            TasksCreated                     = "Tarefas criadas com o prefixo {0}"
            RequirementHeader                = "Estado dos requisitos"
            RequirementMet                   = "OK"
            RequirementMissing               = "Em falta"
            RequirementOptional              = "Opcional"
            RequirementWindowsBuild          = "Build compativel com Windows 11"
            RequirementPowerShell            = "PowerShell 5.1 ou superior"
            RequirementScheduledTasks        = "Cmdlets do Task Scheduler disponiveis"
            RequirementLocation              = "Localizacao do Windows pronta para autodeteccao"
            RequirementVSCode                = "Visual Studio Code instalado"
            RequirementWindowsBuildHelp      = "Esta ferramenta foi pensada para Windows 11 (build 22000 ou superior)."
            RequirementPowerShellHelp        = "O instalador requer PowerShell 5.1 ou superior."
            RequirementScheduledTasksHelp    = "Os cmdlets do Task Scheduler precisam de estar disponiveis para a automacao funcionar."
            RequirementLocationHelp          = "Ative a localizacao do Windows para permitir a deteccao automatica do nascer e do por do sol."
            RequirementVSCodeHelp            = "Instale o VS Code para ativar a sincronizacao automatica do tema do editor."
            RequirementLocationFixPrompt     = "Abrir as definicoes de localizacao do Windows agora? [Y/n]"
            RequirementVSCodeFixPrompt       = "Instalar o VS Code agora? [Y/n]"
            RequirementPowerShellFixPrompt   = "Abrir a pagina de instalacao do PowerShell agora? [Y/n]"
            RequirementOpenWebsiteFallback   = "Winget nao esta disponivel. A abrir a pagina de download..."
            RequirementRecheckPrompt         = "Prima Enter para verificar novamente."
            RequirementDisableVSCodePrompt   = "Pretende continuar sem integracao com o VS Code? [Y/n]"
            RequirementStillMissing          = "Ainda existem requisitos criticos em falta. Resolva-os antes de continuar."
            RequirementSummaryAllGood        = "Todos os requisitos relevantes estao prontos."
            ToolRemoved                      = "Ferramenta removida."
            MainActionCancelled              = "Operacao cancelada."
            InvalidMenuChoice                = "Opcao invalida."
            PressEnterToContinue             = "Prima Enter para continuar."
            ReturningToMenu                  = "A voltar ao menu principal..."
            InstallSummaryHeader             = "Resumo da instalacao"
            InstallSummaryLocation           = "Localizacao: {0} ({1}, {2})"
            InstallSummarySchedule           = "Proxima transicao: escuro em {0} e claro em {1}"
            InstallSummaryVSCode             = "Tema do VS Code: claro '{0}', escuro '{1}'"
            RequirementsCompleted            = "Verificacao de requisitos concluida."
            OperationFailedHeader            = "Nao foi possivel concluir a operacao"
            OperationFailedMessage           = "{0}"
        }
    }

    return @{
        MenuHeader                       = "Main menu"
        MenuInstall                      = "Install or update"
        MenuUninstall                    = "Uninstall"
        MenuRequirements                 = "Check requirements"
        MenuExit                         = "Exit"
        MenuPrompt                       = "Choose an option"
        CoordinatesPairRequired          = "Provide Latitude and Longitude together."
        AutoLocationFailed               = "Unable to detect the location automatically. Run the installer again with -Latitude and -Longitude."
        AutoLocationManualPrompt         = "Do you want to enter the coordinates manually now? [Y/n]"
        DetectedLocationName             = "Location detected from Windows"
        ManualLocationName               = "Location configured manually"
        ManualLocationHeader             = "Manual coordinates"
        ManualLatitudePrompt             = "Latitude"
        ManualLongitudePrompt            = "Longitude"
        ManualLocationNamePrompt         = "Location name (optional)"
        ManualCoordinateInvalid          = "Invalid value for {0}. Enter a valid number."
        VSCodeDiscoveryStart             = "VS Code detected. Collecting available dark themes..."
        VSCodeDarkThemeListHeader        = "Available VS Code dark themes:"
        VSCodeDarkThemePrompt            = "Select the number of the default dark theme. Press Enter to use {0}."
        VSCodeDarkThemeInvalidChoice     = "Invalid choice. The default theme {0} will be used."
        VSCodeDefaultThemeSelected       = "Selected VS Code dark theme: {0}"
        VSCodeSkipped                    = "VS Code was not found. VS Code configuration will be skipped."
        InstallAction                    = "Install the tool and register the Task Scheduler jobs"
        InstalledAt                      = "Tool installed at {0}"
        TasksCreated                     = "Tasks created with prefix {0}"
        RequirementHeader                = "Requirement status"
        RequirementMet                   = "Ready"
        RequirementMissing               = "Missing"
        RequirementOptional              = "Optional"
        RequirementWindowsBuild          = "Windows 11 compatible build"
        RequirementPowerShell            = "PowerShell 5.1 or later"
        RequirementScheduledTasks        = "Task Scheduler cmdlets available"
        RequirementLocation              = "Windows Location ready for auto-detection"
        RequirementVSCode                = "Visual Studio Code installed"
        RequirementWindowsBuildHelp      = "This tool targets Windows 11 style builds (22000 or newer)."
        RequirementPowerShellHelp        = "The installer requires PowerShell 5.1 or later."
        RequirementScheduledTasksHelp    = "Task Scheduler cmdlets must be available for autonomous automation."
        RequirementLocationHelp          = "Enable Windows Location to allow automatic sunrise and sunset detection."
        RequirementVSCodeHelp            = "Install VS Code to enable automatic editor theme syncing."
        RequirementLocationFixPrompt     = "Open Windows Location settings now? [Y/n]"
        RequirementVSCodeFixPrompt       = "Install VS Code now? [Y/n]"
        RequirementPowerShellFixPrompt   = "Open the PowerShell install page now? [Y/n]"
        RequirementOpenWebsiteFallback   = "Winget is not available. Opening the download page..."
        RequirementRecheckPrompt         = "Press Enter to re-check."
        RequirementDisableVSCodePrompt   = "Do you want to continue without VS Code integration? [Y/n]"
        RequirementStillMissing          = "Critical requirements are still missing. Resolve them before continuing."
        RequirementSummaryAllGood        = "All relevant requirements are ready."
        ToolRemoved                      = "Tool removed."
        MainActionCancelled              = "Operation cancelled."
        InvalidMenuChoice                = "Invalid option."
        PressEnterToContinue             = "Press Enter to continue."
        ReturningToMenu                  = "Returning to the main menu..."
        InstallSummaryHeader             = "Installation summary"
        InstallSummaryLocation           = "Location: {0} ({1}, {2})"
        InstallSummarySchedule           = "Next transition: dark at {0} and light at {1}"
        InstallSummaryVSCode             = "VS Code theme: light '{0}', dark '{1}'"
        RequirementsCompleted            = "Requirement check completed."
        OperationFailedHeader            = "The operation could not be completed"
        OperationFailedMessage           = "{0}"
    }
}

function Pause-Installer {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    if (Test-InteractiveInstallerSession) {
        Read-Host $Messages.PressEnterToContinue | Out-Null
    }
}

function Test-InstallerConfirmation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    if (-not (Test-InteractiveInstallerSession) -or $WhatIfPreference) {
        return $false
    }

    $answer = Read-Host $Prompt
    return [string]::IsNullOrWhiteSpace($answer) -or $answer.Trim().ToLowerInvariant() -in @("y", "yes", "s", "sim")
}

function ConvertTo-InstallerCoordinate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalizedValue = $Value.Trim().Replace(",", ".")
    $parsedValue = 0.0
    $styles = [System.Globalization.NumberStyles]::Float -bor [System.Globalization.NumberStyles]::AllowLeadingSign
    $culture = [System.Globalization.CultureInfo]::InvariantCulture

    if ([double]::TryParse($normalizedValue, $styles, $culture, [ref]$parsedValue)) {
        return $parsedValue
    }

    return $null
}

function Read-InstallerCoordinate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    while ($true) {
        $rawValue = Read-Host $Prompt
        $parsedValue = ConvertTo-InstallerCoordinate -Value $rawValue

        if ($null -ne $parsedValue) {
            return [double]$parsedValue
        }

        Write-Host ($Messages.ManualCoordinateInvalid -f $Prompt)
    }
}

function Resolve-ManualCoordinates {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    if (-not (Test-InteractiveInstallerSession) -or $WhatIfPreference) {
        return $null
    }

    if (-not (Test-InstallerConfirmation -Prompt $Messages.AutoLocationManualPrompt)) {
        return $null
    }

    Write-InstallerSection -Title $Messages.ManualLocationHeader
    $manualLatitude = Read-InstallerCoordinate -Prompt $Messages.ManualLatitudePrompt -Messages $Messages
    $manualLongitude = Read-InstallerCoordinate -Prompt $Messages.ManualLongitudePrompt -Messages $Messages
    $manualLocationName = Read-Host $Messages.ManualLocationNamePrompt

    return [pscustomobject]@{
        Latitude     = $manualLatitude
        Longitude    = $manualLongitude
        LocationName = $manualLocationName
        Source       = "Manual"
    }
}

function Show-InstallerFailure {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    Write-InstallerSection -Title $Messages.OperationFailedHeader
    Write-Host ($Messages.OperationFailedMessage -f $ErrorRecord.Exception.Message) -ForegroundColor Red
}

function Resolve-AutomaticCoordinates {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    $attemptTimeouts = @(30, 45)
    for ($index = 0; $index -lt $attemptTimeouts.Count; $index++) {
        $timeoutSeconds = $attemptTimeouts[$index]
        $detectedCoordinates = Get-CoordinatesFromWindowsLocation -TimeoutSeconds $timeoutSeconds
        if ($null -ne $detectedCoordinates) {
            return $detectedCoordinates
        }

        $isLastAttempt = ($index -eq ($attemptTimeouts.Count - 1))
        if (-not $isLastAttempt) {
            # Give Windows Location a brief grace period before retrying.
            Start-Sleep -Seconds 3
        }
    }

    return $null
}

function Test-CommandSetAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CommandNames
    )

    foreach ($commandName in $CommandNames) {
        if ($null -eq (Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1)) {
            return $false
        }
    }

    return $true
}

function Get-WindowsBuildNumber {
    $buildValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).CurrentBuildNumber
    if ([string]::IsNullOrWhiteSpace($buildValue)) {
        return 0
    }

    return [int]$buildValue
}

function Get-WindowsLocationConsentValue {
    $locationConsent = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -ErrorAction SilentlyContinue
    if ($null -eq $locationConsent) {
        return $null
    }

    return $locationConsent.Value
}

function Test-WindowsLocationAvailability {
    <#
    .SYNOPSIS
    Tests whether automatic location data can be obtained from Windows.

    .DESCRIPTION
    Instead of checking permissions only, this function tries to obtain
    coordinates and confirms that Windows has usable location data.
    #>
    param(
        [int]$TimeoutSeconds = 5
    )

    try {
        $coordinates = Get-CoordinatesFromWindowsLocation -TimeoutSeconds $TimeoutSeconds
        return ($null -ne $coordinates)
    }
    catch {
        return $false
    }
}

function Get-RequirementStatuses {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages,

        [Parameter(Mandatory = $true)]
        [bool]$UsesAutomaticLocationDetection,

        [Parameter(Mandatory = $true)]
        [bool]$RequiresVSCodeIntegration
    )

    $statuses = @()
    $windowsBuild = Get-WindowsBuildNumber
    $statuses += [pscustomobject]@{
        Id         = "WindowsBuild"
        Name       = $Messages.RequirementWindowsBuild
        IsMet      = ($windowsBuild -ge 22000)
        IsCritical = $true
        Details    = "{0} (build {1})" -f $Messages.RequirementWindowsBuildHelp, $windowsBuild
        FixAction  = "None"
    }

    $statuses += [pscustomobject]@{
        Id         = "PowerShell"
        Name       = $Messages.RequirementPowerShell
        IsMet      = ([version]$PSVersionTable.PSVersion -ge [version]"5.1")
        IsCritical = $true
        Details    = "{0} (current: {1})" -f $Messages.RequirementPowerShellHelp, $PSVersionTable.PSVersion
        FixAction  = "PowerShell"
    }

    $scheduledTasksReady = Test-CommandSetAvailable -CommandNames @(
        "Register-ScheduledTask",
        "New-ScheduledTaskTrigger",
        "New-ScheduledTaskAction",
        "Unregister-ScheduledTask"
    )
    $statuses += [pscustomobject]@{
        Id         = "ScheduledTasks"
        Name       = $Messages.RequirementScheduledTasks
        IsMet      = $scheduledTasksReady
        IsCritical = $true
        Details    = $Messages.RequirementScheduledTasksHelp
        FixAction  = "None"
    }

    if ($UsesAutomaticLocationDetection) {
        $locationService = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        $locationConsent = Get-WindowsLocationConsentValue

        # Validate the prerequisites first.
        $preconditionsMet = ($null -ne $locationService) -and ($locationService.Status -eq "Running") -and ($locationConsent -eq "Allow")

        # Try to obtain real coordinates with a short timeout.
        # This checks data availability, not only permission state.
        $dataAvailable = $false
        if ($preconditionsMet) {
            $dataAvailable = Test-WindowsLocationAvailability -TimeoutSeconds 5
        }

        # The requirement passes only when both prerequisites and data are available.
        $locationReady = $preconditionsMet -and $dataAvailable

        $locationServiceStatus = if ($null -eq $locationService) { "NotAvailable" } else { $locationService.Status }
        $locationConsentLabel = if ([string]::IsNullOrWhiteSpace($locationConsent)) { "Unknown" } else { $locationConsent }
        $dataLabel = if ($preconditionsMet) { if ($dataAvailable) { "Available" } else { "Not yet available" } } else { "N/A" }

        $statuses += [pscustomobject]@{
            Id         = "Location"
            Name       = $Messages.RequirementLocation
            IsMet      = $locationReady
            IsCritical = $false
            Details    = "{0} (service: {1}; consent: {2}; data: {3})" -f $Messages.RequirementLocationHelp, $locationServiceStatus, $locationConsentLabel, $dataLabel
            FixAction  = "Location"
        }
    }

    if ($RequiresVSCodeIntegration) {
        $statuses += [pscustomobject]@{
            Id         = "VSCode"
            Name       = $Messages.RequirementVSCode
            IsMet      = (Test-IsVSCodeInstalled)
            IsCritical = $false
            Details    = $Messages.RequirementVSCodeHelp
            FixAction  = "VSCode"
        }
    }

    return @($statuses)
}

function Show-RequirementStatuses {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Statuses,

        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    Write-InstallerSection -Title $Messages.RequirementHeader
    foreach ($status in $Statuses) {
        $stateLabel = if ($status.IsMet) { $Messages.RequirementMet } elseif ($status.IsCritical) { $Messages.RequirementMissing } else { $Messages.RequirementOptional }
        $line = "- [{0}] {1}" -f $stateLabel, $status.Name

        if (-not $status.IsMet -and -not [string]::IsNullOrWhiteSpace($status.Details)) {
            $line = "{0} - {1}" -f $line, $status.Details
        }

        Write-Host $line
    }
}

function Invoke-LocationRequirementFix {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    if (-not (Test-InstallerConfirmation -Prompt $Messages.RequirementLocationFixPrompt)) {
        return
    }

    try {
        Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
    }
    catch {
    }

    Start-Process "ms-settings:privacy-location" | Out-Null
    Read-Host $Messages.RequirementRecheckPrompt | Out-Null
}

function Invoke-PowerShellRequirementFix {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    if (-not (Test-InstallerConfirmation -Prompt $Messages.RequirementPowerShellFixPrompt)) {
        return
    }

    $wingetCommand = Get-Command "winget" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $wingetCommand) {
        & $wingetCommand.Source install --exact --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements
    }
    else {
        Write-Host $Messages.RequirementOpenWebsiteFallback
        Start-Process "https://aka.ms/powershell-release?tag=stable" | Out-Null
    }

    Read-Host $Messages.RequirementRecheckPrompt | Out-Null
}

function Invoke-VSCodeRequirementFix {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    if (-not (Test-InstallerConfirmation -Prompt $Messages.RequirementVSCodeFixPrompt)) {
        return $false
    }

    $wingetCommand = Get-Command "winget" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $wingetCommand) {
        & $wingetCommand.Source install --exact --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements
    }
    else {
        Write-Host $Messages.RequirementOpenWebsiteFallback
        Start-Process "https://code.visualstudio.com/Download" | Out-Null
    }

    Read-Host $Messages.RequirementRecheckPrompt | Out-Null
    return (Test-IsVSCodeInstalled)
}

function Resolve-RequirementIssues {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages,

        [Parameter(Mandatory = $true)]
        [bool]$UsesAutomaticLocationDetection,

        [Parameter(Mandatory = $true)]
        [bool]$RequiresVSCodeIntegration
    )

    $currentVSCodeIntegration = $RequiresVSCodeIntegration

    if (-not (Test-InteractiveInstallerSession) -or $WhatIfPreference) {
        return [pscustomobject]@{
            RequiresVSCodeIntegration = $currentVSCodeIntegration
            Statuses                  = @(Get-RequirementStatuses -Messages $Messages -UsesAutomaticLocationDetection $UsesAutomaticLocationDetection -RequiresVSCodeIntegration $currentVSCodeIntegration)
        }
    }

    while ($true) {
        $statuses = @(Get-RequirementStatuses -Messages $Messages -UsesAutomaticLocationDetection $UsesAutomaticLocationDetection -RequiresVSCodeIntegration $currentVSCodeIntegration)
        Show-RequirementStatuses -Statuses $statuses -Messages $Messages

        $unmetCritical = @($statuses | Where-Object { -not $_.IsMet -and $_.IsCritical })
        $unmetOptional = @($statuses | Where-Object { -not $_.IsMet -and -not $_.IsCritical })

        if ($unmetCritical.Count -eq 0 -and $unmetOptional.Count -eq 0) {
            Write-Host $Messages.RequirementSummaryAllGood
            break
        }

        if ($unmetCritical.Count -eq 0 -and $unmetOptional.Count -gt 0) {
            $vscodeMissing = $unmetOptional | Where-Object { $_.Id -eq "VSCode" } | Select-Object -First 1
            if ($null -ne $vscodeMissing) {
                $installed = Invoke-VSCodeRequirementFix -Messages $Messages
                if (-not $installed -and (Test-InstallerConfirmation -Prompt $Messages.RequirementDisableVSCodePrompt)) {
                    $currentVSCodeIntegration = $false
                }
                continue
            }

            break
        }

        foreach ($status in $unmetCritical) {
            switch ($status.FixAction) {
                "Location" { Invoke-LocationRequirementFix -Messages $Messages }
                "PowerShell" { Invoke-PowerShellRequirementFix -Messages $Messages }
                default { }
            }
        }

        $updatedStatuses = @(Get-RequirementStatuses -Messages $Messages -UsesAutomaticLocationDetection $UsesAutomaticLocationDetection -RequiresVSCodeIntegration $currentVSCodeIntegration)
        if (@($updatedStatuses | Where-Object { -not $_.IsMet -and $_.IsCritical }).Count -gt 0) {
            break
        }
    }

    return [pscustomobject]@{
        RequiresVSCodeIntegration = $currentVSCodeIntegration
        Statuses                  = @(Get-RequirementStatuses -Messages $Messages -UsesAutomaticLocationDetection $UsesAutomaticLocationDetection -RequiresVSCodeIntegration $currentVSCodeIntegration)
    }
}

function Test-HasInstallerConfigurationArguments {
    $boundInstallParameters = @(
        "Latitude",
        "Longitude",
        "LocationName",
        "TimeZoneId",
        "DarkModeTime",
        "EnableVSCodeThemeSwitch",
        "VSCodeLightTheme",
        "VSCodeDarkTheme",
        "VSCodeSettingsPath",
        "TaskPrefix",
        "InstallRoot"
    )

    foreach ($parameterName in $boundInstallParameters) {
        if ($script:InstallerBoundParameters.ContainsKey($parameterName)) {
            return $true
        }
    }

    return $false
}

function Resolve-MainAction {
    param(
        [AllowNull()]
        [string]$RequestedAction,

        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedAction)) {
        return $RequestedAction
    }

    if (-not (Test-InteractiveInstallerSession) -or (Test-HasInstallerConfigurationArguments)) {
        return "Install"
    }

    while ($true) {
        Clear-InstallerScreen
        Write-InstallerSection -Title $Messages.MenuHeader
        Write-Host ("[1] {0}" -f $Messages.MenuInstall)
        Write-Host ("[2] {0}" -f $Messages.MenuUninstall)
        Write-Host ("[3] {0}" -f $Messages.MenuRequirements)
        Write-Host ("[4] {0}" -f $Messages.MenuExit)

        $choice = Read-Host $Messages.MenuPrompt
        switch ($choice.Trim()) {
            "1" { return "Install" }
            "2" { return "Uninstall" }
            "3" { return "Requirements" }
            "4" { return "Menu" }
            default { Write-Host $Messages.InvalidMenuChoice }
        }
    }
}

function Show-InstallSummary {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Result,

        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    Write-InstallerSection -Title $Messages.InstallSummaryHeader
    Write-Host ($Messages.InstallSummaryLocation -f $Result.LocationName, $Result.Latitude, $Result.Longitude)
    Write-Host ($Messages.InstallSummarySchedule -f $Result.NextDarkEventLocal.ToString("yyyy-MM-dd HH:mm:ss"), $Result.NextLightEventLocal.ToString("yyyy-MM-dd HH:mm:ss"))

    if ($Result.VSCodeDetected) {
        Write-Host ($Messages.InstallSummaryVSCode -f $Result.VSCodeLightTheme, $Result.VSCodeDarkTheme)
    }
}

function Select-VSCodeDarkTheme {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$DarkThemes,

        [Parameter(Mandatory = $true)]
        [string]$DefaultTheme,

        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    if (-not (Test-InteractiveInstallerSession) -or $WhatIfPreference) {
        Write-Host ($Messages.VSCodeDefaultThemeSelected -f $DefaultTheme)
        return $DefaultTheme
    }

    Write-Host $Messages.VSCodeDarkThemeListHeader
    for ($index = 0; $index -lt $DarkThemes.Count; $index++) {
        Write-Host ("[{0}] {1}" -f ($index + 1), $DarkThemes[$index].Name)
    }

    $selection = Read-Host ($Messages.VSCodeDarkThemePrompt -f $DefaultTheme)
    if ([string]::IsNullOrWhiteSpace($selection)) {
        Write-Host ($Messages.VSCodeDefaultThemeSelected -f $DefaultTheme)
        return $DefaultTheme
    }

    $selectedIndex = 0
    if ([int]::TryParse($selection, [ref]$selectedIndex) -and $selectedIndex -ge 1 -and $selectedIndex -le $DarkThemes.Count) {
        $selectedTheme = $DarkThemes[$selectedIndex - 1].Name
        Write-Host ($Messages.VSCodeDefaultThemeSelected -f $selectedTheme)
        return $selectedTheme
    }

    $matchingTheme = $DarkThemes | Where-Object { $_.Name -eq $selection } | Select-Object -First 1
    if ($null -ne $matchingTheme) {
        Write-Host ($Messages.VSCodeDefaultThemeSelected -f $matchingTheme.Name)
        return $matchingTheme.Name
    }

    Write-Host ($Messages.VSCodeDarkThemeInvalidChoice -f $DefaultTheme)
    return $DefaultTheme
}

function Invoke-RequirementsAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages,

        [Parameter(Mandatory = $true)]
        [bool]$UsesAutomaticLocationDetection,

        [Parameter(Mandatory = $true)]
        [bool]$RequiresVSCodeIntegration
    )

    return Resolve-RequirementIssues -Messages $Messages -UsesAutomaticLocationDetection $UsesAutomaticLocationDetection -RequiresVSCodeIntegration $RequiresVSCodeIntegration
}

function Invoke-UninstallAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    $uninstallPath = Join-Path $PSScriptRoot "uninstall.ps1"
    & $uninstallPath -TaskPrefix $TaskPrefix -InstallRoot $InstallRoot -WhatIf:$WhatIfPreference
}

function Invoke-InstallAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Messages
    )

    $hasLatitude = $script:InstallerBoundParameters.ContainsKey("Latitude")
    $hasLongitude = $script:InstallerBoundParameters.ContainsKey("Longitude")

    if ($hasLatitude -xor $hasLongitude) {
        throw $Messages.CoordinatesPairRequired
    }

    [void](Resolve-ThemeSwitchTimeZone -TimeZoneId $TimeZoneId)
    [void](ConvertTo-ThemeSwitchClockTime -ClockTime $DarkModeTime)

    $usesAutomaticLocationDetection = (-not $hasLatitude -and -not $hasLongitude)
    $requirementResult = Invoke-RequirementsAction -Messages $Messages -UsesAutomaticLocationDetection $usesAutomaticLocationDetection -RequiresVSCodeIntegration $EnableVSCodeThemeSwitch
    $EnableVSCodeThemeSwitch = [bool]$requirementResult.RequiresVSCodeIntegration

    if (@($requirementResult.Statuses | Where-Object { -not $_.IsMet -and $_.IsCritical }).Count -gt 0) {
        throw $Messages.RequirementStillMissing
    }

    $coordinateSource = "Manual"

    if ($usesAutomaticLocationDetection) {
        $detectedCoordinates = Resolve-AutomaticCoordinates -Messages $Messages
        if ($null -eq $detectedCoordinates) {
            Write-Host $Messages.AutoLocationFailed
            $manualCoordinates = Resolve-ManualCoordinates -Messages $Messages
            if ($null -eq $manualCoordinates) {
                # Interactive runs can return to the menu. Non-interactive runs fail fast.
                if (Test-InteractiveInstallerSession) {
                    throw $Messages.MainActionCancelled
                }
                else {
                    throw $Messages.AutoLocationFailed
                }
            }

            $detectedCoordinates = $manualCoordinates
        }

        $Latitude = $detectedCoordinates.Latitude
        $Longitude = $detectedCoordinates.Longitude
        $coordinateSource = $detectedCoordinates.Source
    }

    if ([string]::IsNullOrWhiteSpace($LocationName)) {
        if ($coordinateSource -eq "WindowsLocation") {
            $LocationName = $Messages.DetectedLocationName
        }
        else {
            $LocationName = $Messages.ManualLocationName
        }
    }

    $hasCustomVSCodeSettingsPath = $script:InstallerBoundParameters.ContainsKey("VSCodeSettingsPath")
    if ([string]::IsNullOrWhiteSpace($VSCodeSettingsPath)) {
        $VSCodeSettingsPath = Get-DefaultVSCodeSettingsPath
    }

    $darkThemes = @()
    $preferredDarkTheme = "VS Code Dark"
    $vscodeDetected = Test-IsVSCodeInstalled

    if ($EnableVSCodeThemeSwitch -and $vscodeDetected) {
        Write-Host $Messages.VSCodeDiscoveryStart
        $darkThemes = @(Get-VSCodeThemes -Kind Dark)
        $preferredDarkTheme = Get-PreferredVSCodeDarkTheme -AvailableThemes $darkThemes

        if ([string]::IsNullOrWhiteSpace($VSCodeDarkTheme)) {
            if ($darkThemes.Count -gt 0) {
                $VSCodeDarkTheme = Select-VSCodeDarkTheme -DarkThemes $darkThemes -DefaultTheme $preferredDarkTheme -Messages $Messages
            }
            else {
                $VSCodeDarkTheme = $preferredDarkTheme
                Write-Host ($Messages.VSCodeDefaultThemeSelected -f $preferredDarkTheme)
            }
        }
    }
    elseif ($EnableVSCodeThemeSwitch -and -not $vscodeDetected -and -not $hasCustomVSCodeSettingsPath) {
        $EnableVSCodeThemeSwitch = $false
        Write-Host $Messages.VSCodeSkipped
    }

    if ([string]::IsNullOrWhiteSpace($VSCodeDarkTheme)) {
        $VSCodeDarkTheme = $preferredDarkTheme
    }

    $installRootPath = [System.IO.Path]::GetFullPath($InstallRoot)
    $runtimeDirectory = Join-Path $installRootPath "runtime"
    $configPath = Get-ThemeSwitchConfigPath -InstallRoot $installRootPath
    $logPath = Get-ThemeSwitchLogPath -InstallRoot $installRootPath

    $config = [pscustomobject][ordered]@{
        Version                 = 1
        Language                = $Language
        LocationName            = $LocationName
        Latitude                = [math]::Round($Latitude, 6)
        Longitude               = [math]::Round($Longitude, 6)
        TimeZoneId              = $TimeZoneId
        DarkModeTime            = if ([string]::IsNullOrWhiteSpace($DarkModeTime)) { $null } else { $DarkModeTime }
        TaskPrefix              = $TaskPrefix
        LogPath                 = $logPath
        CoordinateSource        = $coordinateSource
        EnableVSCodeThemeSwitch = $EnableVSCodeThemeSwitch
        VSCodeLightTheme        = $VSCodeLightTheme
        VSCodeDarkTheme         = $VSCodeDarkTheme
        VSCodeSettingsPath      = $VSCodeSettingsPath
        InstalledAt             = (Get-Date).ToString("s")
    }

    $transitions = Get-NextThemeTransitions -Config $config

    if ($PSCmdlet.ShouldProcess($installRootPath, $Messages.InstallAction)) {
        Initialize-ThemeSwitchDirectory -Path $installRootPath | Out-Null
        Initialize-ThemeSwitchDirectory -Path $runtimeDirectory | Out-Null
        Copy-Item -Path (Join-Path $sourceRoot "*.ps1") -Destination $runtimeDirectory -Force
        Copy-Item -Path (Join-Path $sourceRoot "*.psm1") -Destination $runtimeDirectory -Force

        Write-ThemeSwitchConfig -Config $config -Path $configPath | Out-Null
        Register-ThemeRefreshTask -ConfigPath $configPath -RuntimeDirectory $runtimeDirectory -TaskPrefix $TaskPrefix | Out-Null
        $transitions = Update-ThemeEventTasks -ConfigPath $configPath -RuntimeDirectory $runtimeDirectory -TaskPrefix $TaskPrefix
        Invoke-ThemeSwitch -ConfigPath $configPath | Out-Null

        Write-Host ($Messages.InstalledAt -f $installRootPath)
        Write-Host ($Messages.TasksCreated -f $TaskPrefix)
    }

    return [pscustomobject]@{
        Language            = $Language
        InstallRoot         = $installRootPath
        ConfigPath          = $configPath
        RuntimeDirectory    = $runtimeDirectory
        TaskPrefix          = $TaskPrefix
        LocationName        = $LocationName
        Latitude            = [math]::Round($Latitude, 6)
        Longitude           = [math]::Round($Longitude, 6)
        TimeZoneId          = $TimeZoneId
        DarkModeTime        = $config.DarkModeTime
        VSCodeDetected      = $vscodeDetected
        VSCodeLightTheme    = $config.VSCodeLightTheme
        VSCodeDarkTheme     = $config.VSCodeDarkTheme
        VSCodeSettingsPath  = $config.VSCodeSettingsPath
        NextDarkEventLocal  = $transitions.NextDarkEventLocal
        NextLightEventLocal = $transitions.NextLightEventLocal
    }
}

$Language = Resolve-InstallerLanguage -RequestedLanguage $Language
$Messages = Get-InstallerMessages -Language $Language
$isInteractiveMenuSession = [string]::IsNullOrWhiteSpace($Action) -and (Test-InteractiveInstallerSession) -and -not (Test-HasInstallerConfigurationArguments)

if ($isInteractiveMenuSession) {
    while ($true) {
        Clear-InstallerScreen
        $resolvedAction = Resolve-MainAction -RequestedAction $null -Messages $Messages

        if ($resolvedAction -eq "Menu") {
            Write-Host $Messages.MainActionCancelled
            break
        }

        try {
            switch ($resolvedAction) {
                "Requirements" {
                    $usesAutomaticLocationDetection = (-not $script:InstallerBoundParameters.ContainsKey("Latitude") -and -not $script:InstallerBoundParameters.ContainsKey("Longitude"))
                    $null = Invoke-RequirementsAction -Messages $Messages -UsesAutomaticLocationDetection $usesAutomaticLocationDetection -RequiresVSCodeIntegration $EnableVSCodeThemeSwitch
                    Write-InstallerBlankLine
                    Write-Host $Messages.RequirementsCompleted
                    Pause-Installer -Messages $Messages
                    Write-InstallerBlankLine
                    Write-Host $Messages.ReturningToMenu
                }
                "Uninstall" {
                    Invoke-UninstallAction -Messages $Messages
                    Pause-Installer -Messages $Messages
                    Write-InstallerBlankLine
                    Write-Host $Messages.ReturningToMenu
                }
                default {
                    $installResult = Invoke-InstallAction -Messages $Messages
                    Show-InstallSummary -Result $installResult -Messages $Messages
                    Pause-Installer -Messages $Messages
                    Write-InstallerBlankLine
                    Write-Host $Messages.ReturningToMenu
                }
            }
        }
        catch {
            Show-InstallerFailure -Messages $Messages -ErrorRecord $_
            Pause-Installer -Messages $Messages
            Write-InstallerBlankLine
            Write-Host $Messages.ReturningToMenu
        }
    }
}
else {
    try {
        $resolvedAction = if ([string]::IsNullOrWhiteSpace($Action)) { "Install" } else { $Action }

        switch ($resolvedAction) {
            "Menu" {
                Write-Host $Messages.MainActionCancelled
            }
            "Requirements" {
                $usesAutomaticLocationDetection = (-not $script:InstallerBoundParameters.ContainsKey("Latitude") -and -not $script:InstallerBoundParameters.ContainsKey("Longitude"))
                $requirementResult = Invoke-RequirementsAction -Messages $Messages -UsesAutomaticLocationDetection $usesAutomaticLocationDetection -RequiresVSCodeIntegration $EnableVSCodeThemeSwitch
                Write-InstallerBlankLine
                Write-Host $Messages.RequirementsCompleted

                if ($PassThru) {
                    $requirementResult
                }
            }
            "Uninstall" {
                Invoke-UninstallAction -Messages $Messages
            }
            default {
                $installResult = Invoke-InstallAction -Messages $Messages
                Show-InstallSummary -Result $installResult -Messages $Messages

                if ($PassThru) {
                    $installResult
                }
            }
        }
    }
    catch {
        Show-InstallerFailure -Messages $Messages -ErrorRecord $_
        exit 1
    }
}
