@echo off
chcp 65001 >nul
echo Starting MVD Frontend (User Version)...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0start-user.ps1"

