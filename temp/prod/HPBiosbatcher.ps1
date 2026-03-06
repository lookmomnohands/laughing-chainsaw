$timestamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"

# Initial Paths
$BasePathCurrent = ".\"
$BasePathFallback = "C:\temp\prod\"
# File checks
$BiosUtilityPath = $BasePathCurrent + "BiosConfigUtility64.exe"
$PasswordFile = $BasePathCurrent + "runthispwd.bin"
$ConfigFile = $BasePathCurrent + "CRE_HP_BIOS_aug.bcu"
# Generate a unique log path based on current timestamp
$LogPath = $BasePathCurrent + "HP_BiosConfigLog_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt"

# Check if all files exist in the current directory
if (!(Test-Path $BiosUtilityPath) -or !(Test-Path $PasswordFile) -or !(Test-Path $ConfigFile)) {
    # If any file is missing, switch to the fallback path
    $BiosUtilityPath = $BasePathFallback + "BiosConfigUtility64.exe"
    $PasswordFile = $BasePathFallback + "runthispwd.bin"
    $ConfigFile = $BasePathFallback + "CRE_HP_BIOS_aug.bcu"
    $LogPath = $BasePathFallback + "HP_BiosConfigLog.txt"
}

# Function to apply BIOS settings
function Apply-BIOSConfig {
    param (
        [string]$BiosUtilityPath,
        [string]$PasswordFile,
        [string]$ConfigFile,
        [string]$LogPath
    )

    try {
        # Run both commands with the /verbose flag
        $outputNpwd = & $BiosUtilityPath /npwdfile:$PasswordFile /set:$ConfigFile /logpath:$LogPath /l /verbose 2>&1
        $outputCpwd = & $BiosUtilityPath /cpwdfile:$PasswordFile /set:$ConfigFile /logpath:$LogPath /l /verbose 2>&1

        # Combine the outputs for easier handling
        $output = $outputNpwd + "`n" + $outputCpwd

        # Log the complete output for debugging
        Add-Content -Path $LogPath -Value $output

        # Check for specific patterns indicating warnings vs. errors
        if ($output -match "Invalid setting value") {
            Add-Content -Path $LogPath -Value "Warning: Invalid setting value encountered."
        } elseif ($output -match "Error" -or $output -match "BCU error") {
            Add-Content -Path $LogPath -Value "An error occurred during BIOS configuration."
        } else {
            Add-Content -Path $LogPath -Value "BIOS configuration succeeded."
        }
    } catch {
        Add-Content -Path $LogPath -Value "Failed to run ${BiosUtilityPath}: $_"
    }
}

# Run the BIOS configuration
Apply-BIOSConfig -BiosUtilityPath $BiosUtilityPath -PasswordFile $PasswordFile -ConfigFile $ConfigFile -LogPath $LogPath

# Add final entry to the log if the log file exists
if (Test-Path $LogPath) {
    $logContent = Get-Content $LogPath

    # Improved success detection based on output
    if ($logContent -match '<SETTING changeStatus="pass"' -or $logContent -match "No changes detected") {
        Add-Content -Path $LogPath -Value "Completed BIOS configuration attempts."
    } else {
        Add-Content -Path $LogPath -Value "BIOS configuration failed."
    }
}

# Registry path to create
$RegistryPath = "HKLM:\SOFTWARE\WOW6432Node\Policies\CRE_HP_Bios"

# Check if the registry key exists, and create it if it doesn't
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force
}

# Define the error status
$ErrorStatus = 0

# Update error status based on log content
if ($logContent -match 'returnCode="19"') {
    $ErrorStatus += 1
}
if ($logContent -match 'returnCode="20"') {
    $ErrorStatus += 1
}
if ($logContent -match 'returnCode="21"') {
    $ErrorStatus += 1
}
if ($logContent -match 'An operation failed') {
    $ErrorStatus += 1
}

# Optional confirmation
New-ItemProperty -Path $RegistryPath -Name "BIOSConfigErrorStatus" -Value $ErrorStatus -PropertyType DWord -Force
New-ItemProperty -Path $RegistryPath -Name "BIOSConfigApplied" -Value "Updated via script at $timestamp" -PropertyType String -Force
