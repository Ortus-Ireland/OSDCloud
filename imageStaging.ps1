### Step 1
# Download the latest Windows 11 ISO from the Microsoft Visual Studio Online portal. 
# Mount the ISO and extract the install.wim file from the D:\Sources folder and place it in C:\ImageStaging:
copy-item D:\sources\install.wim -destination C:\ImageStaging\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 

### Step 2 (Optional)
# Check the index of the WIM file using the following command (if it's not the default of 5, make a note of it):
# dism /Get-WimInfo /WimFile:C:\ImageStaging\install.wim

### Step 3 (Copy install.wim to device folders)
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\LenovoG6\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\SurfacePro9\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\SurfaceGo4\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\ThinkCentreM70sG3\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false
copy-item C:\ImageStaging\install.wim -destination C:\ImageStaging\Win11Pro_Generic\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 


############################################
## Windows 11 Pro Generic (Untouched ISO) ##
############################################

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\Win11Pro_Generic\Install.wim /MountDir:C:\ImageStaging\Win11Pro_Generic\Mount /Index:5

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\Win11Pro_Generic\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\Win11Pro_Generic\Install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\Win11Pro_Generic\Win11Pro_Generic.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item c:\ImageStaging\Win11Pro_Generic\Win11Pro_Generic.esd -Destination c:\inetpub\wwwroot\esd\Win11Pro_Generic.esd
Write-Host "Windows 11 Pro (Generic) Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item c:\ImageStaging\Win11Pro_Generic\install.wim

# Notify
Write-Host "Windows 11 Pro (Generic) Update Complete" -ForegroundColor white -BackgroundColor darkgreen


###############
## Lenovo G6 ##
###############

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\LenovoG6\install.wim /MountDir:C:\ImageStaging\LenovoG6\Mount /Index:5

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\LenovoG6\Mount /Add-Driver /Driver:C:\Drivers\ThinkBook_16_G6_IRL /Recurse

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\LenovoG6\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\LenovoG6\install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\LenovoG6\Win11_LenovoG6.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item c:\ImageStaging\LenovoG6\Win11_LenovoG6.esd -Destination c:\inetpub\wwwroot\esd\Win11_LenovoG6.esd
Write-Host "Lenovo G6 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item c:\ImageStaging\LenovoG6\install.wim

# Notify
Write-Host "Lenovo G6 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


###################
## Surface Pro 9 ##
###################

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\SurfacePro9\install.wim /MountDir:C:\ImageStaging\SurfacePro9\Mount /Index:5

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\SurfacePro9\Mount /Add-Driver /Driver:C:\Drivers\SurfacePro9 /Recurse

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\SurfacePro9\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\SurfacePro9\install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item c:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd -Destination c:\inetpub\wwwroot\esd\Win11_SurfacePro9.esd
Write-Host "Surface Pro 9 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item c:\ImageStaging\SurfacePro9\install.wim

# Notify
Write-Host "Surface Pro 9 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


##################
## Surface Go 4 ##
##################

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\SurfaceGo4\install.wim /MountDir:C:\ImageStaging\SurfaceGo4\Mount /Index:5

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\SurfaceGo4\Mount /Add-Driver /Driver:c:\Drivers\SurfaceGo4 /Recurse

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\SurfaceGo4\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\SurfaceGo4\install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\SurfaceGo4\install.esd /Compress:recovery /CheckIntegrity
 
## -- Move ESD to IntePub -- ##
Move-Item c:\ImageStaging\SurfaceGo4\Win11_SurfaceGo4.esd -Destination c:\inetpub\wwwroot\esd\Win11_SurfaceGo4.esd
Write-Host "Surface Go 4 Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item c:\ImageStaging\SurfaceGo4\install.wim

# Notify
Write-Host "Surface Go 4 Update Complete" -ForegroundColor white -BackgroundColor darkgreen


################################
## Lenovo ThinkCentre M70s G3 ##
################################

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\ThinkCentreM70sG3\Install.wim /MountDir:C:\ImageStaging\ThinkCentreM70sG3\Mount /Index:5

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\ThinkCentreM70sG3\Mount /Add-Driver /Driver:C:\Drivers\ThinkCentreM70sG3 /Recurse

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\ThinkCentreM70sG3\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\ThinkCentreM70sG3\Install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\ThinkCentreM70sG3\ThinkCentreM70sG3.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item c:\ImageStaging\ThinkCentreM70sG3\ThinkCentreM70sG3.esd -Destination c:\inetpub\wwwroot\esd\ThinkCentreM70sG3.esd
Write-Host "Lenovo ThinkCentre M70s Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item c:\ImageStaging\ThinkCentreM70sG3\install.wim

# Notify
Write-Host "ThinkCentre M70s Update Complete" -ForegroundColor white -BackgroundColor darkgreen


##############################
## Notify When All Complete ##
##############################

Write-Host "All Images Updated Successfully" -ForegroundColor white -BackgroundColor darkgreen



