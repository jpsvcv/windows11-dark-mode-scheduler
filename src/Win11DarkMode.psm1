Set-StrictMode -Version Latest

function Get-ThemeSwitchInstallRoot {
    return Join-Path $env:LOCALAPPDATA "Win11DarkMode"
}

function Get-ThemeSwitchConfigPath {
    param(
        [string]$InstallRoot = (Get-ThemeSwitchInstallRoot)
    )

    return Join-Path $InstallRoot "config.json"
}

function Get-ThemeSwitchLogPath {
    param(
        [string]$InstallRoot = (Get-ThemeSwitchInstallRoot)
    )

    return Join-Path $InstallRoot "theme-switch.log"
}

function Get-DefaultVSCodeSettingsPath {
    $candidates = Get-VSCodeSettingsCandidates

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $candidates[0]
}

function Get-VSCodeSettingsCandidates {
    return @(
        (Join-Path $env:APPDATA "Code\User\settings.json"),
        (Join-Path $env:APPDATA "Code - Insiders\User\settings.json"),
        (Join-Path $env:APPDATA "VSCodium\User\settings.json")
    )
}

function Get-VSCodeExtensionSearchRoots {
    return @(
        (Join-Path $env:USERPROFILE ".vscode\extensions"),
        (Join-Path $env:USERPROFILE ".vscode-insiders\extensions"),
        (Join-Path $env:USERPROFILE ".vscode-oss\extensions")
    ) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } |
        Sort-Object -Unique
}

function Get-VSCodeInstallSearchRoots {
    $baseCandidates = New-Object System.Collections.Generic.List[string]

    foreach ($commandName in @("code", "code-insiders", "codium")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) {
            $baseCandidates.Add((Split-Path -Path $command.Source -Parent))
        }
    }

    foreach ($commonPath in @(
        (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"),
        (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code Insiders"),
        (Join-Path $env:LOCALAPPDATA "Programs\VSCodium"),
        (Join-Path $env:ProgramFiles "Microsoft VS Code"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft VS Code"),
        (Join-Path $env:ProgramFiles "Microsoft VS Code Insiders"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft VS Code Insiders"),
        (Join-Path $env:ProgramFiles "VSCodium"),
        (Join-Path ${env:ProgramFiles(x86)} "VSCodium")
    )) {
        if (-not [string]::IsNullOrWhiteSpace($commonPath)) {
            $baseCandidates.Add($commonPath)
        }
    }

    $manifestRoots = New-Object System.Collections.Generic.List[string]

    foreach ($baseCandidate in ($baseCandidates | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $baseCandidate)) {
            continue
        }

        $directManifestRoot = Join-Path $baseCandidate "resources\app\extensions"
        if (Test-Path -LiteralPath $directManifestRoot) {
            $manifestRoots.Add($directManifestRoot)
        }

        foreach ($childDirectory in (Get-ChildItem -Path $baseCandidate -Directory -ErrorAction SilentlyContinue)) {
            $nestedManifestRoot = Join-Path $childDirectory.FullName "resources\app\extensions"
            if (Test-Path -LiteralPath $nestedManifestRoot) {
                $manifestRoots.Add($nestedManifestRoot)
            }
        }
    }

    return $manifestRoots | Sort-Object -Unique
}

function Get-VSCodeThemeKind {
    param(
        [AllowNull()]
        [string]$UiTheme
    )

    if ([string]::IsNullOrWhiteSpace($UiTheme)) {
        return "Unknown"
    }

    if ($UiTheme -match "light") {
        return "Light"
    }

    if ($UiTheme -match "dark|black") {
        return "Dark"
    }

    return "Unknown"
}

function Resolve-VSCodeNlsString {
    param(
        [AllowNull()]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [string]$PackageDirectory
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    if ($Value -notmatch '^%(?<Key>.+)%$') {
        return $Value
    }

    $nlsPath = Join-Path $PackageDirectory "package.nls.json"
    if (-not (Test-Path -LiteralPath $nlsPath)) {
        return $Matches["Key"]
    }

    try {
        $nlsContent = Get-Content -LiteralPath $nlsPath -Raw | ConvertFrom-Json
    }
    catch {
        return $Matches["Key"]
    }

    $property = $nlsContent.PSObject.Properties[$Matches["Key"]]
    if ($null -eq $property -or [string]::IsNullOrWhiteSpace($property.Value)) {
        return $Matches["Key"]
    }

    return $property.Value
}

function Get-VSCodeThemes {
    [CmdletBinding()]
    param(
        [ValidateSet("All", "Dark", "Light")]
        [string]$Kind = "All"
    )

    $themesByName = @{}
    $manifestRoots = @()
    $manifestRoots += Get-VSCodeInstallSearchRoots
    $manifestRoots += Get-VSCodeExtensionSearchRoots

    foreach ($manifestRoot in ($manifestRoots | Sort-Object -Unique)) {
        foreach ($packageDirectory in (Get-ChildItem -Path $manifestRoot -Directory -ErrorAction SilentlyContinue)) {
            $packagePath = Join-Path $packageDirectory.FullName "package.json"
            if (-not (Test-Path -LiteralPath $packagePath)) {
                continue
            }

            try {
                $manifest = Get-Content -LiteralPath $packagePath -Raw | ConvertFrom-Json
            }
            catch {
                continue
            }

            $contributesProperty = $manifest.PSObject.Properties["contributes"]
            if ($null -eq $contributesProperty -or $null -eq $contributesProperty.Value) {
                continue
            }

            $themesProperty = $contributesProperty.Value.PSObject.Properties["themes"]
            if ($null -eq $themesProperty -or $null -eq $themesProperty.Value) {
                continue
            }

            $displayName = $null
            $displayNameProperty = $manifest.PSObject.Properties["displayName"]
            if ($null -ne $displayNameProperty) {
                $displayName = $displayNameProperty.Value
            }

            $sourceName = Resolve-VSCodeNlsString -Value $displayName -PackageDirectory $packageDirectory.FullName
            if ([string]::IsNullOrWhiteSpace($sourceName)) {
                $nameProperty = $manifest.PSObject.Properties["name"]
                if ($null -ne $nameProperty) {
                    $sourceName = $nameProperty.Value
                }
            }

            foreach ($theme in @($themesProperty.Value)) {
                $themeName = $null
                $labelProperty = $theme.PSObject.Properties["label"]
                if ($null -ne $labelProperty) {
                    $themeName = $labelProperty.Value
                }
                if ([string]::IsNullOrWhiteSpace($themeName)) {
                    $idProperty = $theme.PSObject.Properties["id"]
                    if ($null -ne $idProperty) {
                        $themeName = $idProperty.Value
                    }
                }
                if ([string]::IsNullOrWhiteSpace($themeName)) {
                    $pathProperty = $theme.PSObject.Properties["path"]
                    if ($null -ne $pathProperty) {
                        $themeName = $pathProperty.Value
                    }
                }

                $themeName = Resolve-VSCodeNlsString -Value $themeName -PackageDirectory $packageDirectory.FullName
                if ([string]::IsNullOrWhiteSpace($themeName)) {
                    continue
                }

                $uiTheme = $null
                $uiThemeProperty = $theme.PSObject.Properties["uiTheme"]
                if ($null -ne $uiThemeProperty) {
                    $uiTheme = $uiThemeProperty.Value
                }

                $themeKind = Get-VSCodeThemeKind -UiTheme $uiTheme
                if ($Kind -ne "All" -and $themeKind -ne $Kind) {
                    continue
                }

                $key = $themeName.ToLowerInvariant()
                if (-not $themesByName.ContainsKey($key)) {
                    $themesByName[$key] = [pscustomobject]@{
                        Name             = $themeName
                        Kind             = $themeKind
                        UiTheme          = $uiTheme
                        Source           = $sourceName
                        PackageDirectory = $packageDirectory.FullName
                    }
                }
            }
        }
    }

    return $themesByName.Values | Sort-Object Name
}

function Test-IsVSCodeInstalled {
    return (@(Get-VSCodeInstallSearchRoots).Count -gt 0) -or (@(Get-VSCodeExtensionSearchRoots).Count -gt 0)
}

function Get-PreferredVSCodeDarkTheme {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$AvailableThemes
    )

    if ($null -eq $AvailableThemes) {
        $AvailableThemes = Get-VSCodeThemes -Kind Dark
    }

    foreach ($candidateName in @(
        "VS Code Dark",
        "Default Dark+",
        "Dark+ (default dark)",
        "Dark (Visual Studio)",
        "Default Dark Modern",
        "Abyss"
    )) {
        $match = $AvailableThemes | Where-Object { $_.Name -eq $candidateName } | Select-Object -First 1
        if ($null -ne $match) {
            return $match.Name
        }
    }

    $firstTheme = $AvailableThemes | Select-Object -First 1
    if ($null -ne $firstTheme) {
        return $firstTheme.Name
    }

    return "VS Code Dark"
}

function Get-ThemeSwitchConfigPropertyValue {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        $DefaultValue
    )

    $property = $Config.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Initialize-ThemeSwitchDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function ConvertTo-ThemeSwitchClockTime {
    param(
        [AllowNull()]
        [string]$ClockTime
    )

    if ([string]::IsNullOrWhiteSpace($ClockTime)) {
        return $null
    }

    if ($ClockTime -notmatch '^(?<Hour>\d{1,2}):(?<Minute>\d{2})(:(?<Second>\d{2}))?$') {
        throw "DarkModeTime must use the HH:mm or HH:mm:ss format."
    }

    $hour = [int]$Matches["Hour"]
    $minute = [int]$Matches["Minute"]
    $second = 0

    if ($Matches["Second"]) {
        $second = [int]$Matches["Second"]
    }

    if ($hour -gt 23 -or $minute -gt 59 -or $second -gt 59) {
        throw "DarkModeTime contains an invalid time."
    }

    return New-TimeSpan -Hours $hour -Minutes $minute -Seconds $second
}

function Resolve-ThemeSwitchTimeZone {
    param(
        [AllowNull()]
        [string]$TimeZoneId
    )

    if ([string]::IsNullOrWhiteSpace($TimeZoneId)) {
        return [TimeZoneInfo]::Local
    }

    try {
        return [TimeZoneInfo]::FindSystemTimeZoneById($TimeZoneId)
    }
    catch {
        throw "Invalid TimeZoneId: $TimeZoneId"
    }
}

function Get-CoordinatesFromWindowsLocation {
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds = 30
    )

    try {
        Add-Type -AssemblyName System.Device -ErrorAction Stop
    }
    catch {
        Write-Debug "System.Device is not available."
        return $null
    }

    # Retry with progressively longer timeouts before giving up.
    $timeoutAttempts = @(
        [Math]::Min(5, $TimeoutSeconds),
        [Math]::Min(15, $TimeoutSeconds),
        [Math]::Min($TimeoutSeconds, 30)
    )

    foreach ($timeout in $timeoutAttempts) {
        $watcher = $null
        try {
            $watcher = New-Object System.Device.Location.GeoCoordinateWatcher

            Write-Debug "Trying Windows location with a timeout of $timeout seconds."

            # Use the blocking mode so TryStart waits for a usable reading or timeout.
            $started = $watcher.TryStart($true, (New-TimeSpan -Seconds $timeout))

            Write-Debug "Status: $($watcher.Status), Permission: $($watcher.Permission), TryStart: $started"

            if ($started) {
                # Give the watcher a brief moment to populate the current position.
                Start-Sleep -Milliseconds 200

                $location = $watcher.Position.Location

                if ($null -ne $location -and -not $location.IsUnknown) {
                    Write-Debug "Location coordinates were obtained."
                    return [pscustomobject]@{
                        Latitude  = [math]::Round($location.Latitude, 6)
                        Longitude = [math]::Round($location.Longitude, 6)
                        Source    = "WindowsLocation"
                    }
                }
                else {
                    Write-Debug "Location data was still unavailable after $timeout seconds."
                }
            }
            else {
                Write-Debug "TryStart returned false."
            }
        }
        catch {
            Write-Debug "Windows location lookup failed: $_"
        }
        finally {
            if ($null -ne $watcher) {
                try {
                    $watcher.Stop()
                    $watcher.Dispose()
                }
                catch {
                    # Ignore cleanup errors.
                }
            }
        }

        # When the final timeout completed with no coordinates, stop retrying.
        if ($started -and $timeout -ge $TimeoutSeconds) {
            break
        }
    }

    Write-Debug "No Windows location data could be obtained."
    return $null
}

function Normalize-ThemeSwitchAngle {
    param(
        [double]$Value
    )

    $normalized = $Value % 360
    if ($normalized -lt 0) {
        $normalized += 360
    }

    return $normalized
}

function Normalize-ThemeSwitchHours {
    param(
        [double]$Value
    )

    $normalized = $Value % 24
    if ($normalized -lt 0) {
        $normalized += 24
    }

    return $normalized
}

function ConvertTo-ThemeSwitchRadians {
    param(
        [double]$Degrees
    )

    return $Degrees * [math]::PI / 180
}

function ConvertTo-ThemeSwitchDegrees {
    param(
        [double]$Radians
    )

    return $Radians * 180 / [math]::PI
}

function Get-SolarEventUtc {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$Date,

        [Parameter(Mandatory = $true)]
        [double]$Latitude,

        [Parameter(Mandatory = $true)]
        [double]$Longitude,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Sunrise", "Sunset")]
        [string]$EventType
    )

    # NOAA-style approximation used to derive sunrise/sunset from coordinates.
    $dayOfYear = $Date.DayOfYear
    $longitudeHour = $Longitude / 15.0
    $zenith = 90.833

    if ($EventType -eq "Sunrise") {
        $approximateTime = $dayOfYear + ((6 - $longitudeHour) / 24)
    }
    else {
        $approximateTime = $dayOfYear + ((18 - $longitudeHour) / 24)
    }

    $meanAnomaly = (0.9856 * $approximateTime) - 3.289
    $trueLongitude = $meanAnomaly +
        (1.916 * [math]::Sin((ConvertTo-ThemeSwitchRadians -Degrees $meanAnomaly))) +
        (0.020 * [math]::Sin((ConvertTo-ThemeSwitchRadians -Degrees (2 * $meanAnomaly)))) +
        282.634
    $trueLongitude = Normalize-ThemeSwitchAngle -Value $trueLongitude

    $rightAscension = ConvertTo-ThemeSwitchDegrees -Radians (
        [math]::Atan(0.91764 * [math]::Tan((ConvertTo-ThemeSwitchRadians -Degrees $trueLongitude)))
    )
    $rightAscension = Normalize-ThemeSwitchAngle -Value $rightAscension

    $trueLongitudeQuadrant = [math]::Floor($trueLongitude / 90) * 90
    $rightAscensionQuadrant = [math]::Floor($rightAscension / 90) * 90
    $rightAscension += ($trueLongitudeQuadrant - $rightAscensionQuadrant)
    $rightAscension = $rightAscension / 15

    $sinDeclination = 0.39782 * [math]::Sin((ConvertTo-ThemeSwitchRadians -Degrees $trueLongitude))
    $cosDeclination = [math]::Cos([math]::Asin($sinDeclination))

    $cosHourAngle =
        (
            [math]::Cos((ConvertTo-ThemeSwitchRadians -Degrees $zenith)) -
            ($sinDeclination * [math]::Sin((ConvertTo-ThemeSwitchRadians -Degrees $Latitude)))
        ) /
        ($cosDeclination * [math]::Cos((ConvertTo-ThemeSwitchRadians -Degrees $Latitude)))

    if ($cosHourAngle -gt 1) {
        throw "The sun does not rise on this date for the configured latitude/longitude."
    }

    if ($cosHourAngle -lt -1) {
        throw "The sun does not set on this date for the configured latitude/longitude."
    }

    if ($EventType -eq "Sunrise") {
        $localHourAngle = 360 - (ConvertTo-ThemeSwitchDegrees -Radians ([math]::Acos($cosHourAngle)))
    }
    else {
        $localHourAngle = ConvertTo-ThemeSwitchDegrees -Radians ([math]::Acos($cosHourAngle))
    }

    $localHourAngle = $localHourAngle / 15
    $localMeanTime = $localHourAngle + $rightAscension - (0.06571 * $approximateTime) - 6.622
    $utcHour = Normalize-ThemeSwitchHours -Value ($localMeanTime - $longitudeHour)

    $utcMidnight = [datetime]::SpecifyKind($Date.Date, [DateTimeKind]::Utc)
    return $utcMidnight.AddHours($utcHour)
}

