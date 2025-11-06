# Kill process on port 5029 before starting
$port = 5029
Write-Host "Checking port $port..." -ForegroundColor Cyan

try {
    $processes = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($processes) {
        foreach ($proc in $processes) {
            Write-Host "Killing process $proc on port $port" -ForegroundColor Yellow
            Stop-Process -Id $proc -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        Write-Host "Port $port freed" -ForegroundColor Green
    } else {
        Write-Host "Port $port is free" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not check port (may need admin rights): $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting backend..." -ForegroundColor Cyan
Write-Host ""

dotnet run

