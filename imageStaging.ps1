### Ortus Windows Image Deployment Script v2 ###

# Require Administrator privileges
#Requires -RunAsAdministrator

# Customize Write-Progress colors
$Host.PrivateData.ProgressBackgroundColor = 'DarkGreen'
$Host.PrivateData.ProgressForegroundColor = 'Yellow'

# Enable strict error handling
$ErrorActionPreference = "Stop"

# Function to write log messages
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path "C:\ImageStaging\deployment.log" -Value $logMessage -ErrorAction SilentlyContinue
}

# Function to test and create directories
function Test-CreatePath {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        try {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-Log "Created directory: $Path"
            return $true
        } catch {
            Write-Log "Failed to create directory: $Path - $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    return $true
}

# Function to execute DISM commands with error checking
function Invoke-DismCommand {
    param(
        [string]$Arguments,
        [string]$Operation
    )
    
    Write-Log "Executing DISM: $Operation"
    try {
        $result = & dism $Arguments.Split(' ')
        if ($LASTEXITCODE -ne 0) {
            throw "DISM command failed with exit code: $LASTEXITCODE"
        }
        Write-Log "DISM operation completed successfully: $Operation"
        return $true
    } catch {
        Write-Log "DISM operation failed: $Operation - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to cleanup mounted images
function Cleanup-MountedImages {
    param([string]$MountDir)
    
    if (Test-Path $MountDir) {
        Write-Log "Cleaning up mounted image at: $MountDir"
        try {
            & dism /Unmount-Image /MountDir:$MountDir /Discard 2>$null
            Write-Log "Successfully unmounted image at: $MountDir"
        } catch {
            Write-Log "Warning: Could not unmount image at: $MountDir" "WARN"
        }
    }
}

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

# Create log file
try {
    if (-not (Test-Path "C:\ImageStaging")) {
        New-Item -Path "C:\ImageStaging" -ItemType Directory -Force | Out-Null
    }
    Write-Log "=== Starting Ortus Windows Image Update Tool ==="
} catch {
    Write-Host "Warning: Could not create log file" -ForegroundColor Yellow
}

## Prerequisites Check ##
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if DISM is available
try {
    $null = & dism /? 2>$null
    Write-Log "DISM is available"
} catch {
    Write-Log "DISM is not available or not in PATH" "ERROR"
    Write-Host "ERROR: DISM is not available. Please ensure Windows ADK is installed." -ForegroundColor Red
    exit 1
}

# Check if ISO is mounted
if (-not (Test-Path "D:\sources\install.wim")) {
    Write-Host "**************************************************************" -ForegroundColor white -BackgroundColor red
    Write-Host "* ERROR: Windows ISO not found at D:\sources\install.wim    *" -ForegroundColor white -BackgroundColor red
    Write-Host "* Please mount the Windows ISO to D:\ before continuing!    *" -ForegroundColor white -BackgroundColor red
    Write-Host "**************************************************************" -ForegroundColor white -BackgroundColor red
    Write-Log "Windows ISO not found at D:\sources\install.wim" "ERROR"
    exit 1
}

# Verify WIM file and get index information
Write-Host "Verifying WIM file..." -ForegroundColor Yellow
try {
    $wimInfo = & dism /Get-WimInfo /WimFile:D:\sources\install.wim 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get WIM info"
    }
    Write-Log "WIM file verified successfully"
    
    # Check if index 5 exists
    $indexExists = $wimInfo | Select-String "Index : 5"
    if (-not $indexExists) {
        Write-Host "WARNING: Index 5 not found in WIM file. Please verify the correct index to use." -ForegroundColor Yellow
        Write-Log "Index 5 not found in WIM file" "WARN"
    }
} catch {
    Write-Log "Failed to verify WIM file: $($_.Exception.Message)" "ERROR"
    Write-Host "ERROR: Could not verify WIM file. Please check the file integrity." -ForegroundColor Red
    exit 1
}

# Check and create required directories
$requiredPaths = @(
    "C:\ImageStaging",
    "C:\Drivers",
    "C:\inetpub\wwwroot\esd"
)

foreach ($path in $requiredPaths) {
    if (-not (Test-CreatePath $path)) {
        Write-Host "ERROR: Failed to create required directory: $path" -ForegroundColor Red
        exit 1
    }
}

# Check device folders and driver folders
foreach ($device in $deviceList) {
    $devicePath = "C:\ImageStaging\$device"
    $mountPath = "C:\ImageStaging\$device\Mount"
    $driverPath = "C:\Drivers\$device"
    
    if (-not (Test-CreatePath $devicePath)) {
        Write-Host "ERROR: Failed to create device directory: $devicePath" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-CreatePath $mountPath)) {
        Write-Host "ERROR: Failed to create mount directory: $mountPath" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $driverPath)) {
        Write-Host "WARNING: Driver directory not found: $driverPath" -ForegroundColor Yellow
        Write-Log "Driver directory not found: $driverPath" "WARN"
    }
}