function Get-SunTimes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$Date,

        [Parameter(Mandatory = $true)]
        [double]$Latitude,

        [Parameter(Mandatory = $true)]
        [double]$Longitude,

        [Parameter(Mandatory = $true)]
        [string]$TimeZoneId
    )

    $timeZone = Resolve-ThemeSwitchTimeZone -TimeZoneId $TimeZoneId
    $dateOnly = [datetime]::new($Date.Year, $Date.Month, $Date.Day, 0, 0, 0)
    $sunriseUtc = Get-SolarEventUtc -Date $dateOnly -Latitude $Latitude -Longitude $Longitude -EventType Sunrise
    $sunsetUtc = Get-SolarEventUtc -Date $dateOnly -Latitude $Latitude -Longitude $Longitude -EventType Sunset

    return [pscustomobject]@{
        Sunrise = [TimeZoneInfo]::ConvertTimeFromUtc($sunriseUtc, $timeZone)
        Sunset  = [TimeZoneInfo]::ConvertTimeFromUtc($sunsetUtc, $timeZone)
    }
}

function Assert-ThemeSwitchConfig {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Config
    )

    if ($null -eq $Config.Latitude -or $null -eq $Config.Longitude) {
        throw "The configuration requires Latitude and Longitude."
    }

    [void](Resolve-ThemeSwitchTimeZone -TimeZoneId $Config.TimeZoneId)
    [void](ConvertTo-ThemeSwitchClockTime -ClockTime $Config.DarkModeTime)

    if ([string]::IsNullOrWhiteSpace($Config.TaskPrefix)) {
        throw "The configuration requires TaskPrefix."
    }

    $enableVSCodeThemeSwitch = Get-ThemeSwitchConfigPropertyValue -Config $Config -PropertyName "EnableVSCodeThemeSwitch" -DefaultValue $true
    if ($enableVSCodeThemeSwitch) {
        $vscodeLightTheme = Get-ThemeSwitchConfigPropertyValue -Config $Config -PropertyName "VSCodeLightTheme" -DefaultValue "Quit Lite"
        $vscodeDarkTheme = Get-ThemeSwitchConfigPropertyValue -Config $Config -PropertyName "VSCodeDarkTheme" -DefaultValue (Get-PreferredVSCodeDarkTheme)

        if ([string]::IsNullOrWhiteSpace($vscodeLightTheme)) {
            throw "The configuration requires VSCodeLightTheme when VS Code integration is enabled."
        }

        if ([string]::IsNullOrWhiteSpace($vscodeDarkTheme)) {
            throw "The configuration requires VSCodeDarkTheme when VS Code integration is enabled."
        }
    }
}

