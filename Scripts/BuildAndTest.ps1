<#
.SYNOPSIS
    Builds and deploys MQL4 Expert Advisor for testing in existing MT4.

.DESCRIPTION
    Uses an existing MT4 installation with broker data:
    1. Compiles the Expert Advisor
    2. Auto-detects terminal ID from AppData
    3. Deploys EA with configured test name
    4. Updates terminal.ini with test parameters
    5. Launches MT4 and runs backtest automatically (default)
       Or launches MT4 in manual mode with -Manual flag

    Auto mode (default): Creates startup INI file that triggers MT4 to
    automatically run the backtest, save the report, and close.

    Manual mode (-Manual): Launches MT4 and shows instructions for
    manually running the backtest and saving reports.

.PARAMETER Expert
    Name of the Expert Advisor (without extension). Default: AdaptiveTrader

.PARAMETER Symbol
    Trading symbol to test (overrides config)

.PARAMETER Period
    Timeframe (overrides config)

.PARAMETER NoLaunch
    Skip launching MT4 after deployment

.PARAMETER All
    Build all Expert Advisors

.PARAMETER Manual
    Use manual mode instead of auto mode. Shows instructions and waits
    for user to manually run the backtest in MT4.

.EXAMPLE
    .\BuildAndTest.ps1
    # Auto mode: builds, deploys, runs backtest automatically, analyzes report

.EXAMPLE
    .\BuildAndTest.ps1 -Expert "MyEA" -Manual
    # Manual mode: builds, deploys, shows instructions for manual testing

.EXAMPLE
    .\BuildAndTest.ps1 -Expert "MyEA" -Symbol "EURUSD" -Period "M15"
    # Auto mode with custom symbol and period

.EXAMPLE
    .\BuildAndTest.ps1 -NoLaunch
    # Build and deploy only, don't launch MT4
#>

