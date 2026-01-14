<#
.SYNOPSIS
    Builds MQL4 Expert Advisors using MetaEditor.

.DESCRIPTION
    Compiles all .mq4 files in the Experts directory or a specific file.
    Reads compiler path from BuildAndTest.ini.
    Returns exit code 0 on success, 1 on failure.

.PARAMETER File
    Optional specific .mq4 file to compile. If not specified, compiles all.

.EXAMPLE
    .\Build.ps1
    .\Build.ps1 -File "AdaptiveTrader.mq4"
#>

param(
    [string]$File = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ExpertsDir = Join-Path $ProjectRoot "Experts"
$LogFile = Join-Path $ProjectRoot "build.log"
$ConfigFile = Join-Path $ScriptDir "BuildAndTest.ini"

# Read config file
function Read-IniFile {
    param([string]$Path)
    $ini = @{}
    $section = ""
    if (Test-Path $Path) {
        foreach ($line in Get-Content $Path) {
            $line = $line.Trim()
            if ($line -match '^\[(.+)\]$') {
                $section = $Matches[1]
                $ini[$section] = @{}
            } elseif ($line -match '^([^;=]+)=(.*)$' -and $section) {
                $ini[$section][$Matches[1].Trim()] = $Matches[2].Trim()
            }
        }
    }
    return $ini
}

$config = Read-IniFile -Path $ConfigFile
$MetaEditorPath = $config["MT4"]["Compiler"]

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

function Compile-MQ4 {
    param([string]$SourceFile)

    $fileName = Split-Path -Leaf $SourceFile
    $ex4File = $SourceFile -replace '\.mq4$', '.ex4'

    Write-Log "Compiling: $fileName"

    # Get file timestamp before compilation
    $beforeTime = if (Test-Path $ex4File) { (Get-Item $ex4File).LastWriteTime } else { [datetime]::MinValue }

    # Run MetaEditor
    $process = Start-Process -FilePath $MetaEditorPath -ArgumentList "/portable", "/compile:`"$SourceFile`"" -Wait -PassThru -NoNewWindow

    # Check if .ex4 was created/updated
    if (Test-Path $ex4File) {
        $afterTime = (Get-Item $ex4File).LastWriteTime
        if ($afterTime -gt $beforeTime) {
            Write-Log "Success: $fileName -> $(Split-Path -Leaf $ex4File)" "SUCCESS"
            return $true
        }
    }

    # Check for .log file (indicates errors)
    $logPath = $SourceFile -replace '\.mq4$', '.log'
    if (Test-Path $logPath) {
        $errors = Get-Content $logPath
        Write-Log "Compilation errors in $fileName`:" "ERROR"
        foreach ($line in $errors) {
            Write-Log "  $line" "ERROR"
        }
        Remove-Item $logPath -Force
        return $false
    }

    Write-Log "Warning: Could not verify compilation of $fileName" "WARN"
    return $true
}

# Main execution
Write-Log "========== Build Started =========="
Write-Log "Project Root: $ProjectRoot"

if (-not (Test-Path $MetaEditorPath)) {
    Write-Log "MetaEditor not found at: $MetaEditorPath" "ERROR"
    exit 1
}

$filesToCompile = @()

if ($File -ne "") {
    # Compile specific file
    $fullPath = if ([System.IO.Path]::IsPathRooted($File)) { $File } else { Join-Path $ExpertsDir $File }
    if (-not (Test-Path $fullPath)) {
        Write-Log "File not found: $fullPath" "ERROR"
        exit 1
    }
    $filesToCompile += $fullPath
} else {
    # Compile all .mq4 files in Experts directory
    $filesToCompile = Get-ChildItem -Path $ExpertsDir -Filter "*.mq4" | Select-Object -ExpandProperty FullName
}

$successCount = 0
$failCount = 0

foreach ($file in $filesToCompile) {
    if (Compile-MQ4 -SourceFile $file) {
        $successCount++
    } else {
        $failCount++
    }
}

Write-Log "========== Build Complete =========="
Write-Log "Success: $successCount, Failed: $failCount"

if ($failCount -gt 0) {
    exit 1
}
exit 0