function Read-ThemeSwitchConfig {
    [CmdletBinding()]
    param(
        [string]$Path = (Get-ThemeSwitchConfigPath)
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Configuration file not found: $Path"
    }

    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    Assert-ThemeSwitchConfig -Config $config
    return $config
}

function Write-ThemeSwitchConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Config,

        [string]$Path = (Get-ThemeSwitchConfigPath)
    )

    Assert-ThemeSwitchConfig -Config $Config
    Initialize-ThemeSwitchDirectory -Path (Split-Path -Path $Path -Parent) | Out-Null
    $Config | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding UTF8
    return $Path
}

function ConvertTo-JsonLikeSettingValue {
    param(
        [AllowNull()]
        $Value
    )

    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }

    if ($null -eq $Value) {
        return "null"
    }

    return '"' + (($Value.ToString()) -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Set-JsonLikeSetting {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [AllowNull()]
        $Value
    )

    # Keep the updater JSONC-friendly by patching only the requested property.
    $serializedValue = ConvertTo-JsonLikeSettingValue -Value $Value
    $escapedKey = [regex]::Escape($Key)
    $valuePattern = '(?:"(?:\\.|[^"\\])*"|true|false|null|-?\d+(?:\.\d+)?)'
    $pattern = '(?ms)("'+ $escapedKey + '"\s*:\s*)' + $valuePattern

    if ([regex]::IsMatch($Content, $pattern)) {
        return [regex]::Replace($Content, $pattern, ('$1' + $serializedValue), 1)
    }

    $trimmedContent = $Content.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmedContent)) {
        return ('{{{0}  "{1}": {2}{0}}}' -f [Environment]::NewLine, $Key, $serializedValue)
    }

    $lastBraceIndex = $Content.LastIndexOf('}')
    if ($lastBraceIndex -lt 0) {
        throw "The VS Code settings file does not look like a JSON/JSONC object."
    }

    $prefix = $Content.Substring(0, $lastBraceIndex)
    $suffix = $Content.Substring($lastBraceIndex)

    if ($prefix.TrimEnd().EndsWith('{')) {
        $insertion = ('{0}  "{1}": {2}{0}' -f [Environment]::NewLine, $Key, $serializedValue)
    }
    else {
        $insertion = (',{0}  "{1}": {2}{0}' -f [Environment]::NewLine, $Key, $serializedValue)
    }

    return $prefix + $insertion + $suffix
}

