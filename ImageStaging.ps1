### Ortus Windows Image Deployment Script v2 ###

## Define Device Variables ##
# These should match the folder names in the deployment directory
$deviceList = @(
    "SurfacePro9",
    "LenovoThinkBookG6",
    "SurfaceGo4",
    "ThinkCentreM70sG3",
    "Win11Pro_Generic",
    "Win11Pro_AllDrivers",
    "LenovoThinkBookG7",
    "SurfacePro10",
    "ThinkCentreM70sG4",
    "SurfacePro11Business",
    "ThinkCentreNeo50QG4"
)


## Startup Script ##

Write-Host ""
Write-Host "Starting Ortus Windows Image Update Tool..."
Write-Host ""
Write-Host "**************************************************************" -ForegroundColor white -BackgroundColor red
Write-Host "* Make sure Windows ISO is mounted to D:\ before continuing! *" -ForegroundColor white -BackgroundColor red
Write-Host "**************************************************************" -ForegroundColor white -BackgroundColor red
Write-Host ""
Write-Host "Press any key to continue or CTRL+C to cancel..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

Write-Host "**********************************************************************************" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "* Continuing update. If updating fails, use 'DISM /clenup-wim' to clean up files *" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "**********************************************************************************" -ForegroundColor white -BackgroundColor darkgreen

## Start Copying WIM from Source ##
# Download the latest Windows 11 ISO from the Microsoft Visual Studio Online portal. 
# Mount the ISO and extract the install.wim file from the D:\Sources folder and place it in C:\ImageStaging:

# Write-Host ""
# Write-Host "Copying install.wim from source..." -ForegroundColor white -BackgroundColor blue
Write-Host ""
copy-item D:\sources\install.wim -destination C:\ImageStaging\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 

### Step 2 (Optional)
# Check the index of the WIM file using the following command (if it's not the default of 5, make a note of it):
# dism /Get-WimInfo /WimFile:C:\ImageStaging\install.wim

### Step 3 (Copy install.wim to device folders)
### Add more devices in 'Define Variables' above
$totalDevices = $deviceList.Count
$currentDevice = 0

foreach ($device in $deviceList) {
    $currentDevice++
    $percentComplete = [math]::Round(($currentDevice / $totalDevices) * 100, 1)
    
    Write-Progress -Activity "Copying install.wim to device folders" -Status "Processing $device ($currentDevice of $totalDevices)" -PercentComplete $percentComplete -CurrentOperation "Copying to $device"
    
    copy-item C:\ImageStaging\install.wim -destination "C:\ImageStaging\$device\install.wim" -PassThru | Set-ItemProperty -name IsReadOnly -Value $false
}

Write-Progress -Activity "Copying install.wim to device folders" -Completed
Write-Host "Install.wim copied successfully!" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

############################
## Device Processing Loop ##
############################

Write-Host ""
Write-Host "***********************************" -ForegroundColor white -BackgroundColor yellow
Write-Host "* Starting Device Processing Loop *" -ForegroundColor white -BackgroundColor yellow
Write-Host "***********************************" -ForegroundColor white -BackgroundColor yellow
Write-Host ""
Write-Host "Total devices to process: $totalDevices" -ForegroundColor white -BackgroundColor blue
Write-Host "Progress will be shown for each device and overall completion." -ForegroundColor white -BackgroundColor blue
Write-Host ""


$totalDevices = $deviceList.Count
$currentDevice = 0

foreach ($device in $deviceList) {
    $currentDevice++
    $percentComplete = [math]::Round(($currentDevice / $totalDevices) * 100, 1)
    
    Write-Progress -Activity "Processing device images" -Status "Processing $device ($currentDevice of $totalDevices)" -PercentComplete $percentComplete -CurrentOperation "Updating $device"
    
    Write-Host ""
    Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
    Write-Host "* Starting $device Image Update *" -ForegroundColor white -BackgroundColor blue
    Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
    Write-Host ""

    ## -- Mount Image -- ##
    Dism /Mount-Image /ImageFile:"C:\ImageStaging\$device\install.wim" /MountDir:"C:\ImageStaging\$device\Mount" /Index:5
    Write-Host ""
    Write-Host "Adding Drivers for $device" -ForegroundColor white -BackgroundColor blue
    Write-Host ""

    ## -- Add Drivers -- ##
    Dism /Image:"C:\ImageStaging\$device\Mount" /Add-Driver /Driver:"C:\Drivers\$device" /Recurse
    Write-Host ""
    Write-Host "$device Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
    Write-Host ""

    ## -- Unmount WIM and Commit Changes -- ##
    Dism /Unmount-Image /MountDir:"C:\ImageStaging\$device\Mount" /Commit

    ## -- Convert WIM to ESD -- ##
    Dism /Export-Image /SourceImageFile:"C:\ImageStaging\$device\install.wim" /SourceIndex:5 /DestinationImageFile:"C:\ImageStaging\$device\Win11_$device.esd" /Compress:recovery /CheckIntegrity

    ## -- Move ESD to InetPub -- ##
    Move-Item "C:\ImageStaging\$device\Win11_$device.esd" -Destination "c:\inetpub\wwwroot\esd\Win11_$device.esd" -Force
    Write-Host "$device Move Successful" -ForegroundColor white -BackgroundColor darkgreen

    ## -- Remove install.wim -- ##
    Remove-Item "C:\ImageStaging\$device\install.wim"

    # Notify
    Write-Host " "
    Write-Host "$device Update Complete" -ForegroundColor white -BackgroundColor darkgreen
    Write-Host ""
}

Write-Progress -Activity "Processing device images" -Completed


##############################
## Notify When All Complete ##
##############################
Write-Host " "
Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "* All Images Updated Successfully *" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen



