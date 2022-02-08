<#
    .SYNOPSIS
        A simple build script for the Tenant Management Framework
    .PARAMETER BuildVersion
        Provide a version in the format "{MAJOR}.{MINOR}.{PATCH}"
        Example: 1.0.1
    .PARAMETER ModuleName
        Provide the name of the Powershell Module.
        Example: TMF
    .PARAMETER ModulePath
        Path to the module directory.
#>

Param(
    [string] $BuildVersion = $env:buildVer,
    [string] $ModuleName = $env:moduleName,
    [string] $ModulePath = "$PSScriptRoot\..\TMF",
    [string] $LicenseUri = $env:licenseUri,
    [string] $ProjectUri = $env:projectUri,
    [string[]] $Tags = $env:tags,
    [string] $Prerelease = $env:prerelease
)

$manifestPath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
$moduleParams = @{
    Path = $manifestPath
    LicenseUri = $LicenseUri
    ProjectUri = $ProjectUri
    Tags = $Tags
}

if ($Prerelease) {
    $moduleParams["Prerelease"] = $Prerelease
}

Update-ModuleManifest @moduleParams