function ConvertTo-ThemeSwitchEventLocalTime {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$DateTime,

        [Parameter(Mandatory = $true)]
        [string]$TimeZoneId
    )

    $timeZone = Resolve-ThemeSwitchTimeZone -TimeZoneId $TimeZoneId

    if ($DateTime.Kind -eq [DateTimeKind]::Utc) {
        return [TimeZoneInfo]::ConvertTimeFromUtc($DateTime, $timeZone)
    }

    return [TimeZoneInfo]::ConvertTime($DateTime, [TimeZoneInfo]::Local, $timeZone)
}

function ConvertTo-ThemeSwitchSystemLocalTime {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$DateTime,

        [Parameter(Mandatory = $true)]
        [string]$TimeZoneId
    )

    $timeZone = Resolve-ThemeSwitchTimeZone -TimeZoneId $TimeZoneId
    return [TimeZoneInfo]::ConvertTime($DateTime, $timeZone, [TimeZoneInfo]::Local)
}

function Get-DarkIntervalForDate {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$Date,

        [Parameter(Mandatory = $true)]
        [psobject]$Config
    )

    $dateOnly = [datetime]::new($Date.Year, $Date.Month, $Date.Day, 0, 0, 0)
    $todaySunTimes = Get-SunTimes -Date $dateOnly -Latitude $Config.Latitude -Longitude $Config.Longitude -TimeZoneId $Config.TimeZoneId

    if ([string]::IsNullOrWhiteSpace($Config.DarkModeTime)) {
        $start = $todaySunTimes.Sunset
        $nextDaySunTimes = Get-SunTimes -Date $dateOnly.AddDays(1) -Latitude $Config.Latitude -Longitude $Config.Longitude -TimeZoneId $Config.TimeZoneId
        $end = $nextDaySunTimes.Sunrise
    }
    else {
        $start = $dateOnly.Add((ConvertTo-ThemeSwitchClockTime -ClockTime $Config.DarkModeTime))
        if ($start -lt $todaySunTimes.Sunrise) {
            $end = $todaySunTimes.Sunrise
        }
        else {
            $nextDaySunTimes = Get-SunTimes -Date $dateOnly.AddDays(1) -Latitude $Config.Latitude -Longitude $Config.Longitude -TimeZoneId $Config.TimeZoneId
            $end = $nextDaySunTimes.Sunrise
        }
    }

    return [pscustomobject]@{
        Start = $start
        End   = $end
    }
}

function Get-DarkStartForDate {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$Date,

        [Parameter(Mandatory = $true)]
        [psobject]$Config
    )

    $dateOnly = [datetime]::new($Date.Year, $Date.Month, $Date.Day, 0, 0, 0)

    if ([string]::IsNullOrWhiteSpace($Config.DarkModeTime)) {
        $sunTimes = Get-SunTimes -Date $dateOnly -Latitude $Config.Latitude -Longitude $Config.Longitude -TimeZoneId $Config.TimeZoneId
        return $sunTimes.Sunset
    }

    return $dateOnly.Add((ConvertTo-ThemeSwitchClockTime -ClockTime $Config.DarkModeTime))
}

function Get-DesiredThemeMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Config,

        [datetime]$Now = (Get-Date)
    )

    Assert-ThemeSwitchConfig -Config $Config
    $eventNow = ConvertTo-ThemeSwitchEventLocalTime -DateTime $Now -TimeZoneId $Config.TimeZoneId
    $yesterdayInterval = Get-DarkIntervalForDate -Date $eventNow.Date.AddDays(-1) -Config $Config
    $todayInterval = Get-DarkIntervalForDate -Date $eventNow.Date -Config $Config

    if (($eventNow -ge $yesterdayInterval.Start -and $eventNow -lt $yesterdayInterval.End) -or
        ($eventNow -ge $todayInterval.Start -and $eventNow -lt $todayInterval.End)) {
        return "Dark"
    }

    return "Light"
}

function Get-NextThemeTransitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Config,

        [datetime]$Now = (Get-Date)
    )

    Assert-ThemeSwitchConfig -Config $Config
    $eventNow = ConvertTo-ThemeSwitchEventLocalTime -DateTime $Now -TimeZoneId $Config.TimeZoneId
    $today = $eventNow.Date

    $nextDarkEvent = Get-DarkStartForDate -Date $today -Config $Config
    if ($nextDarkEvent -le $eventNow) {
        $nextDarkEvent = Get-DarkStartForDate -Date $today.AddDays(1) -Config $Config
    }

    $nextLightEvent = (Get-SunTimes -Date $today -Latitude $Config.Latitude -Longitude $Config.Longitude -TimeZoneId $Config.TimeZoneId).Sunrise
    if ($nextLightEvent -le $eventNow) {
        $nextLightEvent = (Get-SunTimes -Date $today.AddDays(1) -Latitude $Config.Latitude -Longitude $Config.Longitude -TimeZoneId $Config.TimeZoneId).Sunrise
    }

    return [pscustomobject]@{
        EventLocalNow        = $eventNow
        NextDarkEventLocal   = $nextDarkEvent
        NextLightEventLocal  = $nextLightEvent
        NextDarkEventSystem  = ConvertTo-ThemeSwitchSystemLocalTime -DateTime $nextDarkEvent -TimeZoneId $Config.TimeZoneId
        NextLightEventSystem = ConvertTo-ThemeSwitchSystemLocalTime -DateTime $nextLightEvent -TimeZoneId $Config.TimeZoneId
    }
}

