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
    [string] $Prerelease = $env:prerelease,
    [string] $Description = $env:description
)

$manifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"
$moduleParams = @{
    Path = $manifestPath
    Author = $Author
    CompanyName = $CompanyName
    Copyright = $Copyright
    LicenseUri = $LicenseUri
    ProjectUri = $ProjectUri
    Tags = $Tags
    Description = $Description
}

if ($Prerelease) {
    $moduleParams["Prerelease"] = $Prerelease
}

Update-ModuleManifest @moduleParams