param(
    [string]$Expert = "AdaptiveTrader",
    [string]$Symbol,
    [string]$Period,
    [int]$Model = -1,
    [string]$FromDate,  # Backtest start date (overrides config)
    [string]$ToDate,    # Backtest end date (overrides config)
    [string]$ExpertParams = "",  # Expert parameters (key=value;key2=value2)
    [switch]$NoLaunch = $false,
    [switch]$All = $false,
    [switch]$Manual = $false  # Use manual mode (show instructions, wait for user)
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ExpertsDir = Join-Path $ProjectRoot "Experts"
$ConfigFile = Join-Path $ScriptDir "BuildAndTest.ini"
$ReportsDir = Join-Path $ProjectRoot "TestReports"

# Period mapping (name to MT4 Strategy Tester dropdown index)
# MT4 Tester uses 0-8 index, NOT minute values
$PeriodMap = @{
    "M1" = 0; "M5" = 1; "M15" = 2; "M30" = 3
    "H1" = 4; "H4" = 5; "D1" = 6; "W1" = 7; "MN" = 8
}

# Helper to convert date string to Unix timestamp
function ConvertTo-UnixTimestamp {
    param([string]$DateString)
    $date = [DateTime]::ParseExact($DateString, "yyyy.MM.dd", $null)
    return [int][double]::Parse((Get-Date $date -UFormat %s))
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

function Update-IniSection {
    param(
        [string]$FilePath,
        [string]$Section,
        [hashtable]$Values
    )

    $content = [ordered]@{}
    $currentSection = ""

    if (Test-Path $FilePath) {
        foreach ($line in Get-Content $FilePath) {
            if ($line -match '^\[(.+)\]$') {
                $currentSection = $Matches[1]
                if (-not $content.Contains($currentSection)) {
                    $content[$currentSection] = [ordered]@{}
                }
            } elseif ($line -match '^([^=]+)=(.*)$' -and $currentSection) {
                $content[$currentSection][$Matches[1]] = $Matches[2]
            }
        }
    }

    if (-not $content.Contains($Section)) {
        $content[$Section] = [ordered]@{}
    }
    foreach ($key in $Values.Keys) {
        $content[$Section][$key] = $Values[$key]
    }

    $output = @()
    foreach ($sec in $content.Keys) {
        $output += "[$sec]"
        foreach ($key in $content[$sec].Keys) {
            $output += "$key=$($content[$sec][$key])"
        }
        $output += ""
    }
    Set-Content -Path $FilePath -Value ($output -join "`r`n")
}

# MT4 Report Parsing Functions (inlined from AnalyzeReport.ps1)
function Parse-MT4Report {
    param([string]$Path)

    # Use ArrayList for O(1) append instead of array += which is O(n)
    $events = [System.Collections.ArrayList]::new()
    $meta = @{}
    $meta.params = @{}
    $meta.parameters = ""

    # Read entire file for multi-line parameter parsing
    $fullContent = Get-Content -Path $Path -Raw -Encoding Default

    # Extract parameters (spans multiple lines)
    if ($fullContent -match '(?:Parameters|Parameter)</td><td[^>]*>([\s\S]*?)</td></tr>') {
        $rawParams = $Matches[1] -replace '\s+', ' '
        $meta.parameters = $rawParams.Trim()
        $paramPairs = $rawParams -split ';'
        foreach ($pair in $paramPairs) {
            $pair = $pair.Trim()
            if ($pair -match '^([^=]+)=(.*)$') {
                $meta.params[$Matches[1].Trim()] = $Matches[2].Trim()
            }
        }
    }

    # Process file line by line for other data
    $reader = [System.IO.StreamReader]::new($Path, [System.Text.Encoding]::Default)
    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            # Extract order events from table rows
            if ($line -match '<tr[^>]*>\s*<td>(\d+)</td>') {
                $cells = [regex]::Matches($line, '<td[^>]*>([^<]*)</td>')
                if ($cells.Count -ge 8) {
                    $type = $cells[2].Groups[1].Value.ToLower()
                    if ($type -match '^(buy|sell|modify|close|s/l|t/p)$') {
                        $profit = $null
                        $balance = $null
                        if ($cells.Count -ge 10 -and $cells[8].Groups[1].Value -ne '') {
                            $profit = [double]$cells[8].Groups[1].Value
                            $balance = [double]$cells[9].Groups[1].Value
                        }
                        [void]$events.Add(@{
                            n = [int]$cells[0].Groups[1].Value
                            t = $cells[1].Groups[1].Value.Trim()
                            y = $type
                            o = [int]$cells[3].Groups[1].Value
                            v = [double]$cells[4].Groups[1].Value
                            p = [double]$cells[5].Groups[1].Value
                            s = [double]$cells[6].Groups[1].Value
                            k = [double]$cells[7].Groups[1].Value
                            r = $profit
                            b = $balance
                        })
                    }
                }
            }
            # Extract metadata - use 'if' not 'elseif' since multiple fields can be on same line
            if ($line -match '<title>Strategy Tester:\s*([^<]+)</title>') {
                $meta.expert = $Matches[1].Trim()
            }
            if ($line -match 'Symbol</td><td[^>]*>([^<]+)') {
                $meta.symbol = $Matches[1].Trim()
            }
            if ($line -match '(?:Period|Periode)</td><td[^>]*>([^<]+)') {
                $meta.period = $Matches[1].Trim()
            }
            if ($line -match '(?:Model|Modell)</td><td[^>]*>([^<]+)') {
                $meta.model = ($Matches[1] -replace '<[^>]+>', '').Trim()
            }
            # Extract date range from period line (e.g., "2024.01.16 22:05 - 2025.12.31 21:00")
            if ($line -match '(\d{4}\.\d{2}\.\d{2}\s+\d{2}:\d{2})\s*-\s*(\d{4}\.\d{2}\.\d{2}\s+\d{2}:\d{2})') {
                $meta.startDate = $Matches[1]
                $meta.endDate = $Matches[2]
            }
            # Test metadata - can be on same line
            if ($line -match '(?:Bars in test|Getestete Kerzen)</td><td[^>]*>([0-9]+)') {
                $meta.bars = [int]$Matches[1]
            }
            if ($line -match '(?:Ticks modelled|Modellierte Ticks)</td><td[^>]*>([0-9]+)') {
                $meta.ticks = [int]$Matches[1]
            }
            if ($line -match '(?:Modelling quality|Modellierungsqualit)[^<]*</td><td[^>]*>([^<]+)') {
                $meta.quality = $Matches[1].Trim()
            }
            if ($line -match '(?:Mismatched charts errors|Fehler in Chartanpassung)</td><td[^>]*>([0-9]+)') {
                $meta.errors = [int]$Matches[1]
            }
            if ($line -match 'Spread</td><td[^>]*>([^<]+)') {
                $meta.spread = $Matches[1].Trim()
            }
            if ($line -match '(?:Initial Deposit|Urspr.ngliche Einzahlung)</td><td[^>]*>([0-9.,]+)') {
                $meta.deposit = [double]($Matches[1] -replace ',', '')
            }
            # MT4 pre-calculated statistics (use these for accuracy)
            if ($line -match '(?:Total net profit|Nettoprofit gesamt)</td><td[^>]*>([0-9.,\-]+)') {
                $meta.netProfit = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match '(?:Gross profit|Bruttoprofit)</td><td[^>]*>([0-9.,]+)') {
                $meta.grossProfit = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match '(?:Gross loss|Bruttoverlust)</td><td[^>]*>([0-9.,\-]+)') {
                $meta.grossLoss = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match '(?:Profit factor|Profitfaktor)</td><td[^>]*>([0-9.,]+)') {
                $meta.profitFactor = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match '(?:Expected payoff|Erwartetes Ergebnis)</td><td[^>]*>([0-9.,\-]+)') {
                $meta.expectedPayoff = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match '(?:Absolute drawdown|Absoluter R.ckgang)</td><td[^>]*>([0-9.,]+)') {
                $meta.absDrawdown = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match '(?:Maximal drawdown|Maximaler R.ckgang)</td><td[^>]*>([0-9.,]+)\s*\(([0-9.,]+)%\)') {
                $meta.maxDrawdown = [double]($Matches[1] -replace ',', '')
                $meta.maxDrawdownPct = [double]($Matches[2] -replace ',', '')
            }
            if ($line -match '(?:Total trades|Anzahl an Trades)</td><td[^>]*>([0-9]+)') {
                $meta.totalTrades = [int]$Matches[1]
            }
            if ($line -match '(?:Short positions|Sell-Positionen)[^<]*</td><td[^>]*>([0-9]+)\s*\(([0-9.,]+)%\)') {
                $meta.shortTrades = [int]$Matches[1]
                $meta.shortWinRate = [double]($Matches[2] -replace ',', '.')
            }
            if ($line -match '(?:Long positions|Buy-Positionen)[^<]*</td><td[^>]*>([0-9]+)\s*\(([0-9.,]+)%\)') {
                $meta.longTrades = [int]$Matches[1]
                $meta.longWinRate = [double]($Matches[2] -replace ',', '.')
            }
            if ($line -match '(?:Profit trades|Gewonne Trades)[^<]*</td><td[^>]*>([0-9]+)\s*\(([0-9.,]+)%\)') {
                $meta.winCount = [int]$Matches[1]
                $meta.winRate = [double]($Matches[2] -replace ',', '.')
            }
            if ($line -match '(?:Loss trades|Verlorene Trades)[^<]*</td><td[^>]*>([0-9]+)\s*\(([0-9.,]+)%\)') {
                $meta.lossCount = [int]$Matches[1]
            }
            if ($line -match '(?:Largest.*profit trade|Gewinntrade)</td><td[^>]*>([0-9.,]+)') {
                if (-not $meta.largestWin) { $meta.largestWin = [double]($Matches[1] -replace ',', '') }
            }
            if ($line -match '(?:Largest.*loss trade|Verlusttrade)</td><td[^>]*>([0-9.,\-]+)') {
                if (-not $meta.largestLoss) { $meta.largestLoss = [double]($Matches[1] -replace ',', '') }
            }
            if ($line -match '(?:Average.*profit trade|Durchschnitt</td><td[^>]*></td><td>Gewinntrade)</td><td[^>]*>([0-9.,]+)') {
                $meta.avgWin = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match '(?:Maximum consecutive wins|Gewinntrades in Folge)[^<]*</td><td[^>]*>([0-9]+)\s*\(([0-9.,\-]+)\)') {
                $meta.maxConsecWins = [int]$Matches[1]
                $meta.maxConsecWinsProfit = [double]($Matches[2] -replace ',', '')
            }
            if ($line -match '(?:Maximum consecutive losses|Verlusttrades in Folge)[^<]*</td><td[^>]*>([0-9]+)\s*\(([0-9.,\-]+)\)') {
                $meta.maxConsecLosses = [int]$Matches[1]
                $meta.maxConsecLossesLoss = [double]($Matches[2] -replace ',', '')
            }
            # Maximum profit of consecutive wins (different from max consecutive count)
            if ($line -match '(?:Maximal consecutive profit|Gewinn aufeinanderfolgender Gewinntrades)[^<]*</td><td[^>]*>([0-9.,\-]+)\s*\(([0-9]+)\)') {
                $meta.maxConsecProfit = [double]($Matches[1] -replace ',', '')
                $meta.maxConsecProfitCount = [int]$Matches[2]
            }
            # Maximum loss of consecutive losses (different from max consecutive count)
            if ($line -match '(?:Maximal consecutive loss|Verlust aufeinanderfolgender Verlusttrades)[^<]*</td><td[^>]*>([0-9.,\-]+)\s*\(([0-9]+)\)') {
                $meta.maxConsecLoss = [double]($Matches[1] -replace ',', '')
                $meta.maxConsecLossCount = [int]$Matches[2]
            }
            # Average consecutive wins/losses
            if ($line -match 'Durchschnitt</td><td>Gewinntrades in Folge</td><td[^>]*>([0-9]+)') {
                $meta.avgConsecWins = [int]$Matches[1]
            }
            if ($line -match 'Verlusttrades in Folge</td><td[^>]*>([0-9]+)</td></tr>') {
                $meta.avgConsecLosses = [int]$Matches[1]
            }
            # Average win/loss per trade
            if ($line -match 'Durchschnitt</td><td>Gewinntrade</td><td[^>]*>([0-9.,]+)') {
                $meta.avgWin = [double]($Matches[1] -replace ',', '')
            }
            if ($line -match 'Verlusttrade</td><td[^>]*>([0-9.,\-]+)</td></tr>') {
                $meta.avgLoss = [double]($Matches[1] -replace ',', '')
            }
        }
    } finally {
        $reader.Close()
    }

    return @{ meta = $meta; events = $events.ToArray() }
}

function Remove-NullValues {
    param($Object)
    if ($Object -is [hashtable]) {
        $clean = @{}
        foreach ($key in $Object.Keys) {
            $val = $Object[$key]
            if ($null -ne $val) {
                $clean[$key] = Remove-NullValues $val
            }
        }
        return $clean
    } elseif ($Object -is [array]) {
        return @($Object | ForEach-Object { Remove-NullValues $_ })
    }
    return $Object
}

function Generate-EnhancedReport {
    param($Data, [string]$OutputPath)

    $templatePath = Join-Path $ScriptDir "ReportTemplate.html"
    if (-not (Test-Path $templatePath)) {
        throw "Template file not found: $templatePath"
    }

    $template = Get-Content -Path $templatePath -Raw -Encoding UTF8
    $cleanData = Remove-NullValues $Data
    $json = $cleanData | ConvertTo-Json -Depth 10 -Compress
    $html = $template -replace '/\*\{\{REPORT_DATA\}\}\*/\{\}', $json

    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
}

function Find-TerminalID {
    param([string]$AppDataRoot)

    if (-not (Test-Path $AppDataRoot)) {
        return $null
    }

    $folders = Get-ChildItem -Path $AppDataRoot -Directory -ErrorAction SilentlyContinue
    if ($folders -and $folders.Count -gt 0) {
        # Filter to only terminal ID folders (32-char hex, not "Common" etc.)
        $terminalFolders = $folders | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }
        if ($terminalFolders) {
            # Prefer folders that have an MQL4\Experts directory
            $withExperts = $terminalFolders | Where-Object {
                Test-Path (Join-Path $_.FullName "MQL4\Experts")
            }
            if ($withExperts) {
                # Return the most recently modified one that has Experts folder
                return $withExperts | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            }
            # Fallback to most recently modified
            return $terminalFolders | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
    }
    return $null
}

