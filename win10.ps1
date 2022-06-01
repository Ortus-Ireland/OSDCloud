# Custom Image URL
#$CustomImageFile = "http://wds/esd/win10pro21H2.esd"; $index = 5 # Windows 10 Image
$CustomImageFile = "http://wds/esd/win11pro21H2.esd"; $Index = 1 # Windows 11 Image

Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"

Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine

if ((Get-MyComputerModel) -match 'Virtual') {

Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"

Set-DisRes 1600

}

#Make sure I have the latest OSD Content

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

#Install-Module OSD -RequiredVersion 22.5.10.1 -Force #Get specific version
Install-Module OSD -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"

#Import-Module OSD -RequiredVersion 22.5.10.1 -Force #Import specific version
Import-Module OSD

#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green "Start OSDCloud"

#Start-OSDCloud -OSLanguage en-gb -OSBuild 21H2 -OSEdition Pro -ZTI -SkipAutopilot 
Start-OSDCloud -ImageFileUrl $CustomImageFile -ImageIndex $Index -ZTI -firmware -SkipAutopilot -SkipODT
#Start-OSDCloud -ImageFileUrl $CustomImageFile -ImageIndex $Index -firmware -SkipAutopilot -SkipODT

#Restart from WinPE

Write-Host -ForegroundColor Green "Restarting in 20 seconds!"

Start-Sleep -Seconds 20

wpeutil reboot