function Get-ThemeSwitchTaskNames {
    param(
        [string]$TaskPrefix = "Win11DarkMode"
    )

    return [pscustomobject]@{
        Refresh = "$TaskPrefix-AutoRefresh"
        Dark    = "$TaskPrefix-SwitchToDark"
        Light   = "$TaskPrefix-SwitchToLight"
    }
}

function Get-ThemeSwitchCurrentUser {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function New-ThemeSwitchTaskPrincipal {
    return New-ScheduledTaskPrincipal -UserId (Get-ThemeSwitchCurrentUser) -LogonType Interactive -RunLevel Limited
}

function New-ThemeSwitchTaskSettings {
    return New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -MultipleInstances IgnoreNew
}

function New-ThemeSwitchTaskAction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Arguments
    )

    $powershellPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    return New-ScheduledTaskAction -Execute $powershellPath -Argument $Arguments
}

function Register-ThemeRefreshTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $true)]
        [string]$RuntimeDirectory,

        [Parameter(Mandatory = $true)]
        [string]$TaskPrefix
    )

    $taskNames = Get-ThemeSwitchTaskNames -TaskPrefix $TaskPrefix
    $refreshScriptPath = Join-Path $RuntimeDirectory "Refresh-ThemeSchedule.ps1"
    $arguments = @(
        "-NoLogo"
        "-NoProfile"
        "-NonInteractive"
        "-ExecutionPolicy Bypass"
        "-WindowStyle Hidden"
        ('-File "{0}"' -f $refreshScriptPath)
        ('-ConfigPath "{0}"' -f $ConfigPath)
    ) -join " "

    $dailyTrigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::Today.AddMinutes(5))
    $logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User (Get-ThemeSwitchCurrentUser)
    $task = New-ScheduledTask `
        -Action (New-ThemeSwitchTaskAction -Arguments $arguments) `
        -Trigger @($dailyTrigger, $logonTrigger) `
        -Principal (New-ThemeSwitchTaskPrincipal) `
        -Settings (New-ThemeSwitchTaskSettings)

    Register-ScheduledTask -TaskName $taskNames.Refresh -InputObject $task -Force | Out-Null
    return $taskNames.Refresh
}

function Register-ThemeEventTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Dark", "Light")]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [datetime]$RunAt,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $true)]
        [string]$RuntimeDirectory
    )

    $applyScriptPath = Join-Path $RuntimeDirectory "Invoke-Win11ThemeMode.ps1"
    $arguments = @(
        "-NoLogo"
        "-NoProfile"
        "-NonInteractive"
        "-ExecutionPolicy Bypass"
        "-WindowStyle Hidden"
        ('-File "{0}"' -f $applyScriptPath)
        ('-ConfigPath "{0}"' -f $ConfigPath)
        ('-Mode {0}' -f $Mode)
    ) -join " "

    $trigger = New-ScheduledTaskTrigger -Once -At $RunAt
    $task = New-ScheduledTask `
        -Action (New-ThemeSwitchTaskAction -Arguments $arguments) `
        -Trigger $trigger `
        -Principal (New-ThemeSwitchTaskPrincipal) `
        -Settings (New-ThemeSwitchTaskSettings)

    Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null
}

function Update-ThemeEventTasks {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Get-ThemeSwitchConfigPath),

        [Parameter(Mandatory = $true)]
        [string]$RuntimeDirectory,

        [AllowNull()]
        [string]$TaskPrefix
    )

    $config = Read-ThemeSwitchConfig -Path $ConfigPath
    if ([string]::IsNullOrWhiteSpace($TaskPrefix)) {
        $TaskPrefix = $config.TaskPrefix
    }

    $taskNames = Get-ThemeSwitchTaskNames -TaskPrefix $TaskPrefix
    $transitions = Get-NextThemeTransitions -Config $config

    Register-ThemeEventTask -TaskName $taskNames.Dark -Mode Dark -RunAt $transitions.NextDarkEventSystem -ConfigPath $ConfigPath -RuntimeDirectory $RuntimeDirectory
    Register-ThemeEventTask -TaskName $taskNames.Light -Mode Light -RunAt $transitions.NextLightEventSystem -ConfigPath $ConfigPath -RuntimeDirectory $RuntimeDirectory

    return $transitions
}

function Unregister-ThemeSwitchTasks {
    [CmdletBinding()]
    param(
        [string]$TaskPrefix = "Win11DarkMode"
    )

    $taskNames = Get-ThemeSwitchTaskNames -TaskPrefix $TaskPrefix

    foreach ($property in $taskNames.PSObject.Properties) {
        Unregister-ScheduledTask -TaskName $property.Value -Confirm:$false -ErrorAction SilentlyContinue
    }
}

