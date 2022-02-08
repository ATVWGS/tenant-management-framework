Param (
    [string] $ArtifactPath,
    [string] $ModuleName = $env:moduleName,
    [string] $ApiKey = $env:apiKey
)

begin {
    $package = Get-ChildItem -Filter "*.nupkg" -Path $ArtifactPath -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Copy-Item -Path $package.FullName -Destination "$PSScriptRoot\$ModuleName.zip" -Force
    Expand-Archive -Path "$PSScriptRoot\$ModuleName.zip" -DestinationPath "$PSScriptRoot\$ModuleName" -Force
}
process {
    Publish-Module -Path "$PSScriptRoot\$ModuleName" -NuGetApiKey $ApiKey
}