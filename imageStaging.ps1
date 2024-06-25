Write-Host "Beginning Ortus Windows Image Update..."
Write-Host "Make sure Windows ISO is mounted to D:\ before continuing!" -ForegroundColor white -BackgroundColor red
Write-Host "Press any key to continue or CTRL+C to cancel..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
Write-Host ""
Write-Host "Copying ImageStaging to RAMDisk..." -ForegroundColor white -BackgroundColor blue

## Copy ImageStaging to RAMDisk
Copy-Item -Path C:\ImageStaging -Destination R:\ImageStaging -recurse -Force
Write-Host "RAMDisk Initialised..." -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""
Write-Host "Copying install.wim from source..." -ForegroundColor white -BackgroundColor blue

# Download the latest Windows 11 ISO from the Microsoft Visual Studio Online portal. 
# Mount the ISO and extract the install.wim file from the D:\Sources folder and place it in R:\ImageStaging:
copy-item D:\sources\install.wim -destination R:\ImageStaging\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 

### Step 2 (Optional)
# Check the index of the WIM file using the following command (if it's not the default of 5, make a note of it):
# dism /Get-WimInfo /WimFile:R:\ImageStaging\install.wim

### Step 3 (Copy install.wim to device folders)
copy-item R:\ImageStaging\install.wim -destination R:\ImageStaging\LenovoThinkBookG6\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item R:\ImageStaging\install.wim -destination R:\ImageStaging\SurfacePro9\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item R:\ImageStaging\install.wim -destination R:\ImageStaging\SurfaceGo4\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item R:\ImageStaging\install.wim -destination R:\ImageStaging\ThinkCentreM70sG3\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false
copy-item R:\ImageStaging\install.wim -destination R:\ImageStaging\Win11Pro_Generic\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 

Write-Host "Install.wim copied successfully!" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

#########################
## Lenovo ThinkBook G6 ##
#########################

Write-Host "Starting Lenovo ThinkBook G6 Image Update" -ForegroundColor white -BackgroundColor blue

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:R:\ImageStaging\LenovoThinkBookG6\install.wim /MountDir:R:\ImageStaging\LenovoThinkBookG6\Mount /Index:5

Write-Host "Adding Drivers for Lenovo ThinkBook G6" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:R:\ImageStaging\LenovoThinkBookG6\Mount /Add-Driver /Driver:C:\Drivers\LenovoThinkBookG6 /Recurse

Write-Host "Lenovo ThinkBook G6 Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:R:\ImageStaging\LenovoThinkBookG6\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:R:\ImageStaging\LenovoThinkBookG6\install.wim /SourceIndex:5 /DestinationImageFile:R:\ImageStaging\LenovoThinkBookG6\Win11_LenovoThinkBookG6.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item R:\ImageStaging\LenovoG6\Win11_LenovoThinkBookG6.esd -Destination c:\inetpub\wwwroot\esd\Win11_LenovoThinkBookG6.esd
Write-Host "Lenovo ThinkBook G6 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item R:\ImageStaging\LenovoG6\install.wim

# Notify
Write-Host "Lenovo G6 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


###################
## Surface Pro 9 ##
###################

Write-Host "Starting Surface Pro 9 Image Update" -ForegroundColor white -BackgroundColor blue

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:R:\ImageStaging\SurfacePro9\install.wim /MountDir:R:\ImageStaging\SurfacePro9\Mount /Index:5

Write-Host "Adding Drivers for Surface Pro 9" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:R:\ImageStaging\SurfacePro9\Mount /Add-Driver /Driver:C:\Drivers\SurfacePro9 /Recurse

Write-Host "Surface Pro 9 Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:R:\ImageStaging\SurfacePro9\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:R:\ImageStaging\SurfacePro9\install.wim /SourceIndex:5 /DestinationImageFile:R:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item R:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd -Destination c:\inetpub\wwwroot\esd\Win11_SurfacePro9.esd
Write-Host "Surface Pro 9 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item R:\ImageStaging\SurfacePro9\install.wim