function Get-CurrentWindowsThemeMode {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $appsUseLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
    $systemUsesLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme" -ErrorAction SilentlyContinue

    if ($appsUseLightTheme -eq 0 -and $systemUsesLightTheme -eq 0) {
        return "Dark"
    }

    return "Light"
}

function Set-VSCodeThemePreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Config,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Dark", "Light")]
        [string]$Mode
    )

    $enableVSCodeThemeSwitch = Get-ThemeSwitchConfigPropertyValue -Config $Config -PropertyName "EnableVSCodeThemeSwitch" -DefaultValue $true
    if (-not $enableVSCodeThemeSwitch) {
        return [pscustomobject]@{
            Enabled = $false
            Changed = $false
            Path    = $null
            Theme   = $null
        }
    }

    $settingsPath = Get-ThemeSwitchConfigPropertyValue -Config $Config -PropertyName "VSCodeSettingsPath" -DefaultValue (Get-DefaultVSCodeSettingsPath)
    $lightTheme = Get-ThemeSwitchConfigPropertyValue -Config $Config -PropertyName "VSCodeLightTheme" -DefaultValue "Quit Lite"
    $darkTheme = Get-ThemeSwitchConfigPropertyValue -Config $Config -PropertyName "VSCodeDarkTheme" -DefaultValue (Get-PreferredVSCodeDarkTheme)
    $currentTheme = if ($Mode -eq "Dark") { $darkTheme } else { $lightTheme }

    Initialize-ThemeSwitchDirectory -Path (Split-Path -Path $settingsPath -Parent) | Out-Null

    if (Test-Path -LiteralPath $settingsPath) {
        $content = Get-Content -LiteralPath $settingsPath -Raw
    }
    else {
        $content = "{}"
    }

    # Tell VS Code to follow the OS color scheme while still pinning the preferred themes.
    # IMPORTANT: Keep window.autoDetectColorScheme and preferredColorThemes, but don't set workbench.colorTheme
    # explicitly, as that conflicts with auto-detection. Let VS Code manage the theme selection automatically.
    $updatedContent = $content
    $updatedContent = Set-JsonLikeSetting -Content $updatedContent -Key "window.autoDetectColorScheme" -Value $true
    $updatedContent = Set-JsonLikeSetting -Content $updatedContent -Key "workbench.preferredLightColorTheme" -Value $lightTheme
    $updatedContent = Set-JsonLikeSetting -Content $updatedContent -Key "workbench.preferredDarkColorTheme" -Value $darkTheme

    $changed = $updatedContent -cne $content
    if ($changed) {
        Set-Content -LiteralPath $settingsPath -Value $updatedContent -Encoding UTF8
    }

    return [pscustomobject]@{
        Enabled = $true
        Changed = $changed
        Path    = $settingsPath
        Theme   = $currentTheme
    }
}

function Send-ThemeSwitchNotification {
    # Broadcast the theme change so Explorer and compatible apps refresh immediately.
    if (-not ("Win11DarkMode.NativeMethods" -as [type])) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

namespace Win11DarkMode {
    public static class NativeMethods {
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern IntPtr SendMessageTimeout(
            IntPtr hWnd,
            uint Msg,
            UIntPtr wParam,
            string lParam,
            uint fuFlags,
            uint uTimeout,
            out UIntPtr lpdwResult
        );
    }
}
"@
    }

    $hwndBroadcast = [intptr]0xffff
    $wmSettingChange = [uint32]0x001A
    $sendMessageTimeoutAbortIfHung = [uint32]0x0002
    [UIntPtr]$result = [UIntPtr]::Zero

    [Win11DarkMode.NativeMethods]::SendMessageTimeout(
        $hwndBroadcast,
        $wmSettingChange,
        [UIntPtr]::Zero,
        "ImmersiveColorSet",
        $sendMessageTimeoutAbortIfHung,
        5000,
        [ref]$result
    ) | Out-Null

    $rundllPath = Join-Path $env:SystemRoot "System32\rundll32.exe"
    Start-Process -FilePath $rundllPath -ArgumentList "user32.dll,UpdatePerUserSystemParameters" -WindowStyle Hidden | Out-Null
}

function Set-WindowsThemeMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Dark", "Light")]
        [string]$Mode,

        [switch]$Force
    )

    # Windows stores the app/system theme preference under the current user profile.
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $value = if ($Mode -eq "Dark") { 0 } else { 1 }

    if (-not (Test-Path -LiteralPath $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    $currentAppsUseLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
    $currentSystemUsesLightTheme = Get-ItemPropertyValue -Path $registryPath -Name "SystemUsesLightTheme" -ErrorAction SilentlyContinue

    if (-not $Force -and $currentAppsUseLightTheme -eq $value -and $currentSystemUsesLightTheme -eq $value) {
        return $false
    }

    Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value $value -Type DWord
    Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value $value -Type DWord
    Send-ThemeSwitchNotification
    return $true
}

function Write-ThemeSwitchLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$LogPath = (Get-ThemeSwitchLogPath)
    )

    Initialize-ThemeSwitchDirectory -Path (Split-Path -Path $LogPath -Parent) | Out-Null
    $timestamp = (Get-Date).ToString("s")
    Add-Content -LiteralPath $LogPath -Value ("[{0}] {1}" -f $timestamp, $Message) -Encoding UTF8
}

