@echo off
REM Build MQL4 Expert Advisors
REM Usage: Build.cmd [-File "AdaptiveTrader.mq4"]

powershell -ExecutionPolicy Bypass -File "%~dp0Build.ps1" %*
exit /b %ERRORLEVEL%
