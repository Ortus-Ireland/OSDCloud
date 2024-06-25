### Ortus Windows Image Deployment Script v2 ###

## Define Variables ##
# $device1 = "SurfacePro9"
# $device1_name = "Surface Pro 9"
# $devuce1_drivers
# $device2 = "LenovoThinkBookG6"
# $device2_name = "Lenovo ThinkBook G6"
# $device3 = "SurfaceGo4"
# $device3_name = "Surface Go 4"
# $device4 = "ThinkCentreM70sG3"
# $device4_name = "Lenovo ThinkCentre M70s G3"
# $device5 = "Win11Pro_Generic"
# $device5_name = "Windows 11 Pro (Generic)"


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
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\$device1\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\$device2\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\$device3\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\$device4\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\Win11Pro_Generic\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 

Write-Host "Install.wim copied successfully!" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

###################
## Surface Pro 9 ##
###################
Write-Host ""
Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
Write-Host "* Starting Surface Pro 9 Image Update *" -ForegroundColor white -BackgroundColor blue
Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\SurfacePro9\install.wim /MountDir:C:\ImageStaging\SurfacePro9\Mount /Index:5
Write-Host ""
Write-Host "Adding Drivers for Surface Pro 9" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\SurfacePro9\Mount /Add-Driver /Driver:C:\Drivers\SurfacePro9 /Recurse
Write-Host ""
Write-Host "Surface Pro 9 Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\SurfacePro9\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\SurfacePro9\install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item C:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd -Destination c:\inetpub\wwwroot\esd\Win11_SurfacePro9.esd -Force
Write-Host "Surface Pro 9 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item C:\ImageStaging\SurfacePro9\install.wim

# Notify
Write-Host " "
Write-Host "Surface Pro 9 Update Complete" -ForegroundColor white -BackgroundColor darkgreen

#########################
## Lenovo ThinkBook G6 ##
#########################

Write-Host ""
Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
Write-Host "* Starting Lenovo ThinkBook G6 Update *" -ForegroundColor white -BackgroundColor blue
Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\LenovoThinkBookG6\install.wim /MountDir:C:\ImageStaging\LenovoThinkBookG6\Mount /Index:5
Write-Host ""
Write-Host "Adding Drivers for Lenovo ThinkBook G6" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\LenovoThinkBookG6\Mount /Add-Driver /Driver:C:\Drivers\LenovoThinkBookG6 /Recurse
Write-Host ""
Write-Host "Lenovo ThinkBook G6 Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\LenovoThinkBookG6\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\LenovoThinkBookG6\install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\LenovoThinkBookG6\Win11_LenovoThinkBookG6.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item C:\ImageStaging\LenovoThinkBookG6\Win11_LenovoThinkBookG6.esd -Destination c:\inetpub\wwwroot\esd\Win11_LenovoThinkBookG6.esd -Force
Write-Host "Lenovo ThinkBook G6 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item C:\ImageStaging\LenovoThinkBookG6\install.wim

# Notify
Write-Host " "
Write-Host "Lenovo ThinkBook G6 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


##################
## Surface Go 4 ##
##################

Write-Host ""
Write-Host "********************************" -ForegroundColor white -BackgroundColor blue
Write-Host "* Starting Surface Go 4 Update *" -ForegroundColor white -BackgroundColor blue
Write-Host "********************************" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\SurfaceGo4\install.wim /MountDir:C:\ImageStaging\SurfaceGo4\Mount /Index:5
Write-Host ""
Write-Host "Adding Drivers for Surface Go 4" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\SurfaceGo4\Mount /Add-Driver /Driver:C:\Drivers\SurfaceGo4 /Recurse
Write-Host ""
Write-Host "Surface Go 4 Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\SurfaceGo4\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\SurfaceGo4\install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\SurfaceGo4\Win11_SurfaceGo4.esd /Compress:recovery /CheckIntegrity
 
## -- Move ESD to IntePub -- ##
Move-Item C:\ImageStaging\SurfaceGo4\Win11_SurfaceGo4.esd -Destination c:\inetpub\wwwroot\esd\Win11_SurfaceGo4.esd -Force
Write-Host "Surface Go 4 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item C:\ImageStaging\SurfaceGo4\install.wim

# Notify
Write-Host " "
Write-Host "Surface Go 4 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


################################
## Lenovo ThinkCentre M70s G3 ##
################################

Write-Host ""
Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
Write-Host "* Starting ThinkCentre M70s G3 Update *" -ForegroundColor white -BackgroundColor blue
Write-Host "***************************************" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\ThinkCentreM70sG3\Install.wim /MountDir:C:\ImageStaging\ThinkCentreM70sG3\Mount /Index:5
Write-Host ""
Write-Host "Adding Drivers for Lenovo ThinkCentre M70s G3" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\ThinkCentreM70sG3\Mount /Add-Driver /Driver:C:\Drivers\ThinkCentreM70sG3 /Recurse
Write-Host ""
Write-Host "Lenovo ThinkCentre M70s G3 Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\ThinkCentreM70sG3\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\ThinkCentreM70sG3\Install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\ThinkCentreM70sG3\ThinkCentreM70sG3.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item C:\ImageStaging\ThinkCentreM70sG3\ThinkCentreM70sG3.esd -Destination c:\inetpub\wwwroot\esd\ThinkCentreM70sG3.esd -Force
Write-Host "Lenovo ThinkCentre M70s Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item C:\ImageStaging\ThinkCentreM70sG3\install.wim

# Notify
Write-Host " "
Write-Host "Lenovo ThinkCentre M70s Update Complete" -ForegroundColor white -BackgroundColor darkgreen

############################################
## Windows 11 Pro Generic (Untouched ISO) ##
############################################

Write-Host ""
Write-Host "********************************************" -ForegroundColor white -BackgroundColor blue
Write-Host "* Starting Windows 11 Generic Image Update *" -ForegroundColor white -BackgroundColor blue
Write-Host "********************************************" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\Win11Pro_Generic\Install.wim /MountDir:C:\ImageStaging\Win11Pro_Generic\Mount /Index:5

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\Win11Pro_Generic\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\Win11Pro_Generic\Install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\Win11Pro_Generic\Win11Pro_Generic.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item C:\ImageStaging\Win11Pro_Generic\Win11Pro_Generic.esd -Destination c:\inetpub\wwwroot\esd\Win11Pro_Generic.esd -Force
Write-Host "Windows 11 Pro (Generic) Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item C:\ImageStaging\Win11Pro_Generic\install.wim
Write-Host ""
# Notify
Write-Host "Windows 11 Pro (Generic) Update Complete" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

##############################
## Notify When All Complete ##
##############################
Write-Host " "
Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "* All Images Updated Successfully *" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen



