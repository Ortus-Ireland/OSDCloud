Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"

Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine

if ((Get-MyComputerModel) -match 'Virtual') {

Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"

Set-DisRes 1600

}

#$ScriptFromGitHub = Invoke-Restmethod https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/Diskpart-Clean.ps1
#Invoke-Expression $ScriptFromGitHub

#$ScriptFromGitHub = Invoke-Restmethod https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/New-OSDPartitionSystem.ps1
#Invoke-Expression $ScriptFromGitHub
#Invoke-Restmethod https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/New-OSDPartitionSystem.ps1


#Make sure I have the latest OSD Content

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

Install-Module OSD -RequiredVersion 22.5.10.1 -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"

Import-Module OSD -Force


#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green "Start OSDCloud"

Start-OSDCloud -OSLanguage en-gb -OSBuild 21H2 -OSEdition Pro -ZTI

#Restart from WinPE

Write-Host -ForegroundColor Green "Restarting in 20 seconds!"

Start-Sleep -Seconds 20

wpeutil reboot
