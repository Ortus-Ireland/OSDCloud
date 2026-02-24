Set-executionpolicy bypass -scope process
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#PowerShell.exe -ExecutionPolicy Bypass
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -name Get-WindowsAutopilotInfo -Force

$groupTag = Read-Host "Enter group tag (leave empty to skip)"
$computerName = Read-Host "Enter computer name (leave empty to skip)"

$params = @{
    Online = $true
}

if (-not [string]::IsNullOrEmpty($groupTag)) {
    $params.GroupTag = $groupTag
}

if (-not [string]::IsNullOrEmpty($computerName)) {
    $params.AssignedComputerName = $computerName
}

Get-WindowsAutopilotInfo @params
