@echo off
chcp 65001 >nul
echo ================================================
echo   MVD Backend - Killing all processes
echo ================================================
echo.

REM Kill MvdBackend processes
echo Stopping MvdBackend processes...
taskkill /F /IM MvdBackend.exe >nul 2>&1
timeout /t 1 /nobreak >nul

REM Kill process on port 5029
echo Checking port 5029...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5029 ^| findstr LISTENING') do (
    echo Killing process %%a on port 5029
    taskkill /F /PID %%a >nul 2>&1
)

timeout /t 2 /nobreak >nul
echo.
echo Done! Port 5029 should be free now.
echo.
pause

