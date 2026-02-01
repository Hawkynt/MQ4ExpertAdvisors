<#
.SYNOPSIS
    MetaTrader 4 Parameter Optimizer for Expert Advisors.
.DESCRIPTION
    Builds an EA, extracts optimization parameters from source comments,
    and runs MT4's native genetic optimizer for efficient parameter search.

    Optimization hints are specified in EA source comments using the format:
    input double MyParam = 3.5;  // Description [OPT:min,max,step]

    Examples:
    input double StopATR = 3.5;  // Stop multiplier [OPT:2.0,5.0,0.5]
    input int Period = 14;       // MA Period [OPT:10,30,2]

    Uses MT4's built-in genetic algorithm for fast optimization.
.PARAMETER Expert
    Name of the Expert Advisor to optimize (without .mq4 extension)
.PARAMETER Symbol
    Trading symbol to optimize for (default: from config)
.PARAMETER Period
    Chart timeframe (default: from config)
.PARAMETER FromDate
    Backtest start date (default: from config)
.PARAMETER ToDate
    Backtest end date (default: from config)
.PARAMETER Model
    Testing model: 0=Every tick, 1=Control points, 2=Open prices (default: 1)
.PARAMETER Genetic
    Use genetic algorithm (default: true). Set to false for exhaustive search.
.PARAMETER Criterion
    Optimization criterion: 0=Balance, 1=ProfitFactor, 2=ExpectedPayoff,
    3=MaxDrawdownPct, 4=DrawdownPct (default: 0)
.PARAMETER ExpertParams
    Additional fixed parameters (semicolon-separated key=value pairs)
.EXAMPLE
    .\BuildAndOptimize.ps1 -Expert "AdaptiveRegimeTrader" -Symbol "EURUSD"
    .\BuildAndOptimize.ps1 -Expert "AdaptiveRegimeTrader" -Genetic $false
    .\BuildAndOptimize.ps1 -Expert "AdaptiveRegimeTrader" -Criterion 1
#>

