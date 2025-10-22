[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $OutputFileName = ""
)
#To do list:
#Functions needed
#generate secure passwords
function get-strongpwd {
    $basepwd = "DefaultPassword123!"
    $date = get-date -format yyyy-MM-dd
    $objRand = new-object random
    $num = $objRand.next(1, 500)
    $finalPWD = $basepwd + "!" + $date + "!" + $num
    $finalPWD
}
#Get local users and document them
function get-lusers {
    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $adsi.Children | Where-Object { $_.SchemaClassName -eq "user" } | Foreach-Object {
        $groups = $_.Groups() | Foreach-Object { $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null) }
        $namey = $_.name
        if ($null = $groups) {
            $groups = "N/A"
        }
        $namey 
    }
}

# Create new local Admin user - ONLY FOR WORKSTATIONS
function add-backupadmin {
    # Check if this is a domain controller first
    if ((Get-WindowsFeature -Name AD-Domain-Services).Installed) {
        Write-Warning "Domain Controller detected - skipping local admin creation"
        return
    }
    $Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"
    $passwd = get-strongpwd
    $LocalAdmin = $Computer.Create("User", "estew")
    $LocalAdmin.SetPassword($passwd)
    $LocalAdmin.SetInfo()
    $LocalAdmin.FullName = "Backup Admin Account"
    $LocalAdmin.SetInfo()
    # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
    $LocalAdmin.UserFlags = 64 + 65536
    $LocalAdmin.SetInfo()
    
    # Add to administrators group
    $Group = [ADSI]"WinNT://$Env:COMPUTERNAME/Administrators,group"
    $Group.Add("WinNT://$Env:COMPUTERNAME/estew")
}

# Detect system
function get-system {
    $ip = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
    
    switch ($ip) {
        "10.1.0.7" { return "CEO Workstation" }
        "10.1.0.8" { return "HR Workstation" } 
        "10.1.0.9" { return "SMB Server" }
        "10.1.0.10" { return "Domain Controller" }
        default { return "Unknown" }
    }
}

$system = get-system
Write-Output "Detected system: $system"
Write-Output "Adding backup administrator account"
add-backupadmin
Write-Output "Generating list of local users"
$users = get-lusers

# Password changes - skip on Domain Controller for domain accounts
if ($system -ne "Domain Controller") {
    Write-Output "Changing local user passwords"
    $fdate = get-date -format o | ForEach-Object { $_ -replace ":", "." }
    foreach ($user in $users) {
        try {
            $plainTextPWD = get-strongpwd
            Write-Output "Setting $user to new password"
            $securePWD = ConvertTo-SecureString -String $plainTextPWD -AsPlainText -Force
            Set-LocalUser -Name $user -Password $securePWD
            "$user,$plainTextPWD" | Out-File -FilePath "$env:COMPUTERNAME-$fdate-localusers.txt" -Append
        }
        catch {
            Write-Warning "Failed to change password for user: $user"
            Write-Warning $_.Exception.Message
        }
    }
}

