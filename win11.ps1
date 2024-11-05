# Custom Image URL
#$CustomImageFile = "http://wds/esd/win10pro21H2.esd"; $index = 8 # Windows 10 Image
$CustomImageFile = "http://wds/esd/win11pro21H2drivers.esd"; $Index = 1 # Windows 11 Image

function Show-Menu {
    param (
        [string]$Title = 'Image Selection'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Windows 11 Pro (Generic)"
    Write-Host "2: Windows 11 Pro (All Drivers)"
    Write-Host "3: Windows 10 Pro (Generic)"
    Write-Host "4: Surface Pro 9"
    Write-Host "5: Lenovo ThinkBook G6"
    Write-Host "6: Surface Go 4"
    Write-Host "7: Lenovo ThinkCentre M70s G3"
    Write-Host "8: Lenovo ThinkCentre G7"
    
}


do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    '1' {
    write-host 'Using Windows 11 Pro (Generic) Image'
    $CustomImageFile = "http://wds/esd/Win11Pro_Generic.esd"
    $selection = 'q'
    } '2' {
    write-host 'Using Windows 11 Pro (All Drivers) Image'
    $CustomImageFile = "http://wds/esd/Win11Pro_AllDrivers.esd"
    $selection = 'q'
    } '3' {
    write-host 'Using Windows 10 Pro (Generic) Image'
    $CustomImageFile = "http://wds/esd/Win10Pro_Generic.esd"
    $selection = 'q'
    } '4' {
    write-host 'Using Surface Pro 9 image'
    $CustomImageFile = "http://wds/esd/Win11_SurfacePro9.esd"
    $selection = 'q'
    } '5' {
    write-host 'Using Lenovo ThinkBook G6 image'
    $CustomImageFile = "http://wds/esd/Win11_LenovoThinkBookG6.esd"
    $selection = 'q'
    } '6' {
    write-host 'Using Surface Go 4 image'
    $CustomImageFile = "http://wds/esd/Win11_SurfaceGo4.esd"
    $selection = 'q'
    } '7' {
    write-host 'Using ThinkCentre M70s G3 image'
    $CustomImageFile = "http://wds/esd/Win11_ThinkCentreM70sG3.esd"
    $selection = 'q'
    } '8' {
    write-host 'Using ThinkBook G7 image'
    $CustomImageFile = "http://wds/esd/Win11_LenovoThinkBookG7.esd"
    $selection = 'q'
    }
    
    }
    
 }
 until ($selection -eq 'q')

# Set allowed ASCII character codes to Uppercase letters (65..90), 
$charcodes = 65..90

# Convert allowed character codes to characters
$allowedChars = $charcodes | ForEach-Object { [char][byte]$_ }

$LengthOfName = 10
# Generate computer name
$randomName = ($allowedChars | Get-Random -Count $LengthOfName) -join ""
 
Add-Type -AssemblyName Microsoft.VisualBasic
$ComputerName = [Microsoft.VisualBasic.Interaction]::InputBox('Computer Name', 'Computer Name', $randomName)
Write-Host "Computer will be renamed to $ComputerName once complete"
Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"

Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine

if ((Get-MyComputerModel) -match 'Virtual') {

Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"

Set-DisRes 1600

}

#Make sure I have the latest OSD Content

#Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

#Install-Module OSD -RequiredVersion 22.5.10.1 -Force #Get specific version
#Install-Module OSD -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"

#Import-Module OSD -RequiredVersion 22.5.10.1 -Force #Import specific version
Import-Module OSD

######################
# Build variables
######################
    #=======================================================================
    # Create Hashtable
    #=======================================================================
    $Global:StartOSDCloud = $null
    $Global:StartOSDCloud = [ordered]@{
        DriverPackUrl = $null
        DriverPackName = "None"
        DriverPackOffline = $null
        DriverPackSource = $null
        Function = $MyInvocation.MyCommand.Name
        GetDiskFixed = $null
        GetFeatureUpdate = $null
        GetMyDriverPack = $null
        ImageFileOffline = $null
        ImageFileName = $null
        ImageFileSource = $null
        ImageFileTarget = $null
        ImageFileUrl = $CustomImageFile
        IsOnBattery = Get-OSDGather -Property IsOnBattery
        Manufacturer = $Manufacturer
        OSBuild = $OSBuild
        OSBuildMenu = $null
        OSBuildNames = $null
        OSEdition = $OSEdition
        OSEditionId = $null
        OSEditionMenu = $null
        OSEditionNames = $null
        OSLanguage = $OSLanguage
        OSLanguageMenu = $null
        OSLanguageNames = $null
        OSLicense = $null
        OSImageIndex = $Index
        Product = "none"
        Screenshot = $null
        SkipAutopilot = $SkipAutopilot
        SkipODT = $true
        TimeStart = Get-Date
        updateFirmware = $false
        ZTI = $true
    }


#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green "Start OSDCloud"

#Start-OSDCloud -OSLanguage en-gb -OSBuild 21H2 -OSEdition Pro -ZTI -SkipAutopilot 
#Start-OSDCloud -ImageFileUrl $CustomImageFile -ImageIndex $Index -ZTI -firmware -SkipAutopilot -SkipODT
#Start-OSDCloud -ImageFileUrl $CustomImageFile -ImageIndex $Index -firmware -SkipAutopilot -SkipODT

Invoke-OSDCloud

#Restart from WinPE
Write-Host "Savings computer name to file"
#Set-Content -Path "C:\osdcloud\computername.txt" -Value $ComputerName

# Output name to C:\temp
if (-not (Test-Path -Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp"
}
Set-Content -Path "C:\temp\computername.txt" -Value $ComputerName

Write-Host -ForegroundColor Green "Restarting in 20 seconds!"

Start-Sleep -Seconds 20

wpeutil reboot
