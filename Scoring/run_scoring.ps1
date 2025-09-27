# run_every_minute.ps1

# Checks the scoring every minute

while ($true) {
    .\scoring.ps1 10.0.0.10 10.0.0.11 #REPLACE IPS
    Write-Host "---- $(Get-Date) ----"
    Start-Sleep -Seconds 60
}
