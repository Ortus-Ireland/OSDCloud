### Ekco MSP - OSDCloud Image Selection ###
### Reads enabled devices from imageStaging.json via IIS ###

$wdsHost = "wds"
try {
    $serverCfg = Invoke-WebRequest -Uri "http://wds/imageStaging/wdsServer.json" -UseBasicParsing -ErrorAction Stop
    $raw = $serverCfg.Content.Trim()
    if ($raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1) }
    $srv = $raw | ConvertFrom-Json
    if ($srv.hostname) { $wdsHost = $srv.hostname }
} catch { }

$configUrl = "http://$wdsHost/imageStaging/imageStaging.json"
$Index = 1

function Get-EsdUrl([string]$Name) {
    if ($Name -match '^Win\d') { return "http://$wdsHost/esd/$Name.esd" }
    return "http://$wdsHost/esd/Win11_$Name.esd"
}

function ConvertTo-DeviceDate([string]$DateStr) {
    if ([string]::IsNullOrWhiteSpace($DateStr)) { return $null }
    foreach ($fmt in @('dd-MM-yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd')) {
        try { return [datetime]::ParseExact($DateStr, $fmt, $null) } catch { }
    }
    return $null
}

Write-Host -ForegroundColor Yellow "Fetching device config from $configUrl ..."
$devices = @()
try {
    $response = Invoke-WebRequest -Uri $configUrl -UseBasicParsing -ErrorAction Stop
    $raw = $response.Content
    if ($raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1) }
    if ($raw.StartsWith([string][char]0xEF + [char]0xBB + [char]0xBF)) { $raw = $raw.Substring(3) }
    $raw = $raw.Trim()
    $config = $raw | ConvertFrom-Json
    $devices = @($config.devices | Where-Object { $_.enabled -eq $true -or $_.enabled -eq 'true' -or $_.enabled -eq 'True' })
    Write-Host -ForegroundColor Green "Loaded $($devices.Count) enabled device(s)."
} catch {
    Write-Host -ForegroundColor Red "Could not fetch device config: $_"
    Write-Host ""
    $manual = Read-Host "Enter ESD URL manually (or press Enter to exit)"
    if ([string]::IsNullOrWhiteSpace($manual)) { exit }
    $CustomImageFile = $manual
}

if ($devices.Count -gt 0) {
    $manufacturers = @($devices | ForEach-Object {
        if ($_.manufacturer) { $_.manufacturer } else { "Other" }
    } | Select-Object -Unique | Sort-Object)

    function Show-ManufacturerMenu {
        Clear-Host
        Write-Host "==================== Ekco MSP - Image Selection ====================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " Select a manufacturer:" -ForegroundColor DarkGray
        Write-Host (" " + ("-" * 40)) -ForegroundColor DarkGray
        for ($i = 0; $i -lt $manufacturers.Count; $i++) {
            $mfg = $manufacturers[$i]
            $count = @($devices | Where-Object { $m = if ($_.manufacturer) { $_.manufacturer } else { "Other" }; $m -eq $mfg }).Count
            Write-Host (" {0,3}  {1}  " -f ($i + 1), $mfg) -NoNewline -ForegroundColor White
            Write-Host "($count device$(if ($count -ne 1) { 's' }))" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    function Show-DeviceMenu($MfgName, $MfgDevices) {
        Clear-Host
        Write-Host "==================== Ekco MSP - Image Selection ====================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " $MfgName devices:" -ForegroundColor Cyan
        Write-Host (" {0,3}  {1,-34} {2,-18} {3}" -f "#", "Device", "Image Version", "Drivers") -ForegroundColor DarkGray
        Write-Host (" " + ("-" * 76)) -ForegroundColor DarkGray

        for ($i = 0; $i -lt $MfgDevices.Count; $i++) {
            $d    = $MfgDevices[$i]
            $name = if ($d.friendlyName) { $d.friendlyName } else { $d.name }
            $img  = if ($d.imageVersion) { $d.imageVersion } else { "--" }
            $drv  = if ($d.captureDate -and $d.captureDate -ne '') { $d.captureDate } else { "--" }

            $drvColor = "Green"
            if ($drv -eq "--") {
                $drvColor = "DarkGray"
            } else {
                $parsed = ConvertTo-DeviceDate $d.captureDate
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
        Write-Host "   B  " -NoNewline -ForegroundColor Yellow
        Write-Host "Back to manufacturers" -ForegroundColor DarkGray
        Write-Host ""
    }

    $chosen = $null
    while ($null -eq $chosen) {
        Show-ManufacturerMenu
        $mfgSel = Read-Host "Select manufacturer (1-$($manufacturers.Count))"
        $mfgNum = 0
        if (-not ([int]::TryParse($mfgSel, [ref]$mfgNum)) -or $mfgNum -lt 1 -or $mfgNum -gt $manufacturers.Count) {
            Write-Host -ForegroundColor Red "Invalid selection, try again."
            Start-Sleep -Seconds 1
            continue
        }

        $selMfg = $manufacturers[$mfgNum - 1]
        $mfgDevices = @($devices | Where-Object {
            $m = if ($_.manufacturer) { $_.manufacturer } else { "Other" }; $m -eq $selMfg
        })

        $pickingDevice = $true
        while ($pickingDevice) {
            Show-DeviceMenu $selMfg $mfgDevices
            $devSel = Read-Host "Select a device (1-$($mfgDevices.Count)) or B to go back"
            if ($devSel -eq 'b' -or $devSel -eq 'B') {
                $pickingDevice = $false
                continue
            }
            $devNum = 0
            if ([int]::TryParse($devSel, [ref]$devNum) -and $devNum -ge 1 -and $devNum -le $mfgDevices.Count) {
                $chosen = $mfgDevices[$devNum - 1]
                $pickingDevice = $false
            } else {
                Write-Host -ForegroundColor Red "Invalid selection, try again."
                Start-Sleep -Seconds 1
            }
        }
    }

    $chosenName = if ($chosen.friendlyName) { $chosen.friendlyName } else { $chosen.name }
    $CustomImageFile = Get-EsdUrl $chosen.name
    Write-Host ""
    Write-Host -ForegroundColor Green "Selected: $chosenName"
    Write-Host -ForegroundColor Green "ESD:      $CustomImageFile"
}

if ([string]::IsNullOrWhiteSpace($CustomImageFile)) {
    Write-Host ""
    Write-Host -ForegroundColor Red "========================================="
    Write-Host -ForegroundColor Red " ERROR: No image was selected!"
    Write-Host -ForegroundColor Red "========================================="
    Write-Host -ForegroundColor Yellow "Devices found: $($devices.Count)"
    Write-Host -ForegroundColor Yellow "Config URL: $configUrl"
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

Write-Host ""
Write-Host -ForegroundColor Green "Image URL: $CustomImageFile"
Write-Host ""

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