function Wait-ForTerminalID {
    param([string]$AppDataRoot, [int]$TimeoutSeconds = 30)

    Write-Status "Waiting for terminal ID folder..."
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $folder = Find-TerminalID -AppDataRoot $AppDataRoot
        if ($folder) {
            return $folder
        }
        Start-Sleep -Milliseconds 500
        $elapsed += 0.5
    }
    return $null
}

# Banner
Write-Host ""
Write-Host "  __  __  ___  _  _   ____        _ _     _" -ForegroundColor Magenta
Write-Host " |  \/  |/ _ \| || | | __ ) _   _(_) | __| |" -ForegroundColor Magenta
Write-Host " | |\/| | | | | || |_|  _ \| | | | | |/ _`` |" -ForegroundColor Magenta
Write-Host " | |  | | |_| |__   _| |_) | |_| | | | (_| |" -ForegroundColor Magenta
Write-Host " |_|  |_|\__\_\  |_| |____/ \__,_|_|_|\__,_|" -ForegroundColor Magenta
Write-Host "              Build & Test" -ForegroundColor Magenta
Write-Host ""

# Load config
Write-Header "CONFIGURATION"

if (-not (Test-Path $ConfigFile)) {
    Write-Status "Config file not found: $ConfigFile" "ERROR"
    exit 1
}

$config = Read-IniFile -Path $ConfigFile
$MT4Terminal = $config["MT4"]["Terminal"]
$AppDataRoot = $config["MT4"]["AppDataRoot"]
$TestExpertName = $config["Test"]["ExpertName"]

