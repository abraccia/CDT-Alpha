# Security_Hardening.ps1
# Windows security hardening configurations

function Set-DomainControllerSecurity {
    Write-Log "Applying Domain Controller specific security settings..."
    
    # LDAP security settings
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "LDAPServerIntegrity" -Value 2 -Force
    
    # Disable SMBv1
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    
    # Enable SMB signing
    Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
    
    # Configure password policy via registry (if GPO not available)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name "DisablePasswordChange" -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name "SignSecureChannel" -Value 1 -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name "SealSecureChannel" -Value 1 -Force
}

function Set-SMBServerSecurity {
    Write-Log "Applying SMB Server security settings..."
    
    # Disable SMBv1
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    
    # Enable SMB encryption
    Set-SmbServerConfiguration -EncryptData $true -Force
    
    # Require security signature
    Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
    
    # Configure share permissions (example)
    $shares = Get-SmbShare
    foreach ($share in $shares) {
        if ($share.Name -notlike "*$" -and $share.Name -ne "IPC$") {
            # Remove everyone permissions and set appropriate ACLs
            # This would need to be customized per share
        }
    }
}

function Set-WorkstationSecurity {
    Write-Log "Applying Workstation security settings..."
    
    # Disable SMBv1
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    
    # Disable LLMNR via registry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -Force -ErrorAction SilentlyContinue
    
    # Disable NetBIOS over TCP/IP (for workstations)
    $nics = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    foreach ($nic in $nics) {
        $nic.SetTcpipNetbios(2)  # 2 = Disable NetBIOS
    }
}

function Enable-WindowsAuditing {
    Write-Log "Enabling Windows auditing..."
    
    # Enable PowerShell logging
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1 -Force
    
    # Enable command line process auditing
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -Force
    
    # Configure audit policy using auditpol
    $auditCategories = @(
        "Logon/Logoff",
        "Object Access", 
        "Privilege Use",
        "Detailed Tracking",
        "Policy Change",
        "Account Management",
        "DS Access",
        "Account Logon"
    )
    
    foreach ($category in $auditCategories) {
        try {
            auditpol /set /category:"$category" /success:enable /failure:enable
        }
        catch {
            Write-Log "Failed to set audit policy for $category" -Type "WARNING"
        }
    }
}

function Disable-UnnecessaryServices {
    Write-Log "Disabling unnecessary services..."
    
    $servicesToDisable = @(
        "Telnet",
        "W3SVC",        # IIS
        "FTPSVC",       # FTP
        "SNMP",
        "RemoteRegistry",
        "Spooler",      # Print Spooler (if printing not needed)
        "XboxGipSvc",   # Xbox Accessory Management
        "XboxNetApiSvc" # Xbox Live Auth Manager
    )
    
    foreach ($service in $servicesToDisable) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc) {
                Stop-Service -Name $service -Force
                Set-Service -Name $service -StartupType Disabled
                Write-Log "Disabled service: $service"
            }
        }
        catch {
            Write-Log "Could not disable $service : $($_.Exception.Message)" -Type "WARNING"
        }
    }
}

function Set-LSAProtections {
    Write-Log "Configuring LSA protections..."
    
    # Enable LSA Protection
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -Value 1 -Force
    
    # Disable WDigest credential caching
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -Value 0 -Force
    
    # Restrict anonymous access
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Value 1 -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymousSAM" -Value 1 -Force
}

# Helper function for logging
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Type] $Message"
}