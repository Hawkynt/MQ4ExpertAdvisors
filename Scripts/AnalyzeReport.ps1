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

    $content = Get-Content -Path $Path -Raw -Encoding Default

    # Extract all order events from table rows
    $events = @()
    $eventPattern = '<tr[^>]*>\s*<td>(\d+)</td>\s*<td[^>]*>([^<]+)</td>\s*<td>(buy|sell|modify|close|s/l|t/p)</td>\s*<td>(\d+)</td>\s*<td[^>]*>([0-9.]+)</td>\s*<td[^>]*>([0-9.]+)</td>\s*<td[^>]*>([0-9.]+)</td>\s*<td[^>]*>([0-9.]+)</td>\s*(?:<td[^>]*>(-?[0-9.]+)</td>\s*<td[^>]*>([0-9.]+)</td>|<td colspan=2></td>)'

    $eventMatches = [regex]::Matches($content, $eventPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($match in $eventMatches) {
        $events += @{
            n = [int]$match.Groups[1].Value
            t = $match.Groups[2].Value.Trim()
            y = $match.Groups[3].Value.ToLower()
            o = [int]$match.Groups[4].Value
            v = [double]$match.Groups[5].Value
            p = [double]$match.Groups[6].Value
            s = [double]$match.Groups[7].Value
            k = [double]$match.Groups[8].Value
            r = if ($match.Groups[9].Success -and $match.Groups[9].Value) { [double]$match.Groups[9].Value } else { $null }
            b = if ($match.Groups[10].Success -and $match.Groups[10].Value) { [double]$match.Groups[10].Value } else { $null }
        }
    }

    # Extract metadata using simple patterns - just raw text extraction
    $meta = @{}

    # Title/Expert
    if ($content -match '<title>Strategy Tester:\s*([^<]+)</title>') {
        $meta.expert = $Matches[1].Trim()
    }

    # Symbol
    if ($content -match 'Symbol</td><td[^>]*colspan[^>]*>([^<]+)') {
        $meta.symbol = $Matches[1].Trim()
    }

    # Period
    if ($content -match '(?:Period|Periode)</td><td[^>]*colspan[^>]*>([^<]+)') {
        $meta.period = $Matches[1].Trim()
    }

    # Model
    if ($content -match '(?:Model|Modell)</td><td[^>]*colspan[^>]*>([^<]+)') {
        $meta.model = ($Matches[1] -replace '<[^>]+>', '').Trim()
    }

    # Parameters
    if ($content -match '(?:Parameters|Parameter)</td><td[^>]*colspan[^>]*>([^<]+(?:<[^>]+>[^<]*)*)</td>') {
        $meta.parameters = ($Matches[1] -replace '<[^>]+>', '' -replace '\s+', ' ').Trim()
    }

    # Bars/Candles
    if ($content -match '(?:Bars in test|Getestete Kerzen)</td><td[^>]*>([0-9]+)') {
        $meta.bars = [int]$Matches[1]
    }

    # Ticks
    if ($content -match '(?:Ticks modelled|Modellierte Ticks)</td><td[^>]*>([0-9]+)') {
        $meta.ticks = [int]$Matches[1]
    }

    # Quality
    if ($content -match '(?:Modelling quality|Modellierungsqualit.t)</td><td[^>]*>([^<]+)') {
        $meta.quality = $Matches[1].Trim()
    }

    # Chart errors
    if ($content -match '(?:Mismatched charts errors|Fehler in Chartanpassung)</td><td[^>]*>([0-9]+)') {
        $meta.errors = [int]$Matches[1]
    }

    # Spread
    if ($content -match 'Spread</td><td[^>]*>([^<]+)') {
        $meta.spread = $Matches[1].Trim()
    }

    # Initial deposit
    if ($content -match '(?:Initial Deposit|Urspr.ngliche Einzahlung)</td><td[^>]*>([0-9.,]+)') {
        $meta.deposit = [double]($Matches[1] -replace ',', '')
    }

    return @{ meta = $meta; events = $events }
}

function Generate-EnhancedReport {
    param($Data, [string]$OutputPath)

    $templatePath = Join-Path $ScriptDir "ReportTemplate.html"
    if (-not (Test-Path $templatePath)) {
        throw "Template file not found: $templatePath"
    }

    $template = Get-Content -Path $templatePath -Raw -Encoding UTF8
    $json = $Data | ConvertTo-Json -Depth 10 -Compress
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
