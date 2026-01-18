<#
.SYNOPSIS
    Converts MT4 Strategy Tester reports to enhanced HTML format.

.DESCRIPTION
    Parses MT4 HTML report, extracts raw data to JSON, and embeds it
    in a JavaScript-powered template that handles all analysis.

.PARAMETER ReportPath
    Path to the MT4 Strategy Tester HTML report

.PARAMETER OutputDir
    Directory to save the enhanced report

.EXAMPLE
    .\AnalyzeReport.ps1 -ReportPath "TestReports\StrategyTester.htm"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReportPath,
    [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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

# Main
if (-not (Test-Path $ReportPath)) {
    Write-Status "Report file not found: $ReportPath" "ERROR"
    exit 1
}

Write-Status "Parsing report: $ReportPath"
$data = Parse-MT4Report -Path $ReportPath

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($ReportPath)
$outputPath = Join-Path $OutputDir "${baseName}_Enhanced.html"

Write-Status "Generating enhanced report..."
Generate-EnhancedReport -Data $data -OutputPath $outputPath

Write-Status "Enhanced report saved: $outputPath" "SUCCESS"
Write-Host "  Events: $($data.events.Count)" -ForegroundColor Cyan

exit 0
