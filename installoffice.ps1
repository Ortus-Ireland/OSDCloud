# Install Winget
#$progressPreference = 'silentlyContinue'
#$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
#$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
#Write-Information "Downloading winget to artifacts directory..."
#Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"
#Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
#Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
#Add-AppxPackage $latestWingetMsixBundle
# check if Microsoft 365 Apps is installed
#Add-AppxPackage -Register 'C:\Program Files\WindowsApps\Microsoft.Winget.Source_2021.112.1815.519_neutral_8wekyb3d8bbwe\AppManifest.xml' -DisableDevelopmentMode

if (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "Microsoft 365 Apps*" }) {
    Write-Host "Microsoft 365 Apps is installed"
}
else {
    Write-Host "Installing Microsoft 365 Apps"
    # Install Office using Winget
    winget install --id Microsoft.Office --accept-source-agreements
    Write-Host "Microsoft 365 Apps is installed"

    # Copy Office Shortcuts to Desktop
    copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" -Destination "c:\users\public\desktop\Outlook.lnk" -Force
    copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk" -Destination "c:\users\public\desktop\Word.lnk" -Force
    copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk" -Destination "c:\users\public\desktop\Excel.lnk" -Force
    copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk" -Destination "c:\users\public\desktop\PowerPoint.lnk" -Force
    Write-Host "Shortcuts copied to desktop"
}

# Check if Teams Machine-Wide Installer is installed
if (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "Teams Machine-Wide Installer*" }) {
    Write-Host "Microsoft Teams is installed"
}
else {
    Write-Host "Installing Microsoft Teams"
    # Install Teams Machine-Wide Installer using Winget
    winget install --id Microsoft.Teams --accept-source-agreements
    Write-Host "Microsoft Teams is installed"
}
