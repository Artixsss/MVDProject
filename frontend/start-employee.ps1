# Stop all Flutter Web Server processes if they exist
Get-Process chrome -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like '*--remote-debugging-port=*'} | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process flutter* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$FRONTEND_PORT = 3000
$FRONTEND_URL = "http://localhost:$FRONTEND_PORT/"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Starting MVD Frontend (Employee Version)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Browser window will open for employees:" -ForegroundColor Blue
Write-Host "  $FRONTEND_URL" -ForegroundColor Blue
Write-Host ""
Write-Host "Port: $FRONTEND_PORT" -ForegroundColor Gray
Write-Host ""

# Function to open browser window once after delay
# Chrome will reuse existing window/tab if URL matches
function Open-BrowserWindowOnce {
    param($Url, $DelaySeconds = 10)
    
    Start-Job -ScriptBlock {
        param($Url, $Delay)
        Start-Sleep -Seconds $Delay
        
        # Open URL - Chrome will reuse existing tab if same URL, or open new tab
        # This ensures only one window is opened
        Start-Process $Url
    } -ArgumentList $Url, $DelaySeconds | Out-Null
}

# Open window for employees (after 10 seconds) - only once
Write-Host "[INFO] Employees window will open in 10 seconds: $FRONTEND_URL" -ForegroundColor Blue
Open-BrowserWindowOnce $FRONTEND_URL 10

Write-Host ""
Write-Host "Starting Flutter..." -ForegroundColor Yellow
Write-Host ""
Write-Host "[INFO] Flutter will NOT auto-open browser (we open it manually)" -ForegroundColor Gray
Write-Host ""

# Run Flutter with web-server device (prevents auto-browser opening)
flutter run -d web-server --web-port=$FRONTEND_PORT --web-hostname=localhost

