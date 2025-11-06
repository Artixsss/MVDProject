@echo off
chcp 65001 >nul
echo ================================================
echo   MVD Backend - Starting
echo ================================================
echo.

REM Kill MvdBackend processes
echo Stopping existing MvdBackend processes...
taskkill /F /IM MvdBackend.exe >nul 2>&1

REM Kill process on port 5029 (most important)
echo Checking port 5029...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5029 ^| findstr LISTENING') do (
    echo Killing process %%a on port 5029
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 3 /nobreak >nul

REM Double check - kill any remaining processes on port 5029
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5029') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 1 /nobreak >nul

echo.
echo Starting backend...
echo.

dotnet run

pause

