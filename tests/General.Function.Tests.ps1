$testDir = Split-Path $PSCommandPath -Parent
$moduleRoot = Resolve-Path "$testDir\TMF\"

Describe 'General.Function.Tests' {    
    $testCases = @()
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule -Name "PSAvoid*"

    Get-ChildItem -Path $:moduleRoot -Filter "*.ps1" -Recurse | Foreach-Object {
        $testCases += @{"fileName" = $_.Name; "filePath" = $_.FullName}
    }
            
    foreach ($case in $testCases) {        
        foreach ($rule in $scriptAnalyzerRules) {
            It "[$($case.fileName)] Should not return any violation for the rule: $($rule.ruleName)" -TestCases @{
                fileName = $case.filePath
                ruleName = $rule.ruleName
            } {
                Invoke-ScriptAnalyzer -Path $fileName -IncludeRule $ruleName | Should -BeNullOrEmpty
            }
        }        
    }    
}