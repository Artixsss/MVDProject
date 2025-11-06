@echo off
chcp 65001 >nul
echo Starting MVD Frontend (Employee Version)...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0start.ps1"

