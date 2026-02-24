<#
.SYNOPSIS
    Download and install latest Office 365 Deployment Tool (ODT)
.DESCRIPTION
    Download and install latest Office 365 Deployment Tool (ODT)
.EXAMPLE
    Set-Location to MDT script root aka %settings%
    PS C:\> . .\install.ps1
    Downloads latest officedeploymenttool.exe
    Creates a sub-directory for each new version
    Creates the offline cache for the setup files
    Installs Office 365 to target
.NOTES
    Author: Marco Hofmann & Trond Eric Haavarstein
    Twitter: @xenadmin & @xenappblog
    URL: https://www.meinekleinefarm.net & https://xenappblog.com/
.LINK
    https://www.meinekleinefarm.net/download-and-install-latest-office-365-deployment-tool-odt
.LINK
    https://www.microsoft.com/en-us/download/details.aspx?id=49117
.LINK
    https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117
#>
Set-executionpolicy bypass -scope process
function Get-ODTUri {
    <#
        .SYNOPSIS
            Get Download URL of latest Office 365 Deployment Tool (ODT).
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
            Modified by: Marco Hofmann
            Twitter: @xenadmin
        .LINK
            https://www.meinekleinefarm.net/
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $url = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to ODT: $url with error $_."
        Break
    }
    finally {
        $ODTUri = $response.links | Where-Object { $_.outerHTML -like "*click here to download manually*" }
        Write-Output $ODTUri.href
    }
}

# Check if C:\programdata\ortus\office exists and create if not
$folder = "C:\programdata\ortus\office"
if (!(Test-Path $folder)) {
    New-Item -ItemType Directory -Force -Path $folder
}

# Change directory to C:\programdata\ortus\office
Set-Location $folder

# Download http://wds/esd/configuration.xml
$source = "http://wds/esd/configuration.xml"
$destination = "C:\programdata\ortus\office\configuration.xml"
Invoke-WebRequest -Uri $source -OutFile $destination

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "O365BusinessRetail x64"
$PackageName = "setup"
$InstallerType = "exe"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$Unattendedxml = 'configuration.xml'
$UnattendedArgs = "/configure $Unattendedxml"
$UnattendedArgs2 = "/download $Unattendedxml"
#$URL = $(Get-ODTUri)
# Static url as function broken
$URL = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_18129-20030.exe"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

Write-Verbose "Downloading latest version of Office 365 Deployment Tool (ODT)." -Verbose
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile .\officedeploymenttool.exe
Start-Sleep -s 5
Write-Verbose "Read version number from downloaded file" -Verbose
$Version = (Get-Command .\officedeploymenttool.exe).FileVersionInfo.FileVersion

Write-Verbose "If downloaded ODT file is newer, create new sub-directory." -Verbose
if ( -Not (Test-Path -Path $Version ) ) {
    New-Item -ItemType directory -Path $Version
    Copy-item ".\$Unattendedxml" -Destination $Version -Force
    .\officedeploymenttool.exe /quiet /extract:.\$Version
    start-sleep -s 5
    Write-Verbose "New folder created $Version" -Verbose
}
else {
    Write-Verbose "Version identical. Skipping folder creation." -Verbose
}

Set-Location $Version

Write-Verbose "Downloading $Vendor $Product via ODT $Version" -Verbose
if (!(Test-Path -Path .\Office\Data\v32.cab)) {
    (Start-Process "setup.exe" -ArgumentList $unattendedArgs2 -Wait -Passthru).ExitCode
}
else {
    Write-Verbose "File exists. Skipping Download." -Verbose
}

Write-Verbose "Starting Installation of $Vendor $Product via ODT $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
# Copy Office Shortcuts to Desktop
copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" -Destination "c:\users\public\desktop\Outlook.lnk" -Force
copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk" -Destination "c:\users\public\desktop\Word.lnk" -Force
copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk" -Destination "c:\users\public\desktop\Excel.lnk" -Force
copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk" -Destination "c:\users\public\desktop\PowerPoint.lnk" -Force
Write-Host "Shortcuts copied to desktop"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
