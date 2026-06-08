# Installs MetaTrader 4 silently to obtain metaeditor.exe, then compiles every
# MQL source in the repo. Relative #includes resolve per-file, so the on-disk
# tree is compiled in place; .ex4 binaries land next to their sources.
# Exits non-zero if any source fails to compile or no binary is produced.
$ErrorActionPreference = 'Stop'
# metaeditor.exe returns a non-zero exit code as a matter of course; on
# PowerShell 7.4+ that would terminate the script before our log-based
# success check. Let native exit codes through and judge success from the
# compile log + produced binaries instead.
$PSNativeCommandUseErrorActionPreference = $false

function Find-MetaEditor {
  $roots = @("${env:ProgramFiles(x86)}", "$env:ProgramFiles", "$env:APPDATA\MetaQuotes", "$env:LOCALAPPDATA")
  foreach ($r in $roots) {
    if ($r -and (Test-Path $r)) {
      $e = Get-ChildItem -Path $r -Recurse -Filter 'metaeditor*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($e) { return $e.FullName }
    }
  }
  return $null
}

$editor = Find-MetaEditor
if (-not $editor) {
  Write-Host "Downloading MetaTrader 4 setup..."
  $url = 'https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe'
  for ($i = 1; $i -le 3 -and -not (Test-Path mt4setup.exe); $i++) {
    try { Invoke-WebRequest -Uri $url -OutFile mt4setup.exe -UseBasicParsing -TimeoutSec 120 }
    catch { Write-Host "download attempt $i failed: $_"; Start-Sleep 10 }
  }
  Write-Host "Installing silently (/auto)..."
  Start-Process -FilePath .\mt4setup.exe -ArgumentList '/auto' -PassThru | Out-Null
  $deadline = (Get-Date).AddMinutes(8)
  while (-not $editor -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 10
    $editor = Find-MetaEditor
  }
  # the installer auto-launches the terminal; stop it so the job can finish
  Get-Process terminal, mt4setup -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
if (-not $editor) { Write-Error "metaeditor.exe not found after install"; exit 1 }
Write-Host "Using compiler: $editor"
Get-Process terminal, terminal64 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Restore the legacy <stdlib.mqh> (ErrorDescription) that current MT4 builds no
# longer ship but older EAs still #include. Copy it into the compiler include dir.
$incDir = Join-Path (Split-Path $editor) "MQL4\Include"
New-Item -ItemType Directory -Force -Path $incDir | Out-Null
$stdlib = Join-Path $incDir "stdlib.mqh"
if (-not (Test-Path $stdlib)) {
  Copy-Item -Path "$PSScriptRoot\stdlib.mqh" -Destination $stdlib -Force
  Write-Host "Restored legacy stdlib.mqh -> $stdlib"
}

$repo = (Get-Location).Path
$log  = Join-Path $repo 'compile.log'
# /compile on a folder builds every source recursively; relative #includes
# resolve from each file's own directory. Bounded so a stuck editor can't hang
# the job (metaeditor may keep a handle open after writing the log).
$p = Start-Process -FilePath $editor -ArgumentList "/compile:$repo", "/log:$log" -PassThru -NoNewWindow
if (-not $p.WaitForExit(180000)) { Write-Warning "compiler timed out; killing"; $p.Kill() }
Get-Process terminal, terminal64 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

if (Test-Path $log) {
  # MetaEditor writes UTF-16 (Unicode) logs.
  $txt = Get-Content -Path $log -Raw -Encoding Unicode
  Write-Host "=== compile.log ==="
  Write-Host $txt
} else {
  Write-Warning "no compile.log produced"
  $txt = ""
}

# Count sources that failed (per-file "Result: N errors" summary lines) and the
# binaries produced. Judge success from those, not from metaeditor exit codes.
$errCount = ([regex]::Matches($txt, "(?im)Result:\s*[1-9]\d*\s+error")).Count
$ex = @(Get-ChildItem -Path $repo -Recurse -File | Where-Object { $_.Extension -ieq ".ex4" -or $_.Extension -ieq ".ex5" })
Write-Host "Compiled binaries: $($ex.Count); sources with errors: $errCount"
if ($errCount -gt 0) { Write-Error "some sources failed to compile"; exit 1 }
if ($ex.Count -eq 0) { Write-Error "no .ex4/.ex5 produced"; exit 1 }
exit 0
