Param (
    [string] $ArtifactPath = "$PWD\_tenant-management-framework",
    [string] $ModuleName = $env:moduleName,
    [string] $ApiKey = $env:apiKey,
    [string] $LicenseUri = $env:licenseUri,
    [string] $ProjectUri = $env:projectUri,
    [string[]] $Tags = $env:tags
)

$package = Get-ChildItem -Filter "*.nupkg" -Path $ArtifactPath -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item -Path $package.FullName -Destination "$PSScriptRoot\$ModuleName.zip" -Force
Expand-Archive -Path "$PSScriptRoot\$ModuleName.zip" -DestinationPath "$PSScriptRoot\$ModuleName" -Force
Publish-Module -Path "$PSScriptRoot\$ModuleName" -LicenseUri $LicenseUri -ProjectUri $ProjectUri -Tags $Tags -NuGetApiKey $ApiKey