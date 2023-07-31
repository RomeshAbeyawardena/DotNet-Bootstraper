param (
    [string]$ProjectName,
    [switch]$AddCore,
    [switch]$AddExtensions,
    [switch]$AddWeb,
    [string]$UnitTestFramework,
    [bool]$GenerateDirectoryBuildProps = $true,
    [string]$OutputDirectory,
    [string]$WebProjectName,  # New parameter for web project name
    [string]$AdditionalParameters
)

$configuredProjectPaths = [System.Collections.ArrayList]::new()

function Create-Subfolder {
    param (
        [string]$Path,
        [string]$SubfolderName
    )

    $subfolderPath = Join-Path -Path $Path -ChildPath $SubfolderName
    New-Item -ItemType Directory -Path $subfolderPath -ErrorAction Stop | Out-Null
    Write-Host "Created subfolder: $subfolderPath"
}

$hasNoAdditionalParameters = [System.String]::IsNullOrWhiteSpace($AdditionalParameters)

function Create-CoreProject {
    param (
        [string]$ProjectName,
        [string]$AdditionalParameters
    )
    If ($hasNoAdditionalParameters)
    {
        dotnet new classlib -n $ProjectName -o "$ProjectName/$ProjectName"
    }
    else
    {
        dotnet new classlib -n $ProjectName -o $"$ProjectName/$ProjectName" $AdditionalParameters
    }

    Write-Host "Created Core project: $ProjectName"

    $configuredProjectPaths.Add("$ProjectName/$ProjectName")
}

function Create-ExtensionsProject {
    param (
        [string]$ProjectName,
        [string]$AdditionalParameters
    )

    $extensionsProjectName = "$ProjectName.Extensions"  # Prepend the ProjectName
    $extensionsProjectPath = Join-Path -Path $ProjectName -ChildPath $extensionsProjectName
    Write-Host $extensionsProjectPath
    If ($hasNoAdditionalParameters)
    {
        dotnet new classlib -n $extensionsProjectName -o $extensionsProjectPath
    }
    else
    {
        dotnet new classlib -n $extensionsProjectName -o $extensionsProjectPath $AdditionalParameters
    }

    Write-Host "Created Extensions project: $extensionsProjectPath"
    $configuredProjectPaths.Add($extensionsProjectPath)
}

function Create-WebProject {
    param (
        [string]$ProjectName,
        [string]$WebProjectName,
        [string]$AdditionalParameters
    )

    $webProjectName = "$ProjectName.$WebProjectName"  # Prepend the ProjectName
    $webProjectPath = Join-Path -Path $ProjectName -ChildPath $webProjectName
    Write-Host $webProjectPath
    If ($hasNoAdditionalParameters)
    {
        dotnet new web -n $webProjectName -o $webProjectPath
    }
    else {
        dotnet new web -n $webProjectName -o $webProjectPath $AdditionalParameters
    }
    Write-Host "Created Web project: $webProjectPath"
    $configuredProjectPaths.Add($webProjectPath)
}

function Create-UnitTestProject {
    param (
        [string]$ProjectName,
        [string]$UnitTestFramework,
        [string]$AdditionalParameters
    )

    $unitTestProjectName = "$ProjectName.Tests"  # Prepend the ProjectName
    $unitTestProjectPath = Join-Path -Path $ProjectName -ChildPath $unitTestProjectName

    Write-Host $unitTestProjectPath

    if($hasNoAdditionalParameters)
    {
        dotnet new $UnitTestFramework -n $unitTestProjectName -o $unitTestProjectPath
    }
    else
    {
        dotnet new $UnitTestFramework -n $unitTestProjectName -o $unitTestProjectPath $AdditionalParameters
    }
    
    Write-Host "Created Unit Test project: $unitTestProjectPath"
    $configuredProjectPaths.Add($unitTestProjectPath)
}

function Create-DirectoryBuildProps {
    param (
        [string]$OutputDirectory
    )

    $directoryBuildPropsPath = Join-Path -Path $OutputDirectory -ChildPath "Directory.build.props"
    $directoryBuildPropsContent = @"
<Project>
  <PropertyGroup>
    <!-- Customize shared properties for projects in this solution -->
    <Authors>Romesh Abeyawardena</Authors>
    <Company>DNI</Company>
    <GenerateDocumentationFile>False</GenerateDocumentationFile>
    <GeneratePackageOnBuild>False</GeneratePackageOnBuild>
    <FileVersion>0.0.0.0</FileVersion>
    <PackageLicenseExpression>MIT</PackageLicenseExpression>
    <PackageReadmeFile>README.md</PackageReadmeFile>
    <Version>0.0.0.0</Version>
    <VersionSuffix>DEV</VersionSuffix>
  </PropertyGroup>
</Project>
"@
    $directoryBuildPropsContent | Out-File -FilePath $directoryBuildPropsPath -Encoding UTF8
    Write-Host "Created Directory.build.props: $directoryBuildPropsPath"
}

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDirectory -ErrorAction Stop | Out-Null
}

function Create-README {
    param (
        [string]$ProjectName
    )

    $readmePath = Join-Path -Path $ProjectName -ChildPath "README.md"
    if (-not (Test-Path -Path $readmePath)) {
        $readmeContent = @"
# $ProjectName

This is the project README. Add a brief project description and any relevant information here.

## Getting Started

Provide instructions on how to get the project up and running.

## Usage

Explain how to use the project and its features.

## Contributing

Explain how others can contribute to the project.

## License

Specify the project's license here.
"@
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
        Write-Host "Created README.md: $readmePath"
    }
}

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDirectory -ErrorAction Stop | Out-Null
}

# Change to the output directory
Set-Location $OutputDirectory
Write-Host "Output directory: $OutputDirectory"

# Create the subfolder
Create-Subfolder -Path $OutputDirectory -SubfolderName $ProjectName

Set-Location "$OutputDirectory/$ProjectName"
# Create the solution file
dotnet new sln

cd ..

# Create Core project if specified
if ($AddCore) {
    $path = Create-CoreProject -ProjectName $ProjectName -AdditionalParameters $AdditionalParameters
}

# Create Extensions project if specified
if ($AddExtensions) {
    $path = Create-ExtensionsProject -ProjectName $ProjectName -AdditionalParameters $AdditionalParameters
}

# Create Web project if specified
if ($AddWeb) {
    $path = Create-WebProject -ProjectName $ProjectName -WebProjectName $WebProjectName -AdditionalParameters $AdditionalParameters
    
}

# Create Unit Test project if specified
if ($UnitTestFramework) {
    $path = Create-UnitTestProject -ProjectName $ProjectName -UnitTestFramework $UnitTestFramework -AdditionalParameters $AdditionalParameters
}

foreach($path in $configuredProjectPaths) {
    dotnet sln "$OutputDirectory/$ProjectName/$ProjectName.sln" add $path
}

Set-Location "$OutputDirectory/$ProjectName"

# Generate Directory.build.props if specified
if ($GenerateDirectoryBuildProps) {
    Create-DirectoryBuildProps -OutputDirectory $OutputDirectory
}

# Create default README.md
Create-README -ProjectName $ProjectName

cd ..