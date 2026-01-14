@echo off
REM Build and deploy EA for testing in existing MT4
REM Usage: BuildAndTest.cmd [-Expert name] [-Symbol EURUSD] [-Period H1] [-NoLaunch]

powershell -ExecutionPolicy Bypass -File "%~dp0BuildAndTest.ps1" %*
exit /b %ERRORLEVEL%