# Apply defaults from config, allow command-line overrides
if (-not $Symbol) { $Symbol = $config["Test"]["Symbol"] }
if (-not $Period) { $Period = $config["Test"]["Period"] }
if ($Model -eq -1) { $Model = [int]$config["Test"]["Model"] }
if (-not $FromDate) { $FromDate = $config["Test"]["FromDate"] }
if (-not $ToDate) { $ToDate = $config["Test"]["ToDate"] }

Write-Status "MT4: $MT4Terminal"
Write-Status "AppData: $AppDataRoot"
Write-Status "Test Expert Name: $TestExpertName"
Write-Status "Expert: $Expert | Symbol: $Symbol | Period: $Period"

# Step 1: Build
Write-Header "STEP 1: BUILD"

$buildScript = Join-Path $ScriptDir "Build.ps1"

if ($All) {
    Write-Status "Building all Expert Advisors..."
    & $buildScript
} else {
    $mq4File = "$Expert.mq4"
    Write-Status "Building $Expert.mq4..."
    & $buildScript -File $mq4File
}

if ($LASTEXITCODE -ne 0) {
    Write-Status "Build FAILED" "ERROR"
    exit 1
}

Write-Status "Build completed successfully" "SUCCESS"

$sourceEx4 = Join-Path $ExpertsDir "$Expert.ex4"
if (-not (Test-Path $sourceEx4)) {
    Write-Status "Compiled EA not found: $sourceEx4" "ERROR"
    exit 1
}

# Step 2: Find terminal ID
Write-Header "STEP 2: FIND TERMINAL"

$terminalFolder = Find-TerminalID -AppDataRoot $AppDataRoot

if (-not $terminalFolder) {
    Write-Status "No terminal folder found. Starting MT4 to create one..." "WARN"

    if (-not (Test-Path $MT4Terminal)) {
        Write-Status "MT4 executable not found: $MT4Terminal" "ERROR"
        exit 1
    }

    Start-Process -FilePath $MT4Terminal
    $terminalFolder = Wait-ForTerminalID -AppDataRoot $AppDataRoot -TimeoutSeconds 60

    if (-not $terminalFolder) {
        Write-Status "Timeout waiting for terminal folder" "ERROR"
        exit 1
    }

    # Give MT4 a moment to initialize, then close it
    Start-Sleep -Seconds 3
    $mt4Process = Get-Process -Name "terminal" -ErrorAction SilentlyContinue
    if ($mt4Process) {
        $mt4Process | Stop-Process -Force
        Start-Sleep -Seconds 1
    }
}

$TerminalID = $terminalFolder.Name
$TempDataDir = $terminalFolder.FullName

Write-Status "Found TerminalID: $TerminalID" "SUCCESS"
Write-Status "Data folder: $TempDataDir"

# Step 3: Deploy EA
Write-Header "STEP 3: DEPLOY EXPERT"

$expertsPath = Join-Path $TempDataDir "MQL4\Experts"
if (-not (Test-Path $expertsPath)) {
    Write-Status "Experts folder not found: $expertsPath" "ERROR"
    exit 1
}

$destEx4 = Join-Path $expertsPath "$TestExpertName.ex4"
Copy-Item -Path $sourceEx4 -Destination $destEx4 -Force
Write-Status "Deployed: $TestExpertName.ex4 (from $Expert.ex4)" "SUCCESS"

# Step 4: Prepare reports folder
Write-Header "STEP 4: PREPARE REPORTS"

# Create/clean reports directory
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
    Write-Status "Created TestReports folder" "SUCCESS"
} else {
    # Clean old reports
    Get-ChildItem -Path $ReportsDir -Filter "*.htm" | Remove-Item -Force
    Get-ChildItem -Path $ReportsDir -Filter "*.html" | Remove-Item -Force
    Write-Status "Cleaned TestReports folder" "SUCCESS"
}

# Generate report filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFileName = "${Expert}_${Symbol}_${Period}_${timestamp}.htm"
$reportPath = Join-Path $ReportsDir $reportFileName

Write-Status "Report will be saved to:" "INFO"
Write-Status "  $reportPath" "INFO"

# Step 5: Configure tester
Write-Header "STEP 5: CONFIGURE TESTER"

$periodCode = $PeriodMap[$Period]
if (-not $periodCode) {
    Write-Status "Invalid period: $Period" "ERROR"
    exit 1
}