param(
    [string]$Expert = "AdaptiveRegimeTrader",
    [string]$Symbol,
    [string]$Period,
    [string]$FromDate,
    [string]$ToDate,
    [int]$Model = 1,  # 0=Every tick, 1=Control points, 2=Open prices
    [bool]$Genetic = $true,
    [int]$Criterion = 0,  # 0=Balance, 1=ProfitFactor, 2=ExpectedPayoff, 3=MaxDD, 4=DD%
    [string]$ExpertParams = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ExpertsDir = Join-Path $ProjectRoot "Experts"
$ConfigFile = Join-Path $ScriptDir "BuildAndTest.ini"
$ReportsDir = Join-Path $ProjectRoot "TestReports"

# Period mapping (name to MT4 minute value for lastparameters.ini)
$PeriodMinutes = @{
    "M1" = 1; "M5" = 5; "M15" = 15; "M30" = 30
    "H1" = 60; "H4" = 240; "D1" = 1440; "W1" = 10080; "MN" = 43200
}

function Write-Header {
    param([string]$Text)
    $line = "=" * 60
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "OPTIMIZE" { "Magenta" }
        "BEST" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Read-IniFile {
    param([string]$Path)

    $ini = @{}
    $section = ""

    if (-not (Test-Path $Path)) {
        throw "Config file not found: $Path"
    }

    foreach ($line in Get-Content $Path) {
        $line = $line.Trim()
        if ($line -match '^\[(.+)\]$') {
            $section = $Matches[1]
            $ini[$section] = @{}
        } elseif ($line -match '^([^;=]+)=(.*)$' -and $section) {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            $ini[$section][$key] = $value
        }
    }
    return $ini
}

function Find-TerminalID {
    param([string]$AppDataRoot)

    if (-not (Test-Path $AppDataRoot)) { return $null }

    $folders = Get-ChildItem -Path $AppDataRoot -Directory -ErrorAction SilentlyContinue
    if ($folders -and $folders.Count -gt 0) {
        $terminalFolders = $folders | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }
        if ($terminalFolders) {
            $withExperts = $terminalFolders | Where-Object {
                Test-Path (Join-Path $_.FullName "MQL4\Experts")
            }
            if ($withExperts) {
                return $withExperts | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            }
            return $terminalFolders | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
    }
    return $null
}

function ConvertTo-UnixTimestamp {
    param([string]$DateString)
    $date = [DateTime]::ParseExact($DateString, "yyyy.MM.dd", $null)
    return [int][double]::Parse((Get-Date $date -UFormat %s))
}

function Parse-OptimizationHints {
    param([string]$SourceFile)

    $params = @()
    $content = Get-Content $SourceFile

    foreach ($line in $content) {
        # Match: input <type> <name> = <value>; // <description> [OPT:min,max,step]
        # Supports int, double, bool, and enum types (ENUM_*)
        if ($line -match 'input\s+(\w+)\s+(\w+)\s*=\s*([^;]+);\s*//.*\[OPT:([0-9.-]+),([0-9.-]+),([0-9.-]+)\]') {
            # Save matches before any nested -match calls overwrite $Matches
            $type = $Matches[1]
            $name = $Matches[2]
            $default = $Matches[3].Trim()
            $min = [double]$Matches[4]
            $max = [double]$Matches[5]
            $step = [double]$Matches[6]

            # Map enum types to int for MT4 optimizer
            if ($type -match '^ENUM_') {
                $type = "int"
            }
            $params += @{
                Name = $name
                Type = $type
                Default = $default
                Min = $min
                Max = $max
                Step = $step
            }
        }
    }

    return $params
}

function Generate-ParameterFile {
    param(
        [array]$OptParams,
        [string]$FixedParams,
        [string]$OutputPath
    )

    $lines = @()
    $lines += "<inputs>"

    # Add fixed parameters first
    if ($FixedParams) {
        foreach ($pair in $FixedParams.Split(';', [StringSplitOptions]::RemoveEmptyEntries)) {
            $parts = $pair.Split('=', 2)
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                $lines += "$key=$value"
                $lines += "$key,F=0"
                $lines += "$key,1=$value"
                $lines += "$key,2=0"
                $lines += "$key,3=$value"
            }
        }
    }

    # Add optimization parameters with ranges
    foreach ($param in $OptParams) {
        $name = $param.Name
        $default = $param.Default
        $min = $param.Min
        $max = $param.Max
        $step = $param.Step

        # Format values based on type
        if ($param.Type -eq "int") {
            $min = [int]$min
            $max = [int]$max
            $step = [int]$step
        }

        $lines += "$name=$default"
        $lines += "$name,F=1"       # F=1 means optimize this parameter
        $lines += "$name,1=$min"    # Start value
        $lines += "$name,2=$step"   # Step value
        $lines += "$name,3=$max"    # Stop value
    }

    $lines += "</inputs>"

    $content = $lines -join "`r`n"
    [System.IO.File]::WriteAllText($OutputPath, $content, [System.Text.Encoding]::ASCII)
}

function Parse-OptimizationReport {
    param([string]$ReportPath)

    if (-not (Test-Path $ReportPath)) { return @() }

    $html = Get-Content $ReportPath -Raw -Encoding Default
    $results = @()

    # MT4 optimization report format (German):
    # <tr><td title="Param1=val1; Param2=val2; ...">PassNum</td><td>Profit</td><td>Trades</td><td>PF</td><td>Payoff</td><td>DD$</td><td>DD%</td></tr>
    # The parameters are in the title attribute, not a separate column
    $tablePattern = '<tr[^>]*>\s*<td\s+title="([^"]+)">(\d+)</td>\s*<td[^>]*>([^<]*)</td>\s*<td[^>]*>([^<]*)</td>\s*<td[^>]*>([^<]*)</td>\s*<td[^>]*>([^<]*)</td>\s*<td[^>]*>([^<]*)</td>\s*<td[^>]*>([^<]*)</td>'

    $regMatches = [regex]::Matches($html, $tablePattern)

    foreach ($m in $regMatches) {
        $inputsRaw = $m.Groups[1].Value.Trim()

        # Parse individual parameters from title attribute (format: "Param1=value1; Param2=value2; ...")
        $params = @{}
        foreach ($pair in $inputsRaw.Split(';')) {
            $pair = $pair.Trim()
            if ($pair -match '^([^=]+)=(.*)$') {
                $params[$Matches[1].Trim()] = $Matches[2].Trim()
            }
        }

        # Parse numeric values, handling German decimal format (comma as decimal separator)
        $profitStr = $m.Groups[3].Value.Trim() -replace '[^\d.,-]', ''
        $profitStr = $profitStr -replace ',', '.'
        $tradesStr = $m.Groups[4].Value.Trim() -replace '[^\d]', ''
        $pfStr = $m.Groups[5].Value.Trim() -replace ',', '.'
        $payoffStr = $m.Groups[6].Value.Trim() -replace ',', '.'
        $ddDollarStr = $m.Groups[7].Value.Trim() -replace ',', '.'
        $ddPctStr = $m.Groups[8].Value.Trim() -replace ',', '.'

        $results += @{
            Pass = [int]$m.Groups[2].Value
            Profit = [double]($profitStr -replace '[^\d.-]', '')
            TotalTrades = [int]$tradesStr
            ProfitFactor = [double]($pfStr -replace '[^\d.]', '')
            ExpectedPayoff = [double]($payoffStr -replace '[^\d.-]', '')
            DrawdownDollars = [double]($ddDollarStr -replace '[^\d.]', '')
            DrawdownPercent = [double]($ddPctStr -replace '[^\d.]', '')
            Inputs = $inputsRaw
            params = $params
        }
    }

    return $results
}

function Generate-EnhancedOptimizationReport {
    param(
        [array]$Results,
        [hashtable]$Meta,
        [string]$OutputPath
    )

    $templatePath = Join-Path $ScriptDir "OptimizationReportTemplate.html"
    if (-not (Test-Path $templatePath)) {
        Write-Status "Optimization report template not found: $templatePath" "WARN"
        return $false
    }

    $template = Get-Content -Path $templatePath -Raw -Encoding UTF8

    # Build data object
    $data = @{
        meta = $Meta
        results = $Results
    }

    $json = $data | ConvertTo-Json -Depth 10 -Compress
    $html = $template -replace '/\*\{\{REPORT_DATA\}\}\*/\{\}', $json

    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    return $true
}

# ============================================================
# MAIN SCRIPT
# ============================================================

Write-Host ""
Write-Host "  __  __ _____ _  _    ___        _   _           _              " -ForegroundColor Cyan
Write-Host " |  \/  |_   _| || |  / _ \ _ __ | |_(_)_ __ ___ (_)_______ _ __ " -ForegroundColor Cyan
Write-Host " | |\/| | | | | || |_| | | | '_ \| __| | '_ `` _ \| |_  / _ \ '__|" -ForegroundColor Cyan
Write-Host " | |  | | | | |__   _| |_| | |_) | |_| | | | | | | |/ /  __/ |   " -ForegroundColor Cyan
Write-Host " |_|  |_| |_|    |_|  \___/| .__/ \__|_|_| |_| |_|_/___\___|_|   " -ForegroundColor Cyan
Write-Host "                           |_|    Native MT4 Optimizer           " -ForegroundColor Cyan
Write-Host ""

# Load config
Write-Header "CONFIGURATION"

if (-not (Test-Path $ConfigFile)) {
    Write-Status "Config file not found: $ConfigFile" "ERROR"
    exit 1
}

$config = Read-IniFile -Path $ConfigFile
$MT4Terminal = $config["MT4"]["Terminal"]
$MT4TerminalExe = $config["MT4"]["TerminalExe"]
$AppDataRoot = $config["MT4"]["AppDataRoot"]
$TestExpertName = $config["Test"]["ExpertName"]

# Use direct terminal.exe if available, otherwise fall back to Terminal
if (-not $MT4TerminalExe -or -not (Test-Path $MT4TerminalExe)) {
    # Try to find terminal.exe next to the launcher
    $terminalDir = Split-Path $MT4Terminal -Parent
    $MT4TerminalExe = Join-Path $terminalDir "terminal.exe"
}
if (-not (Test-Path $MT4TerminalExe)) {
    Write-Status "terminal.exe not found. Add TerminalExe to config." "ERROR"
    exit 1
}

# Apply defaults from config, allow command-line overrides
if (-not $Symbol) { $Symbol = $config["Test"]["Symbol"] }
if (-not $Period) { $Period = $config["Test"]["Period"] }
if (-not $FromDate) { $FromDate = $config["Test"]["FromDate"] }
if (-not $ToDate) { $ToDate = $config["Test"]["ToDate"] }

$criterionNames = @("Balance", "Profit Factor", "Expected Payoff", "Max Drawdown", "Drawdown %")
$criterionName = $criterionNames[$Criterion]
$geneticMode = if ($Genetic) { "Genetic Algorithm" } else { "Full Search" }

Write-Status "Expert: $Expert"
Write-Status "Symbol: $Symbol | Period: $Period | Model: $Model"
Write-Status "Date Range: $FromDate to $ToDate"
Write-Status "Optimization: $geneticMode | Criterion: $criterionName"

# ============================================================
# STEP 1: BUILD EA
# ============================================================

Write-Header "STEP 1: BUILD EXPERT ADVISOR"

$buildScript = Join-Path $ScriptDir "Build.ps1"
$mq4File = "$Expert.mq4"
Write-Status "Building $Expert.mq4..."
& $buildScript -File $mq4File

if ($LASTEXITCODE -ne 0) {
    Write-Status "Build FAILED" "ERROR"
    exit 1
}

$sourceEx4 = Join-Path $ExpertsDir "$Expert.ex4"
if (-not (Test-Path $sourceEx4)) {
    Write-Status "Compiled EA not found: $sourceEx4" "ERROR"
    exit 1
}

Write-Status "Build completed successfully" "SUCCESS"

# ============================================================
# STEP 2: PARSE OPTIMIZATION HINTS
# ============================================================

Write-Header "STEP 2: PARSE OPTIMIZATION HINTS"

$sourceFile = Join-Path $ProjectRoot "Experts\$Expert.mq4"
if (-not (Test-Path $sourceFile)) {
    Write-Status "Source file not found: $sourceFile" "ERROR"
    exit 1
}

Write-Status "Scanning $Expert.mq4 for [OPT:min,max,step] hints..."
$optParams = Parse-OptimizationHints -SourceFile $sourceFile

if ($optParams.Count -eq 0) {
    Write-Status "No optimization hints found in source file" "WARN"
    Write-Status "Add [OPT:min,max,step] to input parameter comments" "INFO"
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host '  input double StopATR = 3.5;  // Stop multiplier [OPT:2.0,5.0,0.5]' -ForegroundColor Gray
    exit 1
}

# Calculate total combinations
$totalCombos = 1
foreach ($param in $optParams) {
    $steps = [Math]::Floor(($param.Max - $param.Min) / $param.Step) + 1
    $totalCombos *= $steps
    Write-Status "  $($param.Name) = $($param.Default) [$($param.Min) to $($param.Max) step $($param.Step)] ($steps values)" "OPTIMIZE"
}
Write-Status "Found $($optParams.Count) parameters to optimize" "SUCCESS"
Write-Status "Total possible combinations: $totalCombos" "INFO"

# ============================================================
# STEP 3: FIND TERMINAL & DEPLOY
# ============================================================

Write-Header "STEP 3: DEPLOY TO MT4"

$terminalFolder = Find-TerminalID -AppDataRoot $AppDataRoot
if (-not $terminalFolder) {
    Write-Status "No terminal folder found in: $AppDataRoot" "ERROR"
    exit 1
}

$TerminalID = $terminalFolder.Name
$TempDataDir = $terminalFolder.FullName
Write-Status "Terminal ID: $TerminalID" "SUCCESS"

# Deploy EA
$expertsPath = Join-Path $TempDataDir "MQL4\Experts"
$destEx4 = Join-Path $expertsPath "$TestExpertName.ex4"
Copy-Item -Path $sourceEx4 -Destination $destEx4 -Force
Write-Status "Deployed: $TestExpertName.ex4" "SUCCESS"

# ============================================================
# STEP 4: CONFIGURE OPTIMIZATION
# ============================================================

Write-Header "STEP 4: CONFIGURE OPTIMIZATION"

$testerFolder = Join-Path $TempDataDir "tester"
if (-not (Test-Path $testerFolder)) {
    New-Item -ItemType Directory -Path $testerFolder -Force | Out-Null
}

# Delete old parameter files to ensure clean state
$oldParamFiles = @(
    (Join-Path $testerFolder "$TestExpertName.ini"),
    (Join-Path $testerFolder "$TestExpertName.set")
)
foreach ($oldFile in $oldParamFiles) {
    if (Test-Path $oldFile) {
        Remove-Item $oldFile -Force -ErrorAction SilentlyContinue
    }
}

# Generate fresh parameter file with optimization ranges (.set format for MT4)
$paramSetPath = Join-Path $testerFolder "$TestExpertName.set"
Generate-ParameterFile -OptParams $optParams -FixedParams $ExpertParams -OutputPath $paramSetPath
Write-Status "Created parameter file: $TestExpertName.set" "SUCCESS"

# Configure lastparameters.ini for genetic optimization
$lastParamsPath = Join-Path $testerFolder "lastparameters.ini"
$fromTimestamp = ConvertTo-UnixTimestamp -DateString $FromDate
$toTimestamp = ConvertTo-UnixTimestamp -DateString $ToDate
$periodMinutes = $PeriodMinutes[$Period]
$geneticFlag = if ($Genetic) { 1 } else { 0 }

$lastParamsContent = @"
optimization=1
genetic=$geneticFlag
fitnes=$Criterion
method=$Model
use_date=1
from=$fromTimestamp
to=$toTimestamp
period=$periodMinutes
"@
Set-Content -Path $lastParamsPath -Value $lastParamsContent -Encoding ASCII
Write-Status "Configured optimization settings" "SUCCESS"
Write-Status "  Genetic: $Genetic | Criterion: $criterionName" "INFO"

# Create reports directory
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

# Clean old optimization reports
Get-ChildItem -Path $TempDataDir -Filter "OptimizationReport*.htm" -ErrorAction SilentlyContinue | Remove-Item -Force

# ============================================================
# STEP 5: RUN OPTIMIZATION
# ============================================================

Write-Header "STEP 5: RUN MT4 OPTIMIZATION"

# Check if MT4 is already running
$existingTerminal = Get-Process -Name "terminal" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existingTerminal) {
    Write-Status "MT4 is already running. Please close it first." "ERROR"
    exit 1
}

