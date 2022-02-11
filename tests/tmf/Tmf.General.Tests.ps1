Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName,
    [Parameter(Mandatory = $true)]
    [string] $AccessToken
)

Describe 'Tmf.General.Functions.Tests' {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken $AccessToken

    It "should successfully activate TMF configuration" {
        { Activate-TmfConfiguration -ConfigurationPaths "$PScriptRoot\..\test-config" } | Should -Not -Throw
    }    
}