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

begin {
    $manifestPath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
    $manifest = Import-LocalizedData -BaseDirectory $ModulePath -FileName "$ModuleName.psd1"

    #region Install dependencies
    foreach ($module in $manifest.RequiredModules) {
        switch ($module.GetType().Name) {
            "String" { Install-Module -Name $_ -Scope CurrentUser -Force -Repository PSGallery }
            "Hashtable" { Install-Module -Name $_["ModuleName"] -RequiredVersion ["RequiredVersion"] -Scope CurrentUser -Force -Repository PSGallery }
        }
    }
    #endregion

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
}
process {
    Write-Host "Updating module manifest ($manifestPath) with the following values: $($moduleParams | ConvertTo-Json)"
    Update-ModuleManifest @moduleParams
}




