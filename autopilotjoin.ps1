Set-executionpolicy bypass -scope process
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#PowerShell.exe -ExecutionPolicy Bypass
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -name Get-WindowsAutopilotInfo -Force

$groupTag = Read-Host "Enter group tag (leave empty to skip)"
if ([string]::IsNullOrEmpty($groupTag)) {
    Get-WindowsAutopilotInfo -Online
} else {
    Get-WindowsAutopilotInfo -Online -GroupTag $groupTag
}
