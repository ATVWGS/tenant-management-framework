Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName
)

Describe 'General.Module.Tests' {
    It 'the module imports successfully' {
        { Import-Module -Name "$ModuleRoot\$ModuleName.psd1" -ErrorAction Stop } | Should -Not -Throw
    }

    It 'the module has an associated manifest' {
        Test-Path "$ModuleRoot\$ModuleName.psm1" | Should -Be $true
    }

    It 'passes all default PSScriptAnalyzer rules' {
        Invoke-ScriptAnalyzer -Path "$ModuleRoot\$ModuleName.psm1" | Should -BeNullOrEmpty
    }
}