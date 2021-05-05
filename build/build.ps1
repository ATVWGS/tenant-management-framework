<#
    .SYNOPSIS
        A simple build script for the Tenant Management Framework
    .PARAMETER buildVersion
        Provide a version in the format "{MAJOR}.{MINOR}.{PATCH}"
        Example: 1.0.1
    .PARAMETER moduleName
        Provide the name of the Powershell Module.
        Example: TMF
    .PARAMETER modulePath
        Path to the module directory.
#>

Param(
    [string] $buildVersion = $env:BUILDVER,
    [string] $moduleName = "TMF",
    [string] $modulePath = "$PSScriptRoot\..\TMF"
)

#region Update module manifest
$manifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"
$manifestContent = Get-Content -Path $manifestPath -Raw
$manifestContent = $manifestContent -replace "ModuleVersion = '[\d]+.[\d]+.[\d]+'", ("ModuleVersion = '{0}'" -f $buildVersion)
$manifestContent | Set-Content -Path $manifestPath
#endregion