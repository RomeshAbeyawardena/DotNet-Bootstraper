param (
    [string]$DirectoryBuildPropsPath,
    [string]$ComponentToIncrement,
    [switch]$DryRun,
    [string]$NewVersion
)

# Load the XML content from Directory.build.props
try {
    $xml = [xml](Get-Content $DirectoryBuildPropsPath)
}
catch {
    Write-Error "Error reading the XML file: $_"
    exit 1
}

# Extract the current Version and FileVersion from the XML
$versionNode = $xml.Project.PropertyGroup.Version
$fileVersionNode = $xml.Project.PropertyGroup.FileVersion

if (-not $versionNode -or -not $fileVersionNode) {
    Write-Error "Version and/or FileVersion nodes not found in the XML file."
    exit 1
}

# Parse the current Version and FileVersion as System.Version objects
try {
    $currentVersion = [System.Version]::new($versionNode)
    $currentFileVersion = [System.Version]::new($fileVersionNode)
}
catch {
    Write-Error "Error parsing the Version/FileVersion as System.Version: $_"
    exit 1
}

# Function to increment version and reset following components
function IncrementVersion {
    param (
        [System.Version]$version,
        [string]$component
    )

    switch ($component) {
        "Major" {
            $version = [System.Version]::new($version.Major + 1, 0, 0, 0)
        }
        "Minor" {
            $version = [System.Version]::new($version.Major, $version.Minor + 1, 0, 0)
        }
        "Revision" {
            $version = [System.Version]::new($version.Major, $version.Minor, $version.Build + 1, 0)
        }
        "Build" {
            $version = [System.Version]::new($version.Major, $version.Minor, $version.Build, $version.Revision + 1)
        }
        default {
            Write-Error "Invalid value for the 'ComponentToIncrement' parameter. It must be 'Major', 'Minor', 'Revision', or 'Build'."
            exit 1
        }
    }

    $version
}

# Determine which component to increment or set new version
if ($NewVersion) {
    try {
        $newVersion = [System.Version]::new($NewVersion)
    }
    catch {
        Write-Error "Error parsing the provided 'NewVersion' as System.Version: $_"
        exit 1
    }

    if ($newVersion -eq $currentVersion -and $newVersion -eq $currentFileVersion) {
        Write-Warning "Provided 'NewVersion' is the same as the existing Version and FileVersion. No changes will be made."
        exit 0
    }

    Write-Warning "Setting a new version will overwrite the existing version completely."
}
else {
    $newVersion = IncrementVersion -version $currentVersion -component $ComponentToIncrement
}

# Display the expected changes
Write-Host "Current Version: $currentVersion"
Write-Host "New Version:     $newVersion"

if ($DryRun) {
    Write-Host "Dry-run mode: No changes will be made to the XML file."
}
else {
    # Update the XML with the new Version and FileVersion
    $xml.Project.PropertyGroup.Version = $newVersion.ToString()
    $xml.Project.PropertyGroup.FileVersion = $newVersion.ToString()

    # Save the updated XML back to the Directory.build.props file
    try {
        $currentPath = Get-Location
        $xml.Save("$currentPath/$DirectoryBuildPropsPath")
    }
    catch {
        Write-Error "Error saving the updated XML back to the file: $_"
        exit 1
    }

    Write-Host "Version and FileVersion updated successfully in $DirectoryBuildPropsPath."
}
