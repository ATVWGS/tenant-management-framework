Param (
    [string] $ArtifactPath,
    [string] $ModuleName = $env:moduleName,
    [string] $ApiKey = $env:apiKey
)

begin {
    $package = Get-ChildItem -Filter "*.zip" -Path $ArtifactPath -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1    
    Expand-Archive -Path $package.FullName -DestinationPath "$PSScriptRoot\$ModuleName" -Force
    $manifest = Import-LocalizedData -BaseDirectory "$PSScriptRoot\$ModuleName" -FileName "$ModuleName.psd1"

    #region Install dependencies
    foreach ($module in $manifest.RequiredModules) {
        switch ($module.GetType().Name) {
            "String" { Install-Module -Name $module -Scope CurrentUser -Force -Repository PSGallery }
            "Hashtable" { Install-Module -Name $module["ModuleName"] -RequiredVersion $module["RequiredVersion"] -Scope CurrentUser -Force -Repository PSGallery }
        }
    }
    #endregion
}
process {
    Publish-Module -Path "$PSScriptRoot\$ModuleName" -NuGetApiKey $ApiKey
}