# Update terminal.ini directly with optimization settings
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportBaseName = "OptimizationReport_${Expert}_${Symbol}_${timestamp}"
$terminalDir = Split-Path $MT4TerminalExe -Parent

# Path to terminal.ini in the data folder
$terminalIniPath = Join-Path $TempDataDir "config\terminal.ini"

if (Test-Path $terminalIniPath) {
    $terminalIniContent = Get-Content $terminalIniPath -Raw

    # Update or create [Tester] section values
    $testerSettings = @{
        "Expert" = "$TestExpertName.ex4"
        "ExpertParameters" = "$TestExpertName.ini"
        "Symbol" = $Symbol
        "Period" = $PeriodMinutes[$Period]
        "Model" = $Model
        "Optimization" = "1"
        "OptimizeParameter" = $Criterion
        "FromDate" = $FromDate
        "ToDate" = $ToDate
        "UseDate" = "1"
        "Visual" = "0"
        "Report" = $reportBaseName
        "ReplaceReport" = "1"
        "ShutdownTerminal" = "1"
    }

    foreach ($key in $testerSettings.Keys) {
        $value = $testerSettings[$key]
        $pattern = "(?m)^$key=.*$"
        if ($terminalIniContent -match $pattern) {
            $terminalIniContent = $terminalIniContent -replace $pattern, "$key=$value"
        } else {
            # Add to [Tester] section if not present
            $terminalIniContent = $terminalIniContent -replace "(?m)(\[Tester\])", "`$1`r`n$key=$value"
        }
    }

    [System.IO.File]::WriteAllText($terminalIniPath, $terminalIniContent, [System.Text.Encoding]::ASCII)
    Write-Status "Updated terminal.ini with optimization settings" "SUCCESS"
} else {
    Write-Status "terminal.ini not found at $terminalIniPath" "WARN"
}

