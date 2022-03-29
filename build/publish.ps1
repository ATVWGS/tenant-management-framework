Param (
    [string] $ArtifactPath,
    [string] $ModuleName = $env:moduleName,
    [string] $ApiKey = $env:apiKey
)

begin {
    $package = Get-ChildItem -Filter "*.zip" -Path $ArtifactPath -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1    
    Expand-Archive -Path $package.FullName -DestinationPath "$PSScriptRoot\$ModuleName" -Force
}
process {
    Publish-Module -Path "$PSScriptRoot\$ModuleName" -NuGetApiKey $ApiKey
}