Write-Host "Prerequisites check completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "**************************************************************" -ForegroundColor white -BackgroundColor red
Write-Host "* Make sure Windows ISO is mounted to D:\ before continuing! *" -ForegroundColor white -BackgroundColor red
Write-Host "**************************************************************" -ForegroundColor white -BackgroundColor red
Write-Host ""
Write-Host "Press any key to continue or CTRL+C to cancel..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

Write-Host "**********************************************************************************" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "* Continuing update. If updating fails, use 'DISM /cleanup-wim' to clean up files *" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "**********************************************************************************" -ForegroundColor white -BackgroundColor darkgreen

## Start Copying WIM from Source ##
Write-Host ""
Write-Host "Copying install.wim from source..." -ForegroundColor white -BackgroundColor blue
Write-Host ""

try {
    Copy-Item D:\sources\install.wim -Destination C:\ImageStaging\install.wim -Force
    Set-ItemProperty -Path "C:\ImageStaging\install.wim" -Name IsReadOnly -Value $false
    Write-Log "Successfully copied install.wim from source"
} catch {
    Write-Log "Failed to copy install.wim from source: $($_.Exception.Message)" "ERROR"
    Write-Host "ERROR: Failed to copy install.wim from source" -ForegroundColor Red
    exit 1
}

### Step 3 (Copy install.wim to device folders)
$totalDevices = $deviceList.Count
$currentDevice = 0

# Clear the console before starting progress to ensure clean display
Clear-Host
Write-Host "Starting file copy operations..." -ForegroundColor white -BackgroundColor blue
Write-Host ""

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
    
    try {
        Copy-Item C:\ImageStaging\install.wim -Destination "C:\ImageStaging\$device\install.wim" -Force
        Set-ItemProperty -Path "C:\ImageStaging\$device\install.wim" -Name IsReadOnly -Value $false
        Write-Log "Successfully copied install.wim to $device"
    } catch {
        Write-Log "Failed to copy install.wim to $device: $($_.Exception.Message)" "ERROR"
        Write-Host "ERROR: Failed to copy install.wim to $device" -ForegroundColor Red
        exit 1
    }
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

$failedDevices = @()

