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
    [string] $BuildVersion,
    [string] $ModuleName,
    [string] $ModulePath = "$PSScriptRoot\..\$ModuleName",
    [string] $LicenseUri,
    [string] $ProjectUri,
    [string[]] $Tags,
    [AllowNull()]
    [string] $Prerelease
)

$manifestPath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
$moduleParams = @{
    ModuleVersion = $BuildVersion
    Path = $manifestPath
    LicenseUri = $LicenseUri
    ProjectUri = $ProjectUri
    Tags = $Tags
}

if ($Prerelease) {
    $moduleParams["Prerelease"] = $Prerelease
}

Write-Host "Updating module manifest ($manifestPath) with the following values: $($moduleParams | ConvertTo-Json)"
Update-ModuleManifest @moduleParams