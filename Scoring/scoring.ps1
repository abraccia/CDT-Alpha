#!/usr/bin/env pwsh
# Minimal concurrent scoring (ICMP + TCP) in PowerShell 7+

# ---- CONFIG -------------------------------------------------
$Hosts = @(
  '10.1.0.1','10.1.0.2','10.1.0.3','10.1.0.10','10.1.0.11','10.1.0.12'
)

# Each service is a hashtable with Label/Type/Port (Port ignored for icmp)
$Services = @(
  @{ Label='ICMP'; Type='icmp'; Port=$null },
  @{ Label='SSH' ; Type='tcp' ; Port=22    },
  @{ Label='HTTP'; Type='tcp' ; Port=80    },
  @{ Label='FTP' ; Type='tcp' ; Port=21    },
  @{ Label='SMTP'; Type='tcp' ; Port=25    },
  @{ Label='LDAP'; Type='tcp' ; Port=389   },
  @{ Label='RDP' ; Type='tcp' ; Port=3389  },
  @{ Label='MySQL';Type='tcp' ; Port=3306  }
)

$IntervalSec   = 60
$TcpTimeoutMs  = 2000
$ThrottleLimit = 64

# ---- CHECKS -------------------------------------------------
function Test-IcmpUp {
  param([string]$Ip)
  try {
    # Fast, quiet single echo
    Test-Connection -TargetName $Ip -Count 1 -Quiet -TimeoutSeconds 1 -ErrorAction SilentlyContinue
  } catch { $false }
}

function Test-TcpUp {
  param([string]$Ip, [int]$Port, [int]$TimeoutMs)
  $client = [System.Net.Sockets.TcpClient]::new()
  try {
    $iar = $client.BeginConnect($Ip, $Port, $null, $null)
    $ok = $iar.AsyncWaitHandle.WaitOne($TimeoutMs)
    if ($ok -and $client.Connected) { $true } else { $false }
  } catch { $false } finally {
    try { $client.Close() } catch {}
  }
}

# ---- RENDER -------------------------------------------------
function Show-Table {
  param([object[]]$Rows)
  $hostWidth=15; $svcWidth=10; $stWidth=6
  $sep = ('-' * ($hostWidth + $svcWidth + $stWidth + 4))
  "{0}" -f $sep
  "{0,-$hostWidth}  {1,-$svcWidth}  {2,-$stWidth}" -f 'Host','Service','Status'
  "{0}" -f $sep
  $Rows | Sort-Object Host, Service | ForEach-Object {
    "{0,-$hostWidth}  {1,-$svcWidth}  {2,-$stWidth}" -f $_.Host, $_.Service, $_.Status
  }
  "{0}" -f $sep
}

# ---- MAIN LOOP ----------------------------------------------
try {
  while ($true) {
    $combos = foreach ($h in $Hosts) { foreach ($s in $Services) {
      [pscustomobject]@{ Host=$h; Service=$s.Label; Type=$s.Type; Port=$s.Port }
    }}

    $results = $combos | ForEach-Object -Parallel {
      if ($using:PSStyle) { } # no-op to avoid remoting style issues
      if ($_.Type -eq 'icmp') {
        $ok = & ${function:Test-IcmpUp} -Ip $_.Host
      } else {
        $ok = & ${function:Test-TcpUp} -Ip $_.Host -Port $_.Port -TimeoutMs $using:TcpTimeoutMs
      }
      [pscustomobject]@{ Host=$_.Host; Service=$_.Service; Status=($(if($ok){'UP'}else{'DOWN'})) }
    } -ThrottleLimit $ThrottleLimit

    # Clear screen and draw
    if ($Host.UI.RawUI) { $Host.UI.RawUI.WindowTitle = "Scoring Simple MT" }
    Write-Host "`e[2J`e[H" -NoNewline
    Show-Table -Rows $results

    Start-Sleep -Seconds $IntervalSec
  }
}
catch [System.Exception] {
  Write-Host "Error: $($_.Exception.Message)"
}