foreach ($device in $deviceList) {
    $currentDevice++
    $devicePercentComplete = [math]::Round(($currentDevice / $totalDevices) * 100, 1)
    
    Write-Information "Starting $device Image Update" -InformationAction Continue
    Write-Log "Starting processing for device: $device"

    $currentTask = 0
    $deviceFailed = $false
    
<<<<<<< HEAD
    try {
        ## -- Mount Image -- ##
        $currentTask++
        Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Mounting image for $device"
        
        # Clean up any existing mount first
        Cleanup-MountedImages "C:\ImageStaging\$device\Mount"
        
        $wimFile = "C:\ImageStaging\$device\install.wim"
        $mountDir = "C:\ImageStaging\$device\Mount"
        $mountArgs = "/Mount-Image /ImageFile:`"$wimFile`" /MountDir:`"$mountDir`" /Index:5"
        if (-not (Invoke-DismCommand $mountArgs "Mount Image for $device")) {
            throw "Failed to mount image for $device"
        }
        
        ## -- Add Drivers -- ##
        $currentTask++
        Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Adding drivers for $device"
        
        $driverPath = "C:\Drivers\$device"
        if (Test-Path $driverPath) {
            $driverArgs = "/Image:`"$mountDir`" /Add-Driver /Driver:`"$driverPath`" /Recurse"
            if (-not (Invoke-DismCommand $driverArgs "Add Drivers for $device")) {
                Write-Log "Warning: Failed to add some drivers for $device, but continuing..." "WARN"
            }
        } else {
            Write-Log "No drivers found for $device, skipping driver installation" "WARN"
        }
        
        ## -- Unmount WIM and Commit Changes -- ##
        $currentTask++
        Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Unmounting and committing changes for $device"
        
        $unmountArgs = "/Unmount-Image /MountDir:`"$mountDir`" /Commit"
        if (-not (Invoke-DismCommand $unmountArgs "Unmount and Commit for $device")) {
            throw "Failed to unmount and commit image for $device"
        }
=======
    ## -- Mount Image -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Mounting image for $device"
    & dism /Mount-Image /ImageFile:"C:\ImageStaging\$device\install.wim" /MountDir:"C:\ImageStaging\$device\Mount" /Index:5 | Out-Null
    
    ## -- Add Drivers -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Adding drivers for $device"
    & dism /Image:"C:\ImageStaging\$device\Mount" /Add-Driver /Driver:"C:\Drivers\$device" /Recurse | Out-Null
    
    ## -- Unmount WIM and Commit Changes -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Unmounting and committing changes for $device"
    & dism /Unmount-Image /MountDir:"C:\ImageStaging\$device\Mount" /Commit | Out-Null
>>>>>>> bdb43bdec78092dea2309dc0e900a875f22d4370

<<<<<<< HEAD
        ## -- Convert WIM to ESD -- ##
        $currentTask++
        Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Converting WIM to ESD for $device"
        
        $esdFile = "C:\ImageStaging\$device\Win11_$device.esd"
        $exportArgs = "/Export-Image /SourceImageFile:`"$wimFile`" /SourceIndex:5 /DestinationImageFile:`"$esdFile`" /Compress:recovery /CheckIntegrity"
        if (-not (Invoke-DismCommand $exportArgs "Convert WIM to ESD for $device")) {
            throw "Failed to convert WIM to ESD for $device"
        }
=======
    ## -- Convert WIM to ESD -- ##
    $currentTask++
    $taskPercentComplete = [math]::Round(($currentTask / $totalTasks) * 100, 1)
    Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Converting WIM to ESD for $device"
    & dism /Export-Image /SourceImageFile:"C:\ImageStaging\$device\install.wim" /SourceIndex:5 /DestinationImageFile:"C:\ImageStaging\$device\Win11_$device.esd" /Compress:recovery /CheckIntegrity | Out-Null
>>>>>>> bdb43bdec78092dea2309dc0e900a875f22d4370

        ## -- Move ESD to InetPub -- ##
        $currentTask++
        Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Moving ESD file for $device"
        
        Move-Item "C:\ImageStaging\$device\Win11_$device.esd" -Destination "C:\inetpub\wwwroot\esd\Win11_$device.esd" -Force
        Write-Log "Successfully moved ESD file for $device"

        ## -- Remove install.wim -- ##
        $currentTask++
        Write-Progress -Activity "Processing device images" -Status "Device $currentDevice of $totalDevices: $device" -PercentComplete $devicePercentComplete -CurrentOperation "Task $currentTask of $totalTasks: Cleaning up install.wim for $device"
        
        Remove-Item "C:\ImageStaging\$device\install.wim" -Force
        Write-Log "Successfully cleaned up install.wim for $device"

        Write-Information "$device Update Complete" -InformationAction Continue
        Write-Log "Successfully completed processing for device: $device"
        
    } catch {
        $deviceFailed = $true
        $failedDevices += $device
        Write-Log "Failed to process device $device: $($_.Exception.Message)" "ERROR"
        Write-Host "ERROR: Failed to process device $device" -ForegroundColor Red
        
        # Cleanup on failure
        Cleanup-MountedImages "C:\ImageStaging\$device\Mount"
        
        # Remove partially created files
        $partialFiles = @(
            "C:\ImageStaging\$device\install.wim",
            "C:\ImageStaging\$device\Win11_$device.esd"
        )
        foreach ($file in $partialFiles) {
            if (Test-Path $file) {
                Remove-Item $file -Force -ErrorAction SilentlyContinue
                Write-Log "Cleaned up partial file: $file"
            }
        }
        
        Write-Host "Continuing with next device..." -ForegroundColor Yellow
    }
}

Write-Progress -Activity "Processing device images" -Completed

##############################
## Final Results Summary ##
##############################
Write-Host ""
Write-Log "=== Processing Complete ==="

if ($failedDevices.Count -eq 0) {
    Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen
    Write-Host "* All Images Updated Successfully *" -ForegroundColor white -BackgroundColor darkgreen
    Write-Host "***********************************" -ForegroundColor white -BackgroundColor darkgreen
    Write-Log "All devices processed successfully"
} else {
    Write-Host "***********************************" -ForegroundColor white -BackgroundColor red
    Write-Host "* Processing Complete with Errors *" -ForegroundColor white -BackgroundColor red
    Write-Host "***********************************" -ForegroundColor white -BackgroundColor red
    Write-Host ""
    Write-Host "Failed devices:" -ForegroundColor Red
    foreach ($device in $failedDevices) {
        Write-Host "  - $device" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Successful devices: $($deviceList.Count - $failedDevices.Count) of $($deviceList.Count)" -ForegroundColor Yellow
    Write-Log "Processing completed with $($failedDevices.Count) failures out of $($deviceList.Count) devices"
}

Write-Host ""
Write-Host "Check the log file at C:\ImageStaging\deployment.log for detailed information."
Write-Log "=== Script execution completed ==="
