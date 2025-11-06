$FRONTEND_PORT = 4000
$FRONTEND_URL = "http://localhost:$FRONTEND_PORT/"

Write-Host "Starting Flutter Web on port $FRONTEND_PORT..." -ForegroundColor Yellow
Write-Host "Browser will open automatically when ready" -ForegroundColor Gray
Write-Host ""

# Run Flutter - it will open browser automatically when ready
flutter run -d chrome --web-port=$FRONTEND_PORT --web-hostname=localhost --web-launch-url=$FRONTEND_URL