#configure windows firewall
Write-Output "Configuring Windows Firewall"
# Netsh.exe advfirewall firewall add rule name="Block Notepad.exe network connections" program="%systemroot%\system32\notepad.exe" protocol=tcp dir=out enable=yes action=block profile=any
# Netsh.exe advfirewall firewall add rule name="Block regsvr32.exe network connections" program="%systemroot%\system32\regsvr32.exe" protocol=tcp dir=out enable=yes action=block profile=any
# Netsh.exe advfirewall firewall add rule name="Block calc.exe network connections" program="%systemroot%\system32\calc.exe" protocol=tcp dir=out enable=yes action=block profile=any
# Netsh.exe advfirewall firewall add rule name="Block mshta.exe network connections" program="%systemroot%\system32\mshta.exe" protocol=tcp dir=out enable=yes action=block profile=any
# Netsh.exe advfirewall firewall add rule name="Block wscript.exe network connections" program="%systemroot%\system32\wscript.exe" protocol=tcp dir=out enable=yes action=block profile=any
# Netsh.exe advfirewall firewall add rule name="Block cscript.exe network connections" program="%systemroot%\system32\cscript.exe" protocol=tcp dir=out enable=yes action=block profile=any
# Netsh.exe advfirewall firewall add rule name="Block runscripthelper.exe network connections" program="%systemroot%\system32\runscripthelper.exe" protocol=tcp dir=out enable=yes action=block profile=any
# Netsh.exe Advfirewall set allprofiles state on
#Powershell version
Write-Output "Adding outbound rules to prevent LOLBins."
$blockedPrograms = @(
    "notepad.exe", "regsvr32.exe", "calc.exe", "mshta.exe",
    "wscript.exe", "cscript.exe", "runscripthelper.exe",
    "msbuild.exe", "installutil.exe", "regasm.exe", "regsvcs.exe"
)
foreach ($program in $blockedPrograms) {
    $params = @{
        "DisplayName" = "Block Network Connections-$program"
        "Direction"   = "Outbound"
        "Action"      = "Block"
        "Program"     = "%systemroot%\system32\$program"
        "Enabled"     = "True"
    }
    try {
        New-NetFirewallRule @params -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to create firewall rule for $program"
    }
}

# Rustdesk should be allowed regardless (https://github.com/rustdesk/rustdesk/commit/f47f2a91512feba30f0907f08690bbbae2311e75), but just in case
$rustdeskTCPRules = @(
    @{Name="RustDesk-TCP-21114"; Port=21114},
    @{Name="RustDesk-TCP-21115"; Port=21115},
    @{Name="RustDesk-TCP-21116"; Port=21116},
    @{Name="RustDesk-TCP-21117"; Port=21117},
    @{Name="RustDesk-TCP-21118"; Port=21118},
    @{Name="RustDesk-TCP-21119"; Port=21119}
)

$rustdeskUDPRules = @(
    @{Name="RustDesk-UDP-21116"; Port=21116}
)

foreach ($rule in $rustdeskTCPRules) {
    if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol TCP -LocalPort $rule.Port -Action Allow -Enabled True
        Write-Host "- Added TCP rule: $($rule.Name)"
    }
}

foreach ($rule in $rustdeskUDPRules) {
    if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol UDP -LocalPort $rule.Port -Action Allow -Enabled True
        Write-Host "- Added UDP rule: $($rule.Name)"
    }
}

# add rules to filter inbound
#Commented out just to be used as a reference
# $Params = @{ "DisplayName" = "Block-Inbound-SMB-445"
#              "Direction" = "Inbound"
#              "Port" = "445"}
# New-NetFirewallRule @Params

#enable firewall, this terrifies me
if ($system -eq "Domain Controller") {
    # Less restrictive for DC
    $Params = @{
        "Enabled"              = "true"
        "DefaultInboundAction" = "Block"
        "LogAllowed"           = "True"
        "LogBlocked"           = "True"
        "LogFileName"          = "%windir%\system32\logfiles\firewall\pfirewall.log"
    }
} else {
    # More restrictive for workstations/server
    $Params = @{
        "Enabled"              = "true"
        "DefaultInboundAction" = "Block"
        "LogAllowed"           = "True"
        "LogBlocked"           = "True"
        "LogIgnored"           = "True"
        "LogFileName"          = "%windir%\system32\logfiles\firewall\pfirewall.log"
        "LogMaxSizeKilobytes"  = "32767"
        "NotifyOnListen"       = "True"
    }
}

#Baseline security hardening
Write-Output "Performing some baseline hardening...."

