Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"

Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine

if ((Get-MyComputerModel) -match 'Virtual') {

Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"

Set-DisRes 1600

}

#Make sure I have the latest OSD Content

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

Install-Module OSD -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"

Import-Module OSD -Force

#$ScriptFromGitHub = Invoke-Restmethod https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/Diskpart-Clean.ps1
#Invoke-Expression $ScriptFromGitHub
function Diskpart-Clean {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$DiskNumber
    )
    #Virtual Machines have issues using PowerShell for Clear-Disk
    #$OSDDisk | Clear-Disk -RemoveOEM -RemoveData -Confirm:$true -PassThru -ErrorAction SilentlyContinue | Out-Null
    
    Write-Verbose "DISKPART> select disk $DiskNumber"
    Write-Verbose "DISKPART> clean"
    Write-Verbose "DISKPART> exit"
    
    #Abort if not in WinPE
    if ($env:SystemDrive -ne "X:") {Return}

$null = @"
select disk $DiskNumber
clean
exit 
"@ | diskpart.exe
}

#$ScriptFromGitHub = Invoke-Restmethod https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/New-OSDPartitionSystem.ps1
#Invoke-Expression $ScriptFromGitHub
#Invoke-Restmethod https://raw.githubusercontent.com/OSDeploy/OSD/9484db58a67f10362e31613d94ac3f15db78fe2a/Private/Disk/New-OSDPartitionSystem.ps1
<#
.SYNOPSIS
Creates a GPT or MBR System Partition

.DESCRIPTION
Creates a GPT or MBR System Partition

.LINK
https://osd.osdeploy.com/module/functions/storage/new-OSDPartitionSystem

.NOTES
19.12.11     Created by David Segura @SeguraOSD
#>
function New-OSDPartitionSystem {
    [CmdletBinding()]
    param (
        #Fixed Disk Number
        #For multiple Fixed Disks, use the SelectDisk parameter
        #Alias = Disk, Number
        [Parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [Alias('Disk','Number')]
        [uint32]$DiskNumber,

        #Drive Label of the System Partition
        #Default = System
        [string]$LabelSystem = 'System',

        [Alias('PS')]
        [ValidateSet('GPT','MBR')]
        [string]$PartitionStyle,

        #System Partition size for BIOS MBR based Computers
        #Default = 260MB
        #Range = 100MB - 3000MB (3GB)
        [ValidateRange(100MB,3000MB)]
        [uint64]$SizeSystemMbr = 260MB,

        #System Partition size for UEFI GPT based Computers
        #Default = 260MB
        #Range = 100MB - 3000MB (3GB)
        [ValidateRange(100MB,3000MB)]
        [uint64]$SizeSystemGpt = 260MB,

        #MSR Partition size
        #Default = 16MB
        #Range = 16MB - 128MB
        [ValidateRange(16MB,128MB)]
        [uint64]$SizeMSR = 16MB
    )

    #=======================================================================
    #	PartitionStyle
    #=======================================================================
    if (-NOT ($PartitionStyle)) {
        if (Get-OSDGather -Property IsUEFI) {
            $PartitionStyle = 'GPT'
        } else {
            $PartitionStyle = 'MBR'
        }
    }
    Write-Verbose "PartitionStyle is set to $PartitionStyle"
    #=======================================================================
    #	GPT
    #=======================================================================
    if ($PartitionStyle -eq 'GPT') {
        Write-Verbose "Creating GPT System Partition"
        $PartitionSystem = New-Partition -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -DiskNumber $DiskNumber -Size $SizeSystemGpt

        Write-Verbose "Formatting GPT System Partition FAT32 with Label $LabelSystem"
        Diskpart-FormatSystemPartition -DiskNumber $DiskNumber -PartitionNumber $PartitionSystem.PartitionNumber -FileSystem 'fat32' -LabelSystem $LabelSystem

        Write-Verbose "Setting GPT System Partition GptType {c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
        $PartitionSystem | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'

        Write-Verbose "Setting GPT System Partition NewDriveLetter S"
        $PartitionSystem | Set-Partition -NewDriveLetter S
        
        Write-Verbose "Creating MSR Partition GptType {e3c9e316-0b5c-4db8-817d-f92df00215ae}"
        $null = New-Partition -DiskNumber $DiskNumber -Size $SizeMSR -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'
    }
    #=======================================================================
    #	MBR
    #=======================================================================
    if ($PartitionStyle -eq 'MBR') {
        Write-Verbose "Creating MBR System Partition as Active"
        $PartitionSystem = New-Partition -DiskNumber $DiskNumber -Size $SizeSystemMbr -IsActive
        
        Write-Verbose "Formatting MBR System Partition NTFS with Label $LabelSystem"
        Diskpart-FormatSystemPartition -DiskNumber $DiskNumber -PartitionNumber $PartitionSystem.PartitionNumber -FileSystem 'ntfs' -LabelSystem $LabelSystem

        Write-Verbose "Setting MBR System Partition NewDriveLetter S"
        $PartitionSystem | Set-Partition -NewDriveLetter S
    }
}

#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green "Start OSDCloud"

Start-OSDCloud -OSLanguage en-gb -OSBuild 21H2 -OSEdition Pro -ZTI

#Restart from WinPE

Write-Host -ForegroundColor Green "Restarting in 20 seconds!"

Start-Sleep -Seconds 20

wpeutil reboot
