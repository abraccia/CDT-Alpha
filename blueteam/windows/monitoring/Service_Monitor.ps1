# Service_Monitor.ps1
# Windows service monitoring and alerting

param(
    [string]$LogPath = "C:\BlueTeam\Logs",
    [int]$CheckInterval = 180  # 3 minutes to match scoring
)

$MonitorLog = Join-Path $LogPath "service_monitor.log"

function Write-MonitorLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $MonitorLog -Value $logEntry
}

function Get-SystemServices {
    $ip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString
    
    switch ($ip) {
        "10.1.0.7" { 
            # CEO Workstation - RDP
            return @("TermService", "SessionEnv")  # RDP services
        }
        "10.1.0.8" { 
            # HR Workstation - RDP  
            return @("TermService", "SessionEnv")
        }
        "10.1.0.9" { 
            # SMB Server - SMB
            return @("LanmanServer", "LanmanWorkstation")
        }
        "10.1.0.10" { 
            # Domain Controller - LDAP
            return @("NTDS", "Netlogon", "KDC")
        }
        default { 
            return @() 
        }
    }
}

function Monitor-Services {
    $services = Get-SystemServices
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-MonitorLog "=== Service Status Check - $timestamp ==="
    
    foreach ($service in $services) {
        try {
            $svc = Get-Service -Name $service -ErrorAction Stop
            if ($svc.Status -eq 'Running') {
                Write-MonitorLog "$service : RUNNING"
            } else {
                Write-MonitorLog "$service : STOPPED"
                
                # Attempt to restart critical services
                if ($service -in @("TermService", "LanmanServer", "NTDS")) {
                    Start-Service -Name $service -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 5
                    $restarted = Get-Service -Name $service
                    if ($restarted.Status -eq 'Running') {
                        Write-MonitorLog "   [+] Restarted $service"
                    } else {
                        Write-MonitorLog "   [!] Failed to restart $service"
                    }
                }
            }
        }
        catch {
            Write-MonitorLog "$service : NOT FOUND"
        }
    }
    
    # Check network connections for scored services
    Write-MonitorLog "--- Network Connections ---"
    $ports = @(3390, 445, 389)  # RDP, SMB, LDAP
    foreach ($port in $ports) {
        $connections = netstat -an | Select-String ":$port\s"
        if ($connections) {
            Write-MonitorLog "Port $port : LISTENING"
        } else {
            Write-MonitorLog "Port $port : NOT LISTENING"
        }
    }
    
    Write-MonitorLog ""
}

# Main monitoring loop
Write-MonitorLog "Starting service monitor on $(hostname)"
while ($true) {
    Monitor-Services
    Start-Sleep -Seconds $CheckInterval
}