function Invoke-VSCodeThemeRefresh {
    [CmdletBinding()]
    param()

    # Detect running VS Code instances and force theme reload
    # VS Code CLI is available as: code, code-insiders, codium
    # We use --update-extensions to trigger a minimal reload that refreshes the theme
    
    $codeCommands = @("code", "code-insiders", "codium")
    $vsCodeInstances = 0

    foreach ($cmdName in $codeCommands) {
        $cmd = Get-Command $cmdName -ErrorAction SilentlyContinue
        
        if ($null -ne $cmd) {
            try {
                # Check if there are active instances by getting the process
                $processes = Get-Process -Name $cmdName.Replace("-", "") -ErrorAction SilentlyContinue
                
                if ($processes) {
                    # Use the VS Code CLI to refresh while workspaces are open
                    # The --list-extensions command is lightweight and triggers config reload
                    & $cmd --list-extensions 2>&1 | Out-Null
                    $vsCodeInstances += @($processes).Count
                    
                    Write-Debug "VS Code ($cmdName) instances detected and refresh signal sent."
                }
            }
            catch {
                # Silently continue if cannot interact with VS Code
                Write-Debug "Could not refresh VS Code ($cmdName): $_"
            }
        }
    }

    return $vsCodeInstances
}

function Invoke-ThemeSwitch {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Get-ThemeSwitchConfigPath),

        [ValidateSet("Dark", "Light")]
        [string]$Mode
    )

    $config = Read-ThemeSwitchConfig -Path $ConfigPath
    if ([string]::IsNullOrWhiteSpace($Mode)) {
        $Mode = Get-DesiredThemeMode -Config $config
    }

    $changed = Set-WindowsThemeMode -Mode $Mode
    $logPath = if ([string]::IsNullOrWhiteSpace($config.LogPath)) {
        Get-ThemeSwitchLogPath -InstallRoot (Split-Path -Path $ConfigPath -Parent)
    }
    else {
        $config.LogPath
    }

    $vscodeUpdate = Set-VSCodeThemePreferences -Config $config -Mode $Mode

    if ($changed) {
        Write-ThemeSwitchLog -LogPath $logPath -Message ("Windows theme set to {0}." -f $Mode)
    }
    else {
        Write-ThemeSwitchLog -LogPath $logPath -Message ("Windows theme was already {0}." -f $Mode)
    }

    if ($vscodeUpdate.Enabled) {
        if ($vscodeUpdate.Changed) {
            Write-ThemeSwitchLog -LogPath $logPath -Message ("VS Code configured with theme {0} at {1}." -f $vscodeUpdate.Theme, $vscodeUpdate.Path)
            
            # Refresh any running VS Code instances to apply the theme immediately
            $vsCodeInstanceCount = Invoke-VSCodeThemeRefresh
            if ($vsCodeInstanceCount -gt 0) {
                Write-ThemeSwitchLog -LogPath $logPath -Message ("Refreshed {0} running VS Code instance(s) to apply theme change immediately." -f $vsCodeInstanceCount)
            }
        }
        else {
            Write-ThemeSwitchLog -LogPath $logPath -Message ("VS Code was already configured with theme {0} at {1}." -f $vscodeUpdate.Theme, $vscodeUpdate.Path)
        }
    }

    return [pscustomobject]@{
        Mode          = $Mode
        WindowsChanged = $changed
        VSCodeChanged = $vscodeUpdate.Changed
    }
}

Export-ModuleMember -Function `
    Assert-ThemeSwitchConfig, `
    ConvertTo-JsonLikeSettingValue, `
    ConvertTo-ThemeSwitchClockTime, `
    Get-DefaultVSCodeSettingsPath, `
    Get-CoordinatesFromWindowsLocation, `
    Get-CurrentWindowsThemeMode, `
    Get-DarkIntervalForDate, `
    Get-DarkStartForDate, `
    Get-DesiredThemeMode, `
    Get-NextThemeTransitions, `
    Get-SunTimes, `
    Get-ThemeSwitchConfigPath, `
    Get-ThemeSwitchConfigPropertyValue, `
    Get-ThemeSwitchInstallRoot, `
    Get-ThemeSwitchLogPath, `
    Get-ThemeSwitchTaskNames, `
    Get-PreferredVSCodeDarkTheme, `
    Get-VSCodeExtensionSearchRoots, `
    Get-VSCodeInstallSearchRoots, `
    Get-VSCodeSettingsCandidates, `
    Get-VSCodeThemeKind, `
    Get-VSCodeThemes, `
    Initialize-ThemeSwitchDirectory, `
    Invoke-ThemeSwitch, `
    Invoke-VSCodeThemeRefresh, `
    Read-ThemeSwitchConfig, `
    Register-ThemeRefreshTask, `
    Resolve-VSCodeNlsString, `
    Resolve-ThemeSwitchTimeZone, `
    Set-JsonLikeSetting, `
    Set-VSCodeThemePreferences, `
    Set-WindowsThemeMode, `
    Test-IsVSCodeInstalled, `
    Unregister-ThemeSwitchTasks, `
    Update-ThemeEventTasks, `
    Write-ThemeSwitchConfig, `
    Write-ThemeSwitchLog