# Notify
Write-Host "Surface Pro 9 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


##################
## Surface Go 4 ##
##################

Write-Host "Starting Surface Go 4 Image Update" -ForegroundColor white -BackgroundColor blue

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:R:\ImageStaging\SurfaceGo4\install.wim /MountDir:R:\ImageStaging\SurfaceGo4\Mount /Index:5

Write-Host "Adding Drivers for Surface Go 4" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:R:\ImageStaging\SurfaceGo4\Mount /Add-Driver /Driver:C:\Drivers\SurfaceGo4 /Recurse

Write-Host "Surface Go 4 Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:R:\ImageStaging\SurfaceGo4\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:R:\ImageStaging\SurfaceGo4\install.wim /SourceIndex:5 /DestinationImageFile:R:\ImageStaging\SurfaceGo4\install.esd /Compress:recovery /CheckIntegrity
 
## -- Move ESD to IntePub -- ##
Move-Item R:\ImageStaging\SurfaceGo4\Win11_SurfaceGo4.esd -Destination c:\inetpub\wwwroot\esd\Win11_SurfaceGo4.esd
Write-Host "Surface Go 4 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item R:\ImageStaging\SurfaceGo4\install.wim

# Notify
Write-Host "Surface Go 4 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


################################
## Lenovo ThinkCentre M70s G3 ##
################################

Write-Host "Starting ThinkCentre M70s G3 Update" -ForegroundColor white -BackgroundColor blue

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:R:\ImageStaging\ThinkCentreM70sG3\Install.wim /MountDir:R:\ImageStaging\ThinkCentreM70sG3\Mount /Index:5

Write-Host "Adding Drivers for Lenovo ThinkCentre M70s G3" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Add Drivers -- ##
Dism /Image:R:\ImageStaging\ThinkCentreM70sG3\Mount /Add-Driver /Driver:C:\Drivers\ThinkCentreM70sG3 /Recurse

Write-Host "Lenovo ThinkCentre M70s G3 Drivers Added Successfully" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:R:\ImageStaging\ThinkCentreM70sG3\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:R:\ImageStaging\ThinkCentreM70sG3\Install.wim /SourceIndex:5 /DestinationImageFile:R:\ImageStaging\ThinkCentreM70sG3\ThinkCentreM70sG3.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item R:\ImageStaging\ThinkCentreM70sG3\ThinkCentreM70sG3.esd -Destination c:\inetpub\wwwroot\esd\ThinkCentreM70sG3.esd
Write-Host "Lenovo ThinkCentre M70s Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item R:\ImageStaging\ThinkCentreM70sG3\install.wim

# Notify
Write-Host "ThinkCentre M70s Update Complete" -ForegroundColor white -BackgroundColor darkgreen

############################################
## Windows 11 Pro Generic (Untouched ISO) ##
############################################

Write-Host "Starting Windows 11 Pro Generic Image Update" -ForegroundColor white -BackgroundColor blue

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:R:\ImageStaging\Win11Pro_Generic\Install.wim /MountDir:R:\ImageStaging\Win11Pro_Generic\Mount /Index:5

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:R:\ImageStaging\Win11Pro_Generic\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:R:\ImageStaging\Win11Pro_Generic\Install.wim /SourceIndex:5 /DestinationImageFile:R:\ImageStaging\Win11Pro_Generic\Win11Pro_Generic.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item R:\ImageStaging\Win11Pro_Generic\Win11Pro_Generic.esd -Destination c:\inetpub\wwwroot\esd\Win11Pro_Generic.esd
Write-Host "Windows 11 Pro (Generic) Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item R:\ImageStaging\Win11Pro_Generic\install.wim

# Notify
Write-Host "Windows 11 Pro (Generic) Update Complete" -ForegroundColor white -BackgroundColor darkgreen


##############################
## Notify When All Complete ##
##############################

Write-Host "All Images Updated Successfully" -ForegroundColor white -BackgroundColor darkgreen