# SMB Configuration
if ($system -eq "SMB Server") {
    Write-Output "Configuring SMB Server settings"
    # Keep SMB v2/v3 enabled for file sharing
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Type DWORD -Value 0 -Force
    Set-SmbServerConfiguration –EncryptData $true -Confirm:$false
} else {
    Write-Output "Disabling SMB v1/v2"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Type DWORD -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB2" -Type DWORD -Value 0 -Force
}
# #disable smb v1
# Write-Output "Disabling SMB V1 via RegKey"
# Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -name "SMB1" -Type DWORD -Value 0 -Force
# #disable smb v2
# Write-Output "Disabling SMB V2 via RegKey"
# Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -name "SMB2" -Type DWORD -Value 0 -Force
# #Enable smb encryption for 2012r2 or higher
# Write-Output "Enabling SMB Encryption"
# Set-SmbServerConfiguration –EncryptData $true -Confirm:$false
# #Disable SMB null sessions
# #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -name "SMB1" -Type DWORD -Value 0 -Force
# Write-Output "Disabling SMB null sessions."

# LSA Protection - Skip on Domain Controller if it causes issues
if ($systemType -ne "Domain Controller") {
    Write-Output "Enabling LSA protections"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -Type DWORD -Value 1 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -name "RestrictAnonymous" -Type DWORD -Value 1 -Force
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -name "RestrictAnonymousSAM" -Type DWORD -Value 1 -Force
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -name "EveryoneIncludesAnonymous" -Type DWORD -Value 0 -Force

}


Write-Output "Applying common security settings"

# Disable SMB null sessions
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymousSAM" -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name "EveryoneIncludesAnonymous" -Type DWORD -Value 0 -Force
# Disable SMB Compression
# https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-0796
Write-Output "Disabling SMB Compression"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v DisableCompression /t REG_DWORD /d 1 /f
# New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\" -Name "Parameters"
# Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -name "DisableCompression" -Type DWORD -Value 1 -Force
# Disable LLMNR
New-Item -Path "HKLM:\Software\policies\Microsoft\Windows NT" -Name "DNSClient" -Force
Set-ItemProperty -Path "HKLM:\Software\policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Type DWORD -Value 0 -Force
# WDigest hardening
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders" -Name "WDigest" -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -Type DWORD -Value 0 -Force
# Credential Guard
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\" -Name "CredentialsDelegation" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" -Name "AllowProtectedCreds" -Type DWORD -Value 1 -Force
#Harden LSA to protect from mimikatz etc
#reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\LSASS.exe" /v AuditLevel /t REG_DWORD /d 00000008 /f
Write-Output "Enabling protections for LSA"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" -name "AuditLevel" -Type DWORD -Value 8 -Force
Write-Output "Enabling PPL for LSA"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -name "RunAsPPL" -Type DWORD -Value 1 -Force
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders" -Name "WDigest"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -name "UseLogonCredential" -Type DWORD -Value 0 -Force
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\" -Name "CredentialsDelegation"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" -name "AllowProtectedCreds" -Type DWORD -Value 1 -Force

if ($system -like "*Workstation*") {
    $nics = Get-WmiObject win32_NetworkAdapterConfiguration
    foreach ($nic in $nics) {
        $nic.SetTcpipNetbios(2) # 2 = disable netbios
    }
}
#enable powershell logging
Write-Output "Enabling powershell logging"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" /v EnableModuleLogging /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f

# #Bump windows event log size
# Write-Output "Increasing the Windows Event Log Size to 4GB"
# $Logs = Get-Eventlog -List | Select-Object -ExpandProperty Log
# foreach ($log in $logs) {
#     Limit-Eventlog -Logname $Logs -MaximumSize 640000 -OverflowAction OverwriteAsNeeded
# }

$servicesToDisable = @(
    "Telnet",
    "W3SVC",  # IIS if not needed
    "FTPSVC", # FTP if not needed on non-FTP servers
    "SNMP",
    "RemoteRegistry"
)

foreach ($service in $servicesToDisable) {
    try {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Disabled service: $service" -ForegroundColor Green
    } catch {
        Write-Host "Could not disable $service (may not exist)" -ForegroundColor Yellow
    }
}

auditpol /set /category:"System" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"Detailed Tracking" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"DS Access" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable