### Ekco MSP - OSDCloud Image Selection ###
### Dynamically reads enabled devices from imageStaging.json via IIS ###

$configUrl = "http://wds/imageStaging/imageStaging.json"
$Index = 1

function Get-EsdUrl([string]$Name) {
    if ($Name -match '^Win\d') { return "http://wds/esd/$Name.esd" }
    return "http://wds/esd/Win11_$Name.esd"
}

function Parse-DeviceDate([string]$DateStr) {
    if ([string]::IsNullOrWhiteSpace($DateStr)) { return $null }
    foreach ($fmt in @('dd-MM-yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd')) {
        try { return [datetime]::ParseExact($DateStr, $fmt, $null) } catch { }
    }
    return $null
}

$devices = @()
try {
    $config = Invoke-RestMethod -Uri $configUrl -ErrorAction Stop
    $devices = @($config.devices | Where-Object { $_.enabled -eq $true })
} catch {
    Write-Host -ForegroundColor Red "Could not fetch device config from $configUrl"
    Write-Host -ForegroundColor Red "$_"
    Write-Host ""
    $manual = Read-Host "Enter ESD URL manually (or press Enter to exit)"
    if ([string]::IsNullOrWhiteSpace($manual)) { exit }
    $CustomImageFile = $manual
}

if ($devices.Count -gt 0) {
    function Show-Menu {
        Clear-Host
        Write-Host "==================== Ekco MSP - Image Selection ====================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (" {0,3}  {1,-34} {2,-18} {3}" -f "#", "Device", "Image Version", "Drivers") -ForegroundColor DarkGray
        Write-Host (" " + ("-" * 76)) -ForegroundColor DarkGray

        for ($i = 0; $i -lt $devices.Count; $i++) {
            $d    = $devices[$i]
            $name = if ($d.friendlyName) { $d.friendlyName } else { $d.name }
            $img  = if ($d.imageVersion) { $d.imageVersion } else { "--" }
            $drv  = if ($d.captureDate -and $d.captureDate -ne '') { $d.captureDate } else { "--" }

            $drvColor = "Green"
            if ($drv -eq "--") {
                $drvColor = "DarkGray"
            } else {
                $parsed = Parse-DeviceDate $d.captureDate
                if ($null -eq $parsed) {
                    $drvColor = "Yellow"
                } elseif (((Get-Date) - $parsed).TotalDays -gt 90) {
                    $drvColor = "Red"
                }
            }

            Write-Host (" {0,3}  " -f ($i + 1)) -NoNewline -ForegroundColor White
            Write-Host ("{0,-34} " -f $name) -NoNewline
            Write-Host ("{0,-18} " -f $img) -NoNewline -ForegroundColor Cyan
            Write-Host $drv -ForegroundColor $drvColor
        }

        Write-Host ""
        Write-Host " Drivers: " -NoNewline -ForegroundColor DarkGray
        Write-Host "Green = current  " -NoNewline -ForegroundColor Green
        Write-Host "Red = older than 90 days" -ForegroundColor Red
        Write-Host ""
    }

    do {
        Show-Menu
        $selection = Read-Host "Select an image (1-$($devices.Count))"
        $num = 0
        if ([int]::TryParse($selection, [ref]$num) -and $num -ge 1 -and $num -le $devices.Count) {
            $chosen     = $devices[$num - 1]
            $chosenName = if ($chosen.friendlyName) { $chosen.friendlyName } else { $chosen.name }
            $CustomImageFile = Get-EsdUrl $chosen.name
            Write-Host ""
            Write-Host -ForegroundColor Green "Selected: $chosenName"
            Write-Host -ForegroundColor Green "ESD:      $CustomImageFile"
            $selection = 'q'
        } else {
            Write-Host -ForegroundColor Red "Invalid selection, try again."
            Start-Sleep -Seconds 1
        }
    } until ($selection -eq 'q')
}

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
Set-Content -Path "C:\osdcloud\computername.txt" -Value $ComputerName

# Output name to C:\temp
if (-not (Test-Path -Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp"
}
Set-Content -Path "C:\temp\computername.txt" -Value $ComputerName

Write-Host -ForegroundColor Green "Restarting in 20 seconds!"

Start-Sleep -Seconds 20

wpeutil reboot
