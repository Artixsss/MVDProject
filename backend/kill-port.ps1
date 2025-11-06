# Kill process on port 5029
$port = 5029
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

