param (
    [string]$namespace,
    [string]$subNamespaces,
    [string]$className,
    [bool]$generateInterface = $true,      # Default value is $true
    [bool]$generateFSharp = $false,        # Default value is $false
    [switch]$useSmartNamespace = $false    # Default value is $false
)

# If useSmartNamespace is specified, try to find a csproj or fsproj file and use it as the namespace
if ($useSmartNamespace) {
    $csprojFile = Get-ChildItem -Filter *.csproj | Select-Object -First 1
    $fsprojFile = Get-ChildItem -Filter *.fsproj | Select-Object -First 1

    if ($csprojFile) {
        $namespace = $csprojFile.BaseName
    }
    elseif ($fsprojFile) {
        $namespace = $fsprojFile.BaseName
    }
    else {
        Write-Host "Error: No .csproj or .fsproj file found in the current working directory."
        Exit 1
    }
}

# If subNamespaces is null or empty, set $namespaceWithSubNamespaces to just $namespace
if ([string]::IsNullOrEmpty($subNamespaces)) {
    $namespaceWithSubNamespaces = $namespace
}
else {
    $namespaceWithSubNamespaces = "$namespace.$subNamespaces"
}

# Start building the C# code content
$cSharpCode = @"
namespace $namespaceWithSubNamespaces;

"@

# Start building the F# code content
$fSharpCode = @"
namespace $namespaceWithSubNamespaces

"@

# If generateInterface is $true, include the interface definition in C# and F#
if ($generateInterface) {
    $cSharpCode += @"
public interface I$className
{

}
"@

    $fSharpCode += @"
type I$className =
    abstract member MethodName : unit -> unit
"@
}

# Add the class definition in C# and F#
$cSharpCode += @"
public class $className
{

}
"@

$fSharpCode += @"
type $className() =
    member this.MethodName() = ()
"@

# Create the file and write the code content for C#
$cSharpFileName = "$className.cs"
$cSharpCode | Out-File -FilePath $cSharpFileName -Encoding UTF8

# Create the file and write the code content for F# if generateFSharp is $true
if ($generateFSharp) {
    $fSharpFileName = "$className.fs"
    $fSharpCode | Out-File -FilePath $fSharpFileName -Encoding UTF8

    Write-Host "C# and F# code files generated successfully. C# File name: $cSharpFileName, F# File name: $fSharpFileName"
}
else {
    Write-Host "C# code file generated successfully. File name: $cSharpFileName"
}
