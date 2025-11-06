@echo off
REM MVD Project - Start Employee Version (Separate Project)
chcp 65001 >nul
echo ================================================
echo   MVD Project - Starting Employee Version
echo ================================================
echo.

if not exist "backend\" (
    echo [ERROR] Backend folder not found!
    pause
    exit /b 1
)

if not exist "frontend-employee\" (
    echo [ERROR] frontend-employee folder not found!
    pause
    exit /b 1
)

echo [1/2] Starting Backend...
start "MVD Backend" cmd /k "cd backend && start.bat"

timeout /t 5 /nobreak >nul

echo.
echo [2/2] Starting Frontend (Employee Version)...
echo.
echo NOTE: Flutter will build and serve the app automatically
echo Browser will open when ready (may take 30-60 seconds)
echo.
start "MVD Frontend (Employee)" cmd /k "cd frontend-employee && start.bat"

echo.
echo ================================================
echo   Services started!
echo ================================================
echo.
echo Backend: http://localhost:5029
echo Frontend: http://localhost:4000/
echo.
pause >nul