# Create startup INI in the DATA folder's config (matching BuildAndTest.ps1 approach)
$dataConfigDir = Join-Path $TempDataDir "config"
if (-not (Test-Path $dataConfigDir)) {
    New-Item -ItemType Directory -Path $dataConfigDir -Force | Out-Null
}
$startupIniName = "autotest.ini"
$startupIni = Join-Path $dataConfigDir $startupIniName

# MT4 startup config format - matching BuildAndTest.ps1 format
# TestOptimization: "true" to enable optimization
# TestPeriod: uses period NAME (H1), not minutes
$iniContent = @"
; Auto-generated startup configuration for optimization
[Tester]
TestExpert=$TestExpertName
TestExpertParameters=$TestExpertName.set
TestSymbol=$Symbol
TestPeriod=$Period
TestModel=$Model
TestSpread=0
TestOptimization=true
TestDateEnable=true
TestFromDate=$FromDate
TestToDate=$ToDate
TestReport=$reportBaseName
TestReplaceReport=true
TestShutdownTerminal=true
TestVisualEnable=false
"@
[System.IO.File]::WriteAllText($startupIni, $iniContent, [System.Text.Encoding]::ASCII)
Write-Status "Created startup INI: $startupIni" "SUCCESS"

Write-Host ""
Write-Host "  OPTIMIZATION CONFIGURATION:" -ForegroundColor Yellow
Write-Host "       Expert: $TestExpertName" -ForegroundColor Cyan
Write-Host "       Symbol: $Symbol | Period: $Period" -ForegroundColor Cyan
Write-Host "       Model: $Model (0=Every tick, 1=Control points, 2=Open prices)" -ForegroundColor Cyan
Write-Host "       Date: $FromDate to $ToDate" -ForegroundColor Cyan
Write-Host "       Mode: $geneticMode" -ForegroundColor Cyan
Write-Host "       Criterion: $criterionName" -ForegroundColor Cyan
Write-Host "       Parameters: $($optParams.Count) to optimize" -ForegroundColor Cyan
Write-Host "       Combinations: $totalCombos" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
Write-Status "Launching MT4 with optimization enabled..." "INFO"

# Launch MT4 with startup config - matching BuildAndTest.ps1 approach
# Use --minimized flag and pass full path to INI file
$mt4Process = Start-Process -FilePath $MT4Terminal -ArgumentList "--minimized `"$startupIni`"" -PassThru -WindowStyle Minimized
Write-Status "MT4 launched minimized with auto-optimization config" "SUCCESS"

Write-Host ""
Write-Host "  Optimization should auto-start. If not:" -ForegroundColor Yellow
Write-Host "  - Press Ctrl+R to open Strategy Tester" -ForegroundColor White
Write-Host "  - Click 'Start' to begin" -ForegroundColor White
Write-Host "  MT4 will close automatically when done." -ForegroundColor Gray
Write-Host ""

# Wait for MT4 to close
Write-Status "Waiting for optimization to complete..." "INFO"

$lastDot = Get-Date
while ($true) {
    $terminalProcess = Get-Process -Name "terminal" -ErrorAction SilentlyContinue | Select-Object -First 1
    $launcherStillRunning = $mt4Process -and -not $mt4Process.HasExited
    if (-not $launcherStillRunning -and -not $terminalProcess) { break }

    # Progress indicator
    if (((Get-Date) - $lastDot).TotalSeconds -ge 5) {
        Write-Host "." -NoNewline
        $lastDot = Get-Date
    }

    Start-Sleep -Seconds 2
}

Write-Host ""
$duration = ((Get-Date) - $startTime).TotalMinutes
Write-Status "MT4 optimization completed in $([Math]::Round($duration, 1)) minutes" "SUCCESS"

# Clean up startup INI from config folder
if (Test-Path $startupIni) {
    Remove-Item -Path $startupIni -Force -ErrorAction SilentlyContinue
}

# ============================================================
# STEP 6: ANALYZE RESULTS
# ============================================================

Write-Header "STEP 6: ANALYZE RESULTS"

# Search for optimization report in multiple locations
$searchPaths = @(
    $TempDataDir,
    $terminalDir,
    $ReportsDir,
    (Join-Path $TempDataDir "tester"),
    [Environment]::GetFolderPath("MyDocuments")
)

$optimizationReport = $null
$searchPatterns = @("*Optimi*.htm", "*$reportBaseName*.htm", "*_TEST_*.htm")

foreach ($searchPath in $searchPaths) {
    if (-not (Test-Path $searchPath)) { continue }
    foreach ($pattern in $searchPatterns) {
        $reports = Get-ChildItem -Path $searchPath -Filter $pattern -ErrorAction SilentlyContinue |
                   Where-Object { $_.LastWriteTime -gt $startTime } |
                   Sort-Object LastWriteTime -Descending |
                   Select-Object -First 1
        if ($reports) {
            $optimizationReport = $reports.FullName
            Write-Status "Found report: $optimizationReport" "SUCCESS"
            break
        }
    }
    if ($optimizationReport) { break }
}

if (-not $optimizationReport) {
    Write-Status "No optimization report found automatically." "WARN"
    Write-Host ""
    Write-Host "  To save the report manually:" -ForegroundColor Yellow
    Write-Host "  1. In MT4 Strategy Tester, right-click on the Optimization Results tab" -ForegroundColor White
    Write-Host "  2. Select 'Save as Report'" -ForegroundColor White
    Write-Host "  3. Save to: $ReportsDir" -ForegroundColor Cyan
    Write-Host ""

    # Check for cache file as proof optimization ran
    $cacheFile = Join-Path $TempDataDir "tester\caches\$TestExpertName.${Symbol}60.1"
    if (Test-Path $cacheFile) {
        $cacheTime = (Get-Item $cacheFile).LastWriteTime
        if ($cacheTime -gt $startTime) {
            Write-Status "Optimization cache found (optimization did run)" "SUCCESS"
            Write-Status "Cache: $cacheFile" "INFO"
        }
    }
    exit 0
}

Write-Status "Found optimization report: $([System.IO.Path]::GetFileName($optimizationReport))" "SUCCESS"

# Copy report to TestReports
$destReport = Join-Path $ReportsDir "$reportBaseName.htm"
Copy-Item -Path $optimizationReport -Destination $destReport -Force
Write-Status "Copied report to: $destReport" "SUCCESS"

# Parse results
$results = Parse-OptimizationReport -ReportPath $optimizationReport

if ($results.Count -eq 0) {
    Write-Status "Could not parse optimization results" "WARN"
    Write-Status "Check the report manually: $destReport" "INFO"
} else {
    Write-Status "Parsed $($results.Count) optimization passes" "SUCCESS"

    # Sort by the optimization criterion
    $sortedResults = switch ($Criterion) {
        1 { $results | Sort-Object { $_.ProfitFactor } -Descending }
        2 { $results | Sort-Object { $_.ExpectedPayoff } -Descending }
        3 { $results | Sort-Object { $_.DrawdownDollars } }
        4 { $results | Sort-Object { $_.DrawdownPercent } }
        default { $results | Sort-Object { $_.Profit } -Descending }
    }

    # Filter to profitable results with sufficient trades
    $validResults = $sortedResults | Where-Object { $_.TotalTrades -ge 10 }

    if ($validResults.Count -gt 0) {
        $best = $validResults | Select-Object -First 1

        Write-Host ""
        Write-Host "  BEST RESULT (Pass #$($best.Pass)):" -ForegroundColor Green
        Write-Host "  " + ("-" * 50) -ForegroundColor DarkGray
        Write-Host "    Profit: `$$($best.Profit)" -ForegroundColor $(if ($best.Profit -gt 0) { "Green" } else { "Red" })
        Write-Host "    Profit Factor: $($best.ProfitFactor)" -ForegroundColor White
        Write-Host "    Expected Payoff: $($best.ExpectedPayoff)" -ForegroundColor White
        Write-Host "    Total Trades: $($best.TotalTrades)" -ForegroundColor White
        Write-Host "    Max Drawdown: `$$($best.DrawdownDollars) ($($best.DrawdownPercent)%)" -ForegroundColor White
        Write-Host ""
        Write-Host "    Parameters:" -ForegroundColor Cyan
        Write-Host "    $($best.Inputs)" -ForegroundColor Gray
        Write-Host ""

        # Show top 5
        Write-Host "  TOP 5 RESULTS:" -ForegroundColor Cyan
        $rank = 1
        foreach ($r in ($validResults | Select-Object -First 5)) {
            $profitColor = if ($r.Profit -gt 0) { "Green" } else { "Red" }
            Write-Host "    $rank. Profit=`$$($r.Profit), PF=$($r.ProfitFactor), Trades=$($r.TotalTrades)" -ForegroundColor $profitColor
            Write-Host "       $($r.Inputs)" -ForegroundColor Gray
            $rank++
        }

        # Save results to CSV
        $csvPath = Join-Path $ReportsDir "optimization_results_${timestamp}.csv"
        $csvHeader = "Pass,Profit,TotalTrades,ProfitFactor,ExpectedPayoff,DrawdownDollars,DrawdownPercent,Inputs"
        $csvLines = @($csvHeader)
        foreach ($r in $sortedResults) {
            $csvLines += "$($r.Pass),$($r.Profit),$($r.TotalTrades),$($r.ProfitFactor),$($r.ExpectedPayoff),$($r.DrawdownDollars),$($r.DrawdownPercent),`"$($r.Inputs)`""
        }
        $csvLines -join "`r`n" | Out-File $csvPath -Encoding ASCII
        Write-Host ""
        Write-Status "Results saved to: $csvPath" "SUCCESS"

        # Generate enhanced HTML report with charts
        $enhancedReportPath = Join-Path $ReportsDir "${reportBaseName}_Enhanced.html"
        $reportMeta = @{
            expert = $Expert
            symbol = $Symbol
            period = $Period
            fromDate = $FromDate
            toDate = $ToDate
            model = $Model
            criterion = $criterionName
            genetic = $Genetic
            duration = [Math]::Round($duration, 1)
        }

        if (Generate-EnhancedOptimizationReport -Results $sortedResults -Meta $reportMeta -OutputPath $enhancedReportPath) {
            Write-Status "Enhanced report: $enhancedReportPath" "SUCCESS"
        }
    } else {
        Write-Status "No valid results found (need trades >= 10)" "WARN"
    }
}

# ============================================================
# COMPLETE
# ============================================================

Write-Header "OPTIMIZATION COMPLETE"

Write-Status "Expert: $Expert" "INFO"
Write-Status "Symbol: $Symbol | Period: $Period" "INFO"
Write-Status "Mode: $geneticMode" "INFO"
Write-Status "Duration: $([Math]::Round($duration, 1)) minutes" "INFO"
Write-Status "Report: $destReport" "INFO"
Write-Host ""
