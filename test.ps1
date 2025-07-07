### Ortus Windows Image Deployment Script v2 ###

# Customize Write-Progress colors
$Host.PrivateData.ProgressBackgroundColor = 'DarkGreen'
$Host.PrivateData.ProgressForegroundColor = 'Yellow'

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
    "SurfacePro11Business"
#    "ThinkCentreNeo50QG4"
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

Write-Host ""
Write-Host "Copying install.wim from source..." -ForegroundColor white -BackgroundColor blue
Write-Host ""
copy-item D:\sources\install.wim -destination C:\ImageStaging\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 

### Step 2 (Optional)
# Check the index of the WIM file using the following command (if it's not the default of 5, make a note of it):
# dism /Get-WimInfo /WimFile:C:\ImageStaging\install.wim

### Step 3 (Copy install.wim to device folders)
### Add more devices in 'Define Variables' above
$totalDevices = $deviceList.Count
$currentDevice = 0

# Clear the console before starting progress to ensure clean display
Clear-Host
Write-Host "Starting file copy operations..." -ForegroundColor white -BackgroundColor blue
Write-Host ""
Clear-Host

# Define tasks for each device
$deviceTasks = @(
    "Mount Image",
    "Add Drivers", 
    "Unmount and Commit",
    "Convert to ESD",
    "Move to OSDCloud",
    "Cleanup"
)
$totalTasks = $deviceTasks.Count

foreach ($device in $deviceList) {
    $currentDevice++
    $devicePercentComplete = [math]::Round(($currentDevice / $totalDevices) * 100, 1)
    
    Write-Progress -Activity "Copying install.wim to device folders" -Status "Processing $device ($currentDevice of $totalDevices)" -PercentComplete $devicePercentComplete -CurrentOperation "Copying to $device"
    
    # Suppress output from copy-item to prevent console clutter
    copy-item C:\ImageStaging\install.wim -destination "C:\ImageStaging\$device\install.wim" -PassThru | Set-ItemProperty -name IsReadOnly -Value $false | Out-Null
}

Write-Progress -Activity "Copying install.wim to device folders" -Completed
Write-Host "Install.wim copied successfully!" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

$totalDevices = $deviceList.Count
$currentDevice = 0

# Clear console before starting device processing
Clear-Host
Write-Host "Starting device processing..." -ForegroundColor white -BackgroundColor blue
Write-Host "Total devices to process: $totalDevices" -ForegroundColor white -BackgroundColor blue
Write-Host ""

foreach ($device in $deviceList) {
    $currentDevice++
    $devicePercentComplete = [math]::Round(($currentDevice / $totalDevices) * 100, 1)
    
    # Use Write-Information for less critical messages during progress
    Write-Information "Starting $device Image Update" -InformationAction Continue

    $currentTask = 0
    
    ## -- Mount Image -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices - $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks - Mounting image for $device"
    Dism /Mount-Image /ImageFile:"C:\ImageStaging\$device\install.wim" /MountDir:"C:\ImageStaging\$device\Mount" /Index:5 | Out-Null
    
    ## -- Add Drivers -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices - $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks - Adding drivers for $device"
    Dism /Image:"C:\ImageStaging\$device\Mount" /Add-Driver /Driver:"C:\Drivers\$device" /Recurse | Out-Null
    
    ## -- Unmount WIM and Commit Changes -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices - $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks - Unmounting and committing changes for $device"
    Dism /Unmount-Image /MountDir:"C:\ImageStaging\$device\Mount" /Commit | Out-Null

    ## -- Convert WIM to ESD -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices - $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks - Converting WIM to ESD for $device"
    Dism /Export-Image /SourceImageFile:"C:\ImageStaging\$device\install.wim" /SourceIndex:5 /DestinationImageFile:"C:\ImageStaging\$device\Win11_$device.esd" /Compress:recovery /CheckIntegrity | Out-Null

    ## -- Move ESD to InetPub -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices - $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks - Moving ESD file for $device"
    Move-Item "C:\ImageStaging\$device\Win11_$device.esd" -Destination "c:\inetpub\wwwroot\esd\Win11_$device.esd" -Force

    ## -- Remove install.wim -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices - $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks - Cleaning up install.wim for $device"
    Remove-Item "C:\ImageStaging\$device\install.wim"

    # Show completion for this device
    Write-Information "$device Update Complete" -InformationAction Continue
}

Write-Progress -Activity "Processing device images" -Completed


##############################
## Notify When All Complete ##
##############################
Write-Host " "
Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "* All Images Updated Successfully *" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen
