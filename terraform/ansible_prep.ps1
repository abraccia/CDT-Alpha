#ps1

Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString "Password123!" -AsPlainText -Force) -PasswordNeverExpires
New-LocalUser -Name "ansible" -Password (ConvertTo-SecureString "Password123!" -AsPlainText -Force) -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "ansible"
# Bind to the local user account
#$usr = [ADSI]"WinNT://$env:ComputerName/Administrator,user"

# Set the 'PasswordExpired' property to 1 to enable "User must Change password at next logon"
#$usr.PasswordExpired = 0

# Save the changes
#$usr.SetInfo()

# Optionally, display a message indicating the change was made

Get-WindowsCapability -Name OpenSSH.Server* -Online |
    Add-WindowsCapability -Online
Set-Service -Name sshd -StartupType Automatic -Status Running

$firewallParams = @{
    Name        = 'sshd-Server-In-TCP'
    DisplayName = 'Inbound rule for OpenSSH Server (sshd) on TCP port 22'
    Action      = 'Allow'
    Direction   = 'Inbound'
    Enabled     = 'True'
    Profile     = 'Any'
    Protocol    = 'TCP'
    LocalPort   = 22
}
New-NetFirewallRule @firewallParams

$shellParams = @{
    Path         = 'HKLM:\SOFTWARE\OpenSSH'
    Name         = 'DefaultShell'
    Value        = 'C:\Windows\SI think that would be answered by the topology in the packetystem32\WindowsPowerShell\v1.0\powershell.exe'
    PropertyType = 'String'
    Force        = $true
}
New-ItemProperty @shellParams

#Remove-Item -Path 'C:\ProgramData\ssh\sshd_config'

New-Item -Path 'C:\ProgramData\ssh\sshd_config' -Value "Port 22`nListenAddress 0.0.0.0`nAuthorizedKeysFile .ssh/authorized_keys`nPermitRootLogin yes`nPasswordAuthentication yes" -Force

New-Item -Type Directory -Path 'C:\Users\ansible\.ssh'

Add-Content -Path 'C:\Users\ansible\.ssh\authorized_keys' -Value 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwP0b5HMErj5crcx6sg1CVLc2d0MfupzxltH8Mi/D5t8Dda0BqI/PMwPdZDUb4I5GgwONBxerkJOhPgXmIIrWDlroQ5NzFX0EFVY9tEKy6Iir+Uj19ZD2Sz9vitzRgkJtAj4t/nzXeERNaSgDvNDf9uvZUTSpcG+idsbhCIC/kUE5zgLXaG2wGGgaGbrMqkrAccv9O6OhMuxz8AMnfoDLVpvaMLKNxzeIFfph2W5FalPXv5okbwbuJ0ORFzbl1K/JesrTB+TZ4FfGebu9ikP/ZFOhjcVgmjJWZgszCKm1KLwhTdJSYuZbnWokyAayQRY3PDxgg/1FWhBEJzFqYbehoiUM5c7rcGn999qNAXy9d0AAY3xgLYeY6mesrKlaRYp3XAJmTQTrRPPpji2QmiahUcjvo4etHzR+3MahVP83/U3+Ew2wZSgpqPUlU+zzn3gFEihaChWr07TQPsVmiyTPUtBQst7IS63yhqqfra9d+VXuh5qLaqs6/MhuP5G/0YLM=' -Force