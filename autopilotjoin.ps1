Set-executionpolicy bypass -scope process
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#PowerShell.exe -ExecutionPolicy Bypass
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -Online
