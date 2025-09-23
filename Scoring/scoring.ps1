param([string[]]$Hosts)

foreach ($h in $Hosts) {
  if (-not $h) { continue }
  Write-Host "== $h =="

  # ICMP
  if (Test-Connection -ComputerName $h -Count 1 -Quiet) { "ICMP        UP" } else { "ICMP        DOWN" }

  # TCP ports
  if ((Test-NetConnection -ComputerName $h -Port 22).TcpTestSucceeded)   { "SSH (22)    UP" } else { "SSH (22)    DOWN" }
  if ((Test-NetConnection -ComputerName $h -Port 21).TcpTestSucceeded)   { "FTP (21)    UP" } else { "FTP (21)    DOWN" }
  if ((Test-NetConnection -ComputerName $h -Port 445).TcpTestSucceeded)  { "SMB (445)   UP" } else { "SMB (445)   DOWN" }
  if ((Test-NetConnection -ComputerName $h -Port 3389).TcpTestSucceeded) { "RDP (3389)  UP" } else { "RDP (3389)  DOWN" }
  if ((Test-NetConnection -ComputerName $h -Port 25).TcpTestSucceeded)   { "SMTP (25)   UP" } else { "SMTP (25)   DOWN" }

  # HTTP / HTTPS
  try { $r=Invoke-WebRequest "http://$h/" -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400) {"HTTP        UP"} else {"HTTP        DOWN"} } catch {"HTTP        DOWN"}
  try { $r=Invoke-WebRequest "https://$h/" -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400) {"HTTPS       UP"} else {"HTTPS       DOWN"} } catch {"HTTPS       DOWN"}

  # WordPress (simple marker)
  $wpUp = $false
  try { $b = Invoke-WebRequest "http://$h/wp-login.php" -UseBasicParsing -TimeoutSec 3; if ($b.Content -match 'wp-login|WordPress') { $wpUp = $true } } catch {}
  if (-not $wpUp) { try { $b = Invoke-WebRequest "http://$h/" -UseBasicParsing -TimeoutSec 3; if ($b.Content -match 'wp-|WordPress') { $wpUp = $true } } catch {} }
  if ($wpUp) { "WordPress  UP" } else { "WordPress  DOWN" }
}
