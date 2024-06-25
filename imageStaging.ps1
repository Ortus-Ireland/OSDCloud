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

###################
## Surface Pro 9 ##
###################

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\SurfacePro9\install.wim /MountDir:C:\ImageStaging\SurfacePro9\Mount /Index:1

## -- Add Drivers -- ##
Dism /Image:C:\ImageStaging\SurfacePro9\Mount /Add-Driver /Driver:C:\Drivers\SurfacePro9 /Recurse

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\SurfacePro9\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\SurfacePro9\install.wim /SourceIndex:1 /DestinationImageFile:C:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to IntePub -- ##
Move-Item c:\ImageStaging\SurfacePro9\Win11_SurfacePro9.esd -Destination c:\inetpub\wwwroot\esd\Win11_SurfacePro9.esd