$terminalIniPath = Join-Path $TempDataDir "config\terminal.ini"
if (Test-Path $terminalIniPath) {
    # Configure tester section
    Update-IniSection -FilePath $terminalIniPath -Section "Tester" -Values @{
        "Expert" = "$TestExpertName.ex4"
        "Symbol" = $Symbol
        "Period" = $periodCode
        "Model" = $Model
        "FromDate" = $FromDate
        "ToDate" = $ToDate
        "UseDate" = 1
        "Optimization" = 0
    }

    # Configure report path in Settings section
    Update-IniSection -FilePath $terminalIniPath -Section "Settings" -Values @{
        "TesterReportPath" = $reportPath
    }

    Write-Status "Updated terminal.ini" "SUCCESS"
} else {
    Write-Status "terminal.ini not found, skipping config" "WARN"
}

# Also update tester/lastparameters.ini (the Strategy Tester cache)
$testerFolder = Join-Path $TempDataDir "tester"
$lastParamsPath = Join-Path $testerFolder "lastparameters.ini"
if (Test-Path $lastParamsPath) {
    $fromTimestamp = ConvertTo-UnixTimestamp -DateString $FromDate
    $toTimestamp = ConvertTo-UnixTimestamp -DateString $ToDate

    $lastParamsContent = @"
optimization=0
genetic=1
fitnes=0
method=$Model
use_date=1
from=$fromTimestamp
to=$toTimestamp

"@
    Set-Content -Path $lastParamsPath -Value $lastParamsContent
    Write-Status "Updated tester/lastparameters.ini (dates as Unix timestamps)" "SUCCESS"
}

Write-Status "  Expert: $TestExpertName.ex4" "INFO"
Write-Status "  Symbol: $Symbol | Period: $Period | Model: $Model" "INFO"

# Helper function to analyze a report
# $reportPath: source report file
# $outputDir: optional output directory (defaults to same as source)
function Invoke-AnalyzeReport($reportPath, $outputDir = $null) {
    $name = [System.IO.Path]::GetFileName($reportPath)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($reportPath)
    $sourceDir = [System.IO.Path]::GetDirectoryName($reportPath)
    if (-not $outputDir) { $outputDir = $sourceDir }

    Write-Status "Analyzing report: $name" "INFO"
    try {
        # Parse the MT4 report
        $data = Parse-MT4Report -Path $reportPath

        # Generate enhanced report
        $enhancedPath = Join-Path $outputDir "${baseName}_Enhanced.html"
        Generate-EnhancedReport -Data $data -OutputPath $enhancedPath

        Write-Host "  Events: $($data.events.Count)" -ForegroundColor Cyan
        Write-Status "Enhanced report saved: $enhancedPath" "SUCCESS"

        # Clean up source files
        Remove-Item -Path $reportPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path $sourceDir "$baseName.gif") -Force -ErrorAction SilentlyContinue
        Write-Status "Analysis complete" "SUCCESS"
    } catch {
        Write-Status "Analysis failed: $_" "ERROR"
    }
}

# Helper function to check if report was already analyzed
function Test-AlreadyAnalyzed($reportPath) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($reportPath)
    $dir = [System.IO.Path]::GetDirectoryName($reportPath)
    $enhancedPath = Join-Path $dir "${baseName}_Enhanced.html"
    if (-not (Test-Path $enhancedPath)) { return $false }
    $content = Get-Content -Path $enhancedPath -TotalCount 10 -ErrorAction SilentlyContinue
    return ($content -join '') -match 'MQ4-Report-Analyzer'
}

