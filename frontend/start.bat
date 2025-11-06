@echo off
chcp 65001 >nul
echo Starting MVD Frontend...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0start.ps1"
