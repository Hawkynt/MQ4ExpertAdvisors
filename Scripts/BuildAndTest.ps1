<#
.SYNOPSIS
    Builds and deploys MQL4 Expert Advisor for testing in existing MT4.

.DESCRIPTION
    Uses an existing MT4 installation with broker data:
    1. Compiles the Expert Advisor
    2. Auto-detects terminal ID from AppData
    3. Deploys EA with configured test name
    4. Updates terminal.ini with test parameters
    5. Launches MT4 (unless -NoLaunch specified)

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

.EXAMPLE
    .\BuildAndTest.ps1
    .\BuildAndTest.ps1 -Expert "MyEA"
    .\BuildAndTest.ps1 -Expert "MyEA" -Symbol "EURUSD" -Period "M15"
    .\BuildAndTest.ps1 -NoLaunch
#>

param(
    [string]$Expert = "AdaptiveTrader",
    [string]$Symbol,
    [string]$Period,
    [int]$Model = -1,
    [switch]$NoLaunch = $false,
    [switch]$All = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ExpertsDir = Join-Path $ProjectRoot "Experts"
$ConfigFile = Join-Path $ScriptDir "BuildAndTest.ini"
$ReportsDir = Join-Path $ProjectRoot "TestReports"

# Period mapping (name to MT4 period value in minutes)
$PeriodMap = @{
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
$FromDate = $config["Test"]["FromDate"]
$ToDate = $config["Test"]["ToDate"]

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

Write-Status "  Expert: $TestExpertName.ex4" "INFO"
Write-Status "  Symbol: $Symbol | Period: $Period | Model: $Model" "INFO"

# Step 6: Launch MT4
if (-not $NoLaunch) {
    Write-Header "STEP 6: LAUNCH MT4"

    if (Test-Path $MT4Terminal) {
        Write-Status "Starting MetaTrader 4..."
        $mt4Process = Start-Process -FilePath $MT4Terminal -PassThru
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
        Write-Status "Waiting for MetaTrader 4 to close..."
        Write-Status "Watching for new reports in $ReportsDir" "INFO"

        # Set up FileSystemWatcher to analyze reports in real-time
        $analyzerScript = Join-Path $ScriptDir "AnalyzeReport.ps1"
        $analyzedReports = [System.Collections.Generic.HashSet[string]]::new()
        $watcher = $null

        if (Test-Path $analyzerScript) {
            $watcher = [System.IO.FileSystemWatcher]::new()
            $watcher.Path = $ReportsDir
            $watcher.Filter = "*.htm"
            $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite
            $watcher.EnableRaisingEvents = $true

            # Event handler for new/changed files
            $action = {
                $path = $Event.SourceEventArgs.FullPath
                $name = $Event.SourceEventArgs.Name
                $changeType = $Event.SourceEventArgs.ChangeType
                $analyzer = $Event.MessageData.Analyzer
                $outputDir = $Event.MessageData.OutputDir
                $analyzed = $Event.MessageData.Analyzed

                # Skip if already analyzed or if it's an _Enhanced.html file
                if ($name -match '_Enhanced\.html?$') { return }
                if ($analyzed.Contains($path)) { return }

                # Wait a moment for file to be fully written
                Start-Sleep -Milliseconds 500

                # Check if file exists and is readable
                if (-not (Test-Path $path)) { return }

                Write-Host ""
                Write-Host "[WATCHER] New report detected: $name" -ForegroundColor Green
                Write-Host "[WATCHER] Analyzing immediately..." -ForegroundColor Cyan

                try {
                    & $analyzer -ReportPath $path -OutputDir $outputDir
                    [void]$analyzed.Add($path)
                    Write-Host "[WATCHER] Analysis complete. Continue testing or close MT4." -ForegroundColor Green
                    Write-Host ""
                } catch {
                    Write-Host "[WATCHER] Analysis failed: $_" -ForegroundColor Red
                }
            }

            $messageData = @{
                Analyzer = $analyzerScript
                OutputDir = $ReportsDir
                Analyzed = $analyzedReports
            }

            Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action -MessageData $messageData | Out-Null
            Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action -MessageData $messageData | Out-Null

            Write-Status "Report watcher active - reports will be analyzed automatically" "SUCCESS"
        }

        # Find terminal.exe process (may be different from start.bat)
        Start-Sleep -Seconds 3
        $terminalProcess = Get-Process -Name "terminal" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($terminalProcess) {
            $terminalProcess.WaitForExit()
        } else {
            # Fallback: wait for any terminal.exe to appear and then close
            $maxWait = 300  # 5 minutes max wait for MT4 to start
            $waited = 0
            while ($waited -lt $maxWait) {
                $terminalProcess = Get-Process -Name "terminal" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($terminalProcess) {
                    Write-Status "Found MT4 process, waiting for it to close..."
                    $terminalProcess.WaitForExit()
                    break
                }
                Start-Sleep -Seconds 1
                $waited++
            }
        }

        # Clean up watcher
        if ($watcher) {
            Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher } | Unregister-Event
            $watcher.Dispose()
            Write-Status "Report watcher stopped" "INFO"
        }

        Write-Status "MT4 closed" "SUCCESS"

        # Step 7: Find and analyze any remaining reports
        Write-Header "STEP 7: ANALYZE REPORT"

        # Look for newest .htm file in TestReports that wasn't already analyzed
        $reports = Get-ChildItem -Path $ReportsDir -Filter "*.htm" -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -notmatch '_Enhanced\.html?$' } |
                   Sort-Object LastWriteTime -Descending

        if ($reports -and $reports.Count -gt 0) {
            $latestReport = $reports[0].FullName

            # Skip if already analyzed by watcher
            if ($analyzedReports.Contains($latestReport)) {
                Write-Status "Latest report already analyzed: $($reports[0].Name)" "SUCCESS"
            } else {
                Write-Status "Found report: $($reports[0].Name)" "SUCCESS"

                # Run the analyzer script
                if (Test-Path $analyzerScript) {
                    Write-Status "Analyzing report..."
                    & $analyzerScript -ReportPath $latestReport -OutputDir $ReportsDir
                } else {
                    Write-Status "Analyzer script not found: $analyzerScript" "WARN"
                    Write-Status "Report saved at: $latestReport" "INFO"
                }
            }
        } else {
            Write-Status "No report found in $ReportsDir" "WARN"
            Write-Status "Did you save the report from MT4?" "WARN"
        }
    } else {
        Write-Status "MT4 terminal not found: $MT4Terminal" "ERROR"
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
