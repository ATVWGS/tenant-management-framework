Param (
    [string] $ModuleName = "TMF",
    [Parameter(Mandatory = $true, ParameterSetName = "TestArtifact")]
    [string] $ArtifactPath,
    [Parameter(Mandatory = $false, ParameterSetName = "Default")]
    [string] $ModuleRoot = "$PSScriptRoot/../TMF",
    [string] $OutPath = "$PSScriptRoot/results",
    
    [string] $TenantName,
    [string] $TenantId,
    [string] $TenantClientSecret,
    [string] $TenantClientId,

    [switch] $SkipDependencyDownload
)

begin {
    if ($PSBoundParameters.ContainsKey("ArtifactPath")) {
        $ModuleRoot = "$env:TEMP\$ModuleName"
        $package = Get-ChildItem -Filter "*.zip" -Path $ArtifactPath -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1    
        Expand-Archive -Path $package.FullName -DestinationPath $ModuleRoot -Force
    }

    #region Install dependencies
    $manifest = Import-LocalizedData -BaseDirectory $ModuleRoot -FileName "$ModuleName.psd1"
    if (-Not $SkipDependencyDownload) {
        foreach ($module in $manifest.RequiredModules) {
            switch ($module.GetType().Name) {
                "String" { Install-Module -Name $module -Scope CurrentUser -Force -Repository PSGallery }
                "Hashtable" { Install-Module -Name $module["ModuleName"] -RequiredVersion $module["RequiredVersion"] -Scope CurrentUser -Force -Repository PSGallery }
            }
        }
    }    
    Install-Module -Name Pester -Force -SkipPublisherCheck -RequiredVersion "5.3.1"
    #endregion
   
}
process {
    Import-Module Pester

    #region General module tests
    $testData = @{
        ModuleName = $ModuleName
        ModuleRoot = $ModuleRoot
    }

    Get-ChildItem "$PSScriptRoot\general\" -Filter "*.ps1" | Foreach-Object {
        $testContainer = New-PesterContainer -Path $_.FullName -Data $testData
        $testConfig = New-PesterConfiguration -Hashtable @{
            Run = @{
                Container = $testContainer
                PassThru = $true
            }
            TestResult = @{
                OutputPath = "$OutPath\$($_.BaseName).Test-Result.xml"
                OutputFormat = "NUnitXML"
            }
        }
        Invoke-Pester -Configuration $testConfig
    }
    #endregion   
}