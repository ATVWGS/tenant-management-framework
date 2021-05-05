Describe 'General.Function.Tests' {
    $moduleRoot = Resolve-Path "$PSScriptRoot\..\TMF\"        
    $functionFiles = Get-ChildItem -Path $moduleRoot -Filter "*.ps1" -Recurse

    foreach ($file in $functionFiles) {
        Context "$($file.Name)" {
            It "Passes all default PSScriptAnalyzer rules" {                
                $result = Invoke-ScriptAnalyzer -Path $($file.FullName) -ExcludeRule PSAvoidTrailingWhitespace
                $result.Severity | Should -Not -Be "Warning"
            }
        }        
    }    
}