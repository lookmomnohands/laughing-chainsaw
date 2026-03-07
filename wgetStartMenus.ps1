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

# Function to count files in the GitHub repo (using GitHub API)
function Get-GitHubFileCount {
    $apiUrl = "https://api.github.com/repos/lookmomnohands/laughing-chainsaw/git/trees/main?recursive=1"
    try {
        $response = Invoke-WebRequest -Uri $apiUrl -Headers @{ "User-Agent" = "Mozilla/5.0" } -UseBasicParsing
        $json = $response.Content | ConvertFrom-Json
        $fileCount = ($json.tree | Where-Object { $_.type -eq "blob" }).Count
        return $fileCount
    } catch {
        Write-Output "Error retrieving file count from GitHub: $_"
        return $null
    }
}

# Download Zip
try {
    Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip -UseBasicParsing
    if (Test-Path $tempZip) {
        Write-Output "Downloaded zip successfully: $tempZip"
        # Get expected file count from GitHub only after successful download
        $expectedFileCount = Get-GitHubFileCount
        if ($null -ne $expectedFileCount) {
            Write-Output "Expected to extract $expectedFileCount files."
        }
    } else {
        Write-Output "Failed to download the zip."
        exit
    }
}
catch {
    Write-Output "Error downloading zip: $_"
    exit
}

# Extract Zip to temp folder
$extractTempFolder = "C:\temp\startmenutweaks_extracted"
try {
    if (Test-Path $extractTempFolder) {
        Remove-Item -Path $extractTempFolder -Recurse -Force
    }
    Expand-Archive -Path $tempZip -DestinationPath $extractTempFolder -Force
    Write-Output "Successfully extracted the zip archive to $extractTempFolder."
}
catch {
    Write-Output "Error during extraction: $_"
    exit
}

# Count the number of files extracted after extraction
$repoFolder = Get-ChildItem -Path $extractTempFolder | Where-Object { $_.PSIsContainer } | Select-Object -First 1
if ($null -eq $repoFolder) {
    Write-Output "Could not find extracted repo folder."
    exit
}
$extractedFileCount = (Get-ChildItem -Path $repoFolder.FullName -Recurse | Measure-Object -Property Length -Sum).Count
Write-Output "Extracted $extractedFileCount files."

# Exclusion array for files not to move
$excludeNames = @("LICENSE", "README.md", "wgetStartMenus.ps1")

# Helper function to recursively move and merge directories
function Move-Merge-Directory {
    param (
        [string]$Source,
        [string]$Destination
    )
    if (-not (Test-Path $Destination)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    }
    Get-ChildItem -Path $Source | ForEach-Object {
        $childDest = Join-Path -Path $Destination -ChildPath $_.Name
        if ($_.PSIsContainer) {
            Move-Merge-Directory -Source $_.FullName -Destination $childDest
        } else {
            Move-Item -Path $_.FullName -Destination $childDest -Force
            # Mark touched.txt as hidden after move
            if ($_.Name -eq "touched.txt") {
                Set-ItemProperty -Path $childDest -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
            }
        }
    }
    # Remove source directory if empty
    if ((Get-ChildItem -Path $Source).Count -eq 0) {
        Remove-Item -Path $Source -Force
    }
}

# Move files/folders to C:\ if the count matches
if ($expectedFileCount -eq $extractedFileCount) {
    Write-Output "File count matches. Moving files to C:\."
    Get-ChildItem -Path $repoFolder.FullName | ForEach-Object {
        if ($excludeNames -contains $_.Name) {
            return
        }
        $dest = Join-Path -Path $destinationFolder -ChildPath $_.Name
        if ($_.PSIsContainer) {
            Move-Merge-Directory -Source $_.FullName -Destination $dest
        } else {
            Move-Item -Path $_.FullName -Destination $dest -Force
            if ($_.Name -eq "touched.txt") {
                Set-ItemProperty -Path $dest -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
            }
        }
    }
    # Delete the extracted repo folder if empty
    if ((Get-ChildItem -Path $repoFolder.FullName).Count -eq 0) {
        Remove-Item -Path $repoFolder.FullName -Force
    }
    # Remove any remaining empty folders in temp (one-liner, no function needed)
    Get-ChildItem -Path $extractTempFolder -Directory -Recurse | Where-Object { @(Get-ChildItem -Path $_.FullName -Force).Count -eq 0 } | Remove-Item -Force
} else {
    Write-Output "File count mismatch. Not moving files."
}

# Download the latest HP Image Assistant URL dynamically
function Get-LatestHPInstallerUrl {
    $htmlContent = Invoke-WebRequest -Uri $sourceHPInstallerUrl -UseBasicParsing
    $latestUrl = ($htmlContent.Links | Where-Object { $_.href -like "*hp-hpia-*.exe" } | Select-Object -Last 1).href
    return $latestUrl
}

# Download the latest HP Image Assistant
try {
    $hpInstallerUrl = Get-LatestHPInstallerUrl
    $hpInstallerFileName = Split-Path -Path $hpInstallerUrl -Leaf
    $hpInstallerOutputPath = Join-Path -Path "C:\temp" -ChildPath $hpInstallerFileName

    Invoke-WebRequest -Uri $hpInstallerUrl -OutFile $hpInstallerOutputPath -UseBasicParsing
    Write-Output "Downloaded HP Image Assistant to: $hpInstallerOutputPath."
}
catch {
    Write-Output "Error downloading HP Image Assistant: $_"
    exit
}

# Run the executable silently
if (Test-Path $hpInstallerOutputPath) {
    try {
        Start-Process -FilePath $hpInstallerOutputPath -ArgumentList "/s /e"
        Write-Output "HP Image Assistant installed silently."
    }
    catch {
        Write-Output "Error running the installer: $_"
    }
} else {
    Write-Output "Installer not found: $hpInstallerOutputPath"
}
