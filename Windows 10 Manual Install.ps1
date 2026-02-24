copy-item D:\sources\install.wim -destination C:\ImageStaging\Win10Pro_Generic\install.wim -PassThru | Set-ItemProperty -name IsReadOnly -Value $false 
dism /Get-WimInfo /WimFile:C:\ImageStaging\Win10Pro_Generic\install.wim


Write-Host ""
Write-Host "********************************************" -ForegroundColor white -BackgroundColor blue
Write-Host "* Starting Windows 10 Generic Image Update *" -ForegroundColor white -BackgroundColor blue
Write-Host "********************************************" -ForegroundColor white -BackgroundColor blue
Write-Host ""

## -- Mount Image -- ##
Dism /Mount-Image /ImageFile:C:\ImageStaging\Win10Pro_Generic\Install.wim /MountDir:C:\ImageStaging\Win10Pro_Generic\Mount /Index:5

## -- Unmount WIM and Commit Changes -- ##
Dism /Unmount-Image /MountDir:C:\ImageStaging\Win10Pro_Generic\Mount /Commit

## -- Convert WIM to ESD -- ##
Dism /Export-Image /SourceImageFile:C:\ImageStaging\Win10Pro_Generic\Install.wim /SourceIndex:5 /DestinationImageFile:C:\ImageStaging\Win10Pro_Generic\Win10Pro_Generic.esd /Compress:recovery /CheckIntegrity

## -- Move ESD to InetPub -- ##
Move-Item C:\ImageStaging\Win10Pro_Generic\Win11Pro_Generic.esd -Destination c:\inetpub\wwwroot\esd\Win10Pro_Generic.esd -Force
Write-Host "Windows 11 Pro (Generic) Move Successful" -ForegroundColor white -BackgroundColor darkgreen

## -- Remove install.wim -- ##
Remove-Item C:\ImageStaging\Win10Pro_Generic\install.wim
Write-Host ""
# Notify
Write-Host "Windows 10 Pro (Generic) Update Complete" -ForegroundColor white -BackgroundColor darkgreen
Write-Host ""