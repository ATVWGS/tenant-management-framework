Describe 'General.Module.Tests' {
    BeforeAll {
        $moduleRoot = Resolve-Path "$PSScriptRoot\..\TMF\"
    }
    It 'the module imports successfully' {
        { Import-Module -Name "$moduleRoot\TMF.psd1" -ErrorAction Stop } | Should -Not -Throw
    }

    It 'the module has an associated manifest' {
        Test-Path "$moduleRoot\TMF.psm1" | Should -Be $true
    }

    It 'passes all default PSScriptAnalyzer rules' {
        Invoke-ScriptAnalyzer -Path "$moduleRoot\TMF.psm1" | Should -BeNullOrEmpty
    }
}