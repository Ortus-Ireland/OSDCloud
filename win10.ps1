Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"

Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine

if ((Get-MyComputerModel) -match 'Virtual') {

Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"

Set-DisRes 1600

}

#Make sure I have the latest OSD Content

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

Install-Module OSD -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"

Import-Module OSD -Force

$ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/Diskpart-Clean.ps1 -UseBasicParsing
Invoke-Expression $($ScriptFromGitHub.Content)

$ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/New-OSDPartitionSystem.ps1 -UseBasicParsing
Invoke-Expression $($ScriptFromGitHub.Content)

#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green "Start OSDCloud"

Start-OSDCloud -OSLanguage en-gb -OSBuild 21H2 -OSEdition Pro -ZTI

#Restart from WinPE

Write-Host -ForegroundColor Green "Restarting in 20 seconds!"

Start-Sleep -Seconds 20

wpeutil reboot
