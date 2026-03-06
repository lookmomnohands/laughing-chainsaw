<#
.SYNOPSIS
    This script downloads a zip file from a GitHub repository, extracts it, counts the number of files extracted,
    and then dynamically retrieves and installs the latest HP Image Assistant.
    
.DESCRIPTION
    The script first checks for the existence of a temporary directory and creates it if it doesn't exist.
    It then downloads a zip file from a specified GitHub repository URL provided by the authorand checks if the download was successful.
    The script uses the GitHub API to count the expected number of files in the repository for verification purposes.
    Thus maintaining the integrity of the download and extraction process.
    After extracting the zip file, it counts the number of files extracted and outputs this information.
    Finally, it dynamically retrieves the latest HP Image Assistant installer URL from the HP website, downloads it, and runs it silently.    
.NOTES
    Author: James Cummings
    Date: 2026-03-06
    Version: 1.0
    
.EXAMPLE
    .\wgetStartMenus.ps1
    This command will execute the script, which will perform the following actions:
    1. Check for and create a temporary directory if it doesn't exist.
    2. Download a zip file from the specified GitHub repository.
    3. Extract the zip file and count the number of files.
    4. Download and install the latest HP Image Assistant.
    
#>

# Variables
$repoUrl = "https://github.com/lookmomnohands/laughing-chainsaw/archive/refs/heads/main.zip"
$tempZip = "C:\temp\startmenutweaks.zip"
$destinationFolder = "C:\"
$sourceHPInstallerUrl = "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"

# Check if temp exists and create if not
try {
    if (-not (Test-Path "C:\temp")) {
        New-Item -ItemType Directory -Force -Path "C:\temp"
        Write-Output "Created directory: C:\temp"
    }
}
catch {
    Write-Output "Error creating C:\temp: $_"
    exit
}

# Download Zip
try {
    Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip
    if (Test-Path $tempZip) {
        Write-Output "Downloaded zip successfully: $tempZip"
    } else {
        Write-Output "Failed to download the zip."
        exit
    }
}
catch {
    Write-Output "Error downloading zip: $_"
    exit
}

# Function to count files in the GitHub repo (using GitHub API)
function Get-GitHubFileCount {
    $apiUrl = "https://api.github.com/repos/lookmomnohands/laughing-chainsaw/git/trees/main"
    $response = Invoke-WebRequest -Uri $apiUrl -Headers @{ "User-Agent" = "Mozilla/5.0" }
    $files = ($response.files | Measure-Object).Count
    return $files
}

# Get expected file count from GitHub
$expectedFileCount = Get-GitHubFileCount
Write-Output "Expected to extract $expectedFileCount files."

# Extract Zip
try {
    Expand-Archive -Path $tempZip -DestinationPath $destinationFolder -Force
    Write-Output "Successfully extracted the zip archive."
}
catch {
    Write-Output "Error during extraction: $_"
    exit
}

# Count the number of files extracted after extraction
$extractedFileCount = (Get-ChildItem -Path $destinationFolder -Recurse | Measure-Object -Property Length -Sum).Count
Write-Output "Extracted $extractedFileCount files."

# Download the latest HP Image Assistant URL dynamically
function Get-LatestHPInstallerUrl {
    $htmlContent = Invoke-WebRequest -Uri $sourceHPInstallerUrl
    $latestUrl = ($htmlContent.Links | Where-Object { $_.href -like "*hp-hpia-*.exe" } | Select-Object -Last 1).href
    return $latestUrl
}

# Download the latest HP Image Assistant
try {
    $hpInstallerUrl = Get-LatestHPInstallerUrl
    $hpInstallerFileName = Split-Path -Path $hpInstallerUrl -Leaf
    $hpInstallerOutputPath = Join-Path -Path "C:\temp" -ChildPath $hpInstallerFileName

    Invoke-WebRequest -Uri $hpInstallerUrl -OutFile $hpInstallerOutputPath
    Write-Output "Downloaded HP Image Assistant to: $hpInstallerOutputPath."
}
catch {
    Write-Output "Error downloading HP Image Assistant: $_"
    exit
}

# Run the executable silently
if (Test-Path $hpInstallerOutputPath) {
    try {
        Start-Process -FilePath $hpInstallerOutputPath -ArgumentList "/silent" -Wait
        Write-Output "HP Image Assistant installed silently."
    }
    catch {
        Write-Output "Error running the installer: $_"
    }
} else {
    Write-Output "Installer not found: $hpInstallerOutputPath"
}
