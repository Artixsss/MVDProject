# Stop all Flutter Web Server processes if they exist
Get-Process chrome -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like '*--remote-debugging-port=*'} | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process flutter* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$FRONTEND_PORT = 3000
$FRONTEND_URL = "http://localhost:$FRONTEND_PORT"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Starting MVD Frontend (2 windows)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "2 browser windows will open:" -ForegroundColor Yellow
Write-Host "  1. For citizens (submit/check requests)" -ForegroundColor Green
Write-Host "  2. For employees (login to system)" -ForegroundColor Blue
Write-Host ""
Write-Host "Port: $FRONTEND_PORT" -ForegroundColor Gray
Write-Host ""

# Function to open browser window after delay
function Open-BrowserWindow {
    param($Url, $DelaySeconds = 8)
    Start-Job -ScriptBlock {
        param($Url, $Delay)
        Start-Sleep -Seconds $Delay
        Start-Process $Url
    } -ArgumentList $Url, $DelaySeconds | Out-Null
}

# Open window for citizens (after 10 seconds)
Open-BrowserWindow "$FRONTEND_URL/complaint" 10
Write-Host "[INFO] Citizens window will open in 10 seconds: $FRONTEND_URL/complaint" -ForegroundColor Green

# Open window for employees (after 12 seconds)
Open-BrowserWindow "$FRONTEND_URL/" 12
Write-Host "[INFO] Employees window will open in 12 seconds: $FRONTEND_URL/" -ForegroundColor Blue

Write-Host ""
Write-Host "Starting Flutter..." -ForegroundColor Yellow
Write-Host ""

# Run Flutter with fixed port
flutter run -d chrome --web-port=$FRONTEND_PORT --web-hostname=localhost
