# Setup_Windows.ps1
# Quick setup script for competition preparation

Write-Host "=== Windows Blue Team Setup ===" -ForegroundColor Green

# Create directory structure
$directories = @(
    "C:\BlueTeam",
    "C:\BlueTeam\Scripts", 
    "C:\BlueTeam\Logs",
    "C:\BlueTeam\Backups"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir"
    }
}

# Download scripts from repository (placeholder URLs)
$scripts = @{
    "Windows5min.ps1" = "https://raw.githubusercontent.com/abraccia/CDT-Alpha/blueteam/blueteam/windows/hardening/Windows5min.ps1"
    "ADHardening.ps1" ="https://raw.githubusercontent.com/abraccia/CDT-Alpha/blueteam/blueteam/windows/hardening/ADHardening.ps1"
    "Service_Monitor.ps1" = "https://raw.githubusercontent.com/abraccia/CDT-Alpha/blueteam/blueteam/windows/monitoring/Service_Monitor.ps1"
    "pull_sysinternals.ps1" = "https://raw.githubusercontent.com/abraccia/CDT-Alpha/blueteam/blueteam/windows/scripts/pull_sysinternals.ps1"
}

foreach ($script in $scripts.GetEnumerator()) {
    $destination = "C:\BlueTeam\Scripts\$($script.Key)"
    try {
        Invoke-WebRequest -Uri $script.Value -OutFile $destination
        Write-Host "Downloaded: $($script.Key)"
    }
    catch {
        Write-Host "Failed to download $($script.Key), creating placeholder" -ForegroundColor Yellow
        "# Placeholder for $($script.Key)" | Out-File -FilePath $destination
    }
}

# Run initial hardening
Write-Host "`nRunning initial hardening..." -ForegroundColor Yellow
& "C:\BlueTeam\Scripts\Windows5min.ps1"

# Start monitoring service
Write-Host "`nStarting service monitor..." -ForegroundColor Yellow
Start-Process PowerShell -ArgumentList "-File C:\BlueTeam\Scripts\Service_Monitor.ps1" -WindowStyle Hidden

# Start log forwarding
Write-Host "Pulling sysinternals..." -ForegroundColor Yellow  
Start-Process PowerShell -ArgumentList "-File C:\BlueTeam\Scripts\pull_sysinternals.ps1" -WindowStyle Hidden

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Scripts location: C:\BlueTeam\Scripts" -ForegroundColor Cyan
Write-Host "Logs location: C:\BlueTeam\Logs" -ForegroundColor Cyan