# Step 6: Launch MT4
if (-not $NoLaunch) {
    Write-Header "STEP 6: LAUNCH MT4"

    if (-not (Test-Path $MT4Terminal)) {
        Write-Status "MT4 terminal not found: $MT4Terminal" "ERROR"
        exit 1
    }

    # Check if MT4 is already running
    $existingTerminal = Get-Process -Name "terminal" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existingTerminal) {
        Write-Status "MT4 is already running. Please close it first." "ERROR"
        exit 1
    }

    if ($Manual) {
        # Manual mode: launch MT4 and show instructions
        Write-Status "Starting MetaTrader 4 (manual mode)..."
        $mt4Process = Start-Process -FilePath $MT4Terminal -PassThru
        Start-Sleep -Seconds 5  # Give time for MT4 to start
        Write-Status "MT4 launched (waiting for it to close...)" "SUCCESS"
        Write-Host ""
        Write-Host "  INSTRUCTIONS:" -ForegroundColor Yellow
        Write-Host "  1. In MT4: Press Ctrl+R to open Strategy Tester" -ForegroundColor White
        Write-Host "  2. Verify/Select these settings:" -ForegroundColor White
        Write-Host "       Expert Advisor: $TestExpertName" -ForegroundColor Cyan
        Write-Host "       Symbol: $Symbol" -ForegroundColor Cyan
        Write-Host "       Period: $Period" -ForegroundColor Cyan
        Write-Host "       Model: $Model (0=Every tick, 1=Control points, 2=Open prices)" -ForegroundColor Cyan
        Write-Host "       Date: $FromDate to $ToDate" -ForegroundColor Cyan
        Write-Host "  3. Click 'Start' to run the backtest" -ForegroundColor White
        Write-Host "  4. When done, right-click results -> 'Save as Report'" -ForegroundColor White
        Write-Host "     Save to: $ReportsDir" -ForegroundColor Cyan
        Write-Host "     (Reports are analyzed automatically when saved!)" -ForegroundColor Green
        Write-Host "  5. Close MT4 when finished, or save more reports" -ForegroundColor White
        Write-Host ""

        # Wait for MT4 to close while watching for new reports
        Write-Header "WAITING FOR MT4"
        Write-Status "Watching for new reports in $ReportsDir" "INFO"

        $reportsAnalyzed = 0
        while ($true) {
            # Check for unanalyzed .htm reports
            $reports = Get-ChildItem -Path $ReportsDir -Filter "*.htm" -ErrorAction SilentlyContinue |
                       Where-Object { -not (Test-AlreadyAnalyzed $_.FullName) }

            foreach ($report in $reports) {
                Invoke-AnalyzeReport $report.FullName
                ++$reportsAnalyzed
            }

            # Check if MT4 is still running (handle both direct launch and launcher scripts)
            $terminalProcess = Get-Process -Name "terminal" -ErrorAction SilentlyContinue | Select-Object -First 1
            $launcherStillRunning = $mt4Process -and -not $mt4Process.HasExited
            if (-not $launcherStillRunning -and -not $terminalProcess) {
                Write-Host ""
                Write-Status "MT4 closed" "SUCCESS"
                break
            }

            Start-Sleep -Seconds 2
        }

        # Final summary for manual mode
        Write-Header "COMPLETE"
        if ($reportsAnalyzed -gt 0) {
            Write-Status "Reports analyzed: $reportsAnalyzed" "SUCCESS"
        } else {
            Write-Status "No reports were saved" "WARN"
        }
    } else {
        # Auto mode: create startup INI and let MT4 run the test automatically
        Write-Status "Starting MetaTrader 4 (auto mode)..."

        # Create startup INI file for automatic testing
        # TestReport is just a filename - MT4 saves to terminal data folder
        # We'll move the report to TestReports afterwards
        $reportBaseName = "${Expert}_${Symbol}_${Period}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $startupIni = Join-Path $TempDataDir "config\autotest.ini"

        # Generate EA parameter file if parameters were provided
        # MT4 tester expects parameters in a special INI format in the tester folder
        $testExpertParamsValue = ""
        if ($ExpertParams) {
            $testerFolder = Join-Path $TempDataDir "tester"
            $paramIniPath = Join-Path $testerFolder "$TestExpertName.ini"

            # Parse parameters (key=value;key2=value2 format)
            $paramLines = @()
            $paramLines += "<inputs>"
            foreach ($pair in $ExpertParams.Split(';', [StringSplitOptions]::RemoveEmptyEntries)) {
                $parts = $pair.Split('=', 2)
                if ($parts.Count -eq 2) {
                    $key = $parts[0].Trim()
                    $value = $parts[1].Trim()
                    # Format: name=value, then optimization flags (F=0 means fixed/not optimized)
                    $paramLines += "$key=$value"
                    $paramLines += "$key,F=0"
                    $paramLines += "$key,1=$value"
                    $paramLines += "$key,2=0"
                    $paramLines += "$key,3=0"
                }
            }
            $paramLines += "</inputs>"

            $paramContent = $paramLines -join "`r`n"
            [System.IO.File]::WriteAllText($paramIniPath, $paramContent, [System.Text.Encoding]::ASCII)
            Write-Status "Created EA parameters file: $paramIniPath" "SUCCESS"

            # TestExpertParameters takes the filename (relative to tester folder)
            $testExpertParamsValue = "$TestExpertName.ini"
        }

        $iniContent = @"
; Auto-generated startup configuration for backtesting
[Tester]
TestExpert=$TestExpertName
TestExpertParameters=$testExpertParamsValue
TestSymbol=$Symbol
TestPeriod=$Period
TestModel=$Model
TestSpread=0
TestOptimization=false
TestDateEnable=true
TestFromDate=$FromDate
TestToDate=$ToDate
TestReport=$reportBaseName
TestReplaceReport=true
TestShutdownTerminal=true
TestVisualEnable=false
"@
        # Save as ASCII encoding (required by MT4)
        [System.IO.File]::WriteAllText($startupIni, $iniContent, [System.Text.Encoding]::ASCII)
        Write-Status "Created startup INI: $startupIni" "SUCCESS"

        # Expected report path - MT4 saves to terminal data folder
        $expectedReportPath = Join-Path $TempDataDir "$reportBaseName.htm"

        Write-Host ""
        Write-Host "  AUTO-TEST CONFIGURATION:" -ForegroundColor Yellow
        Write-Host "       Expert: $TestExpertName" -ForegroundColor Cyan
        Write-Host "       Symbol: $Symbol" -ForegroundColor Cyan
        Write-Host "       Period: $Period" -ForegroundColor Cyan
        Write-Host "       Model: $Model (0=Every tick, 1=Control points, 2=Open prices)" -ForegroundColor Cyan
        Write-Host "       Date: $FromDate to $ToDate" -ForegroundColor Cyan
        Write-Host "       Report: $expectedReportPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Status "MT4 will auto-start test and close when done..." "INFO"

        # Launch MT4 with startup INI (minimized, no focus steal)
        # Pass --minimized flag for start.bat, plus the INI file path
        $mt4Process = Start-Process -FilePath $MT4Terminal -ArgumentList "--minimized `"$startupIni`"" -PassThru -WindowStyle Minimized
        Write-Status "MT4 launched minimized with auto-test configuration" "SUCCESS"

        # Wait for MT4 to close
        Write-Header "WAITING FOR MT4"
        Write-Status "Backtest running... (MT4 will close automatically when done)" "INFO"

        while ($true) {
            $terminalProcess = Get-Process -Name "terminal" -ErrorAction SilentlyContinue | Select-Object -First 1
            $launcherStillRunning = $mt4Process -and -not $mt4Process.HasExited
            if (-not $launcherStillRunning -and -not $terminalProcess) { break }
            Start-Sleep -Seconds 2
        }

        Write-Status "MT4 closed" "SUCCESS"

        # Clean up startup INI
        Remove-Item -Path $startupIni -Force -ErrorAction SilentlyContinue

        # Check if report was created and analyze it
        Write-Header "ANALYZE REPORT"

        if (Test-Path $expectedReportPath) {
            Write-Status "Report found: $expectedReportPath" "SUCCESS"
            # Analyze directly from MT4 folder, output to TestReports
            Invoke-AnalyzeReport $expectedReportPath $ReportsDir
        } else {
            # Check for any .htm files in terminal data folder (MT4 might use different name)
            $reports = Get-ChildItem -Path $TempDataDir -Filter "*.htm" -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -notmatch '^(index|default|statement|OptimizationReport|strategytester)\.htm' }
            if ($reports -and $reports.Count -gt 0) {
                Write-Status "Found report(s) in terminal folder" "SUCCESS"
                foreach ($report in $reports) {
                    # Analyze directly from MT4 folder, output to TestReports
                    Invoke-AnalyzeReport $report.FullName $ReportsDir
                }
            } else {
                Write-Status "No report was generated. The backtest may have failed." "ERROR"
                Write-Status "Try running with -Manual flag to debug." "INFO"
            }
        }
    }
} else {
    # NoLaunch mode - just show instructions
    Write-Header "DONE"
    Write-Status "Expert deployed and configured."
    Write-Host ""
    Write-Host "  INSTRUCTIONS:" -ForegroundColor Yellow
    Write-Host "  1. In MT4: Press Ctrl+R to open Strategy Tester" -ForegroundColor White
    Write-Host "  2. Verify/Select these settings:" -ForegroundColor White
    Write-Host "       Expert Advisor: $TestExpertName" -ForegroundColor Cyan
    Write-Host "       Symbol: $Symbol" -ForegroundColor Cyan
    Write-Host "       Period: $Period" -ForegroundColor Cyan
    Write-Host "       Model: $Model (0=Every tick, 1=Control points, 2=Open prices)" -ForegroundColor Cyan
    Write-Host "       Date: $FromDate to $ToDate" -ForegroundColor Cyan
    Write-Host "  3. Click 'Start' to run the backtest" -ForegroundColor White
    Write-Host "  4. When done, right-click results -> 'Save as Report'" -ForegroundColor White
    Write-Host "     Save to: $ReportsDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Status "TestReports folder: $ReportsDir" "INFO"
}

# Summary
Write-Header "COMPLETE"
Write-Status "Build and test workflow finished."

exit 0
