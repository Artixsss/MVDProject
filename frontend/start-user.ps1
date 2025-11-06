# Stop all Flutter Web Server processes if they exist
Get-Process chrome -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like '*--remote-debugging-port=*'} | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process flutter* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$FRONTEND_PORT = 3000
$FRONTEND_URL = "http://localhost:$FRONTEND_PORT/complaint"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Starting MVD Frontend (User Version)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Browser window will open for citizens:" -ForegroundColor Green
Write-Host "  $FRONTEND_URL" -ForegroundColor Green
Write-Host ""
Write-Host "Port: $FRONTEND_PORT" -ForegroundColor Gray
Write-Host ""

# Function to open browser window once after delay
# Chrome will reuse existing window/tab if URL matches
function Open-BrowserWindowOnce {
    param($Url, $DelaySeconds = 15)
    
    Start-Job -ScriptBlock {
        param($Url, $Delay)
        Start-Sleep -Seconds $Delay
        
        # Wait a bit more and check if server is ready
        $maxAttempts = 10
        $attempt = 0
        while ($attempt -lt $maxAttempts) {
            try {
                $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    Write-Host "[INFO] Server is ready, opening browser..." -ForegroundColor Green
                    Start-Process $Url
                    break
                }
            } catch {
                # Server not ready yet
            }
            $attempt++
            Start-Sleep -Seconds 2
        }
        
        # If server still not ready, open anyway after max wait
        if ($attempt -ge $maxAttempts) {
            Write-Host "[WARN] Opening browser anyway (server may still be starting)..." -ForegroundColor Yellow
            Start-Process $Url
        }
    } -ArgumentList $Url, $DelaySeconds | Out-Null
}

# Open window for citizens (after 15 seconds with readiness check) - only once
Write-Host "[INFO] Citizens window will open when server is ready: $FRONTEND_URL" -ForegroundColor Green
Open-BrowserWindowOnce $FRONTEND_URL 15

Write-Host ""
Write-Host "Starting Flutter..." -ForegroundColor Yellow
Write-Host ""
Write-Host "[INFO] Flutter will NOT auto-open browser (we open it manually when ready)" -ForegroundColor Gray
Write-Host ""

# Run Flutter with web-server device (prevents auto-browser opening)
flutter run -d web-server --web-port=$FRONTEND_PORT --web-hostname=localhost

