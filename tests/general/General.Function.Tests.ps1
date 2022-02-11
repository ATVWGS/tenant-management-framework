Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName
)

$globalIgnoredAnalyzerRules = @(
    "PSAvoidTrailingWhitespace",
    "PSReviewUnusedParameter",
    "PSUseApprovedVerbs"
)

Describe 'General.Function.Tests' {    
    $testCases = @()    
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object {$_.RuleName -notin $globalIgnoredAnalyzerRules}

    Get-ChildItem -Path $ModuleRoot -Filter "*.ps1" -Recurse | Foreach-Object {
        $testCases += @{"fileName" = $_.Name; "filePath" = $_.FullName}
    }
            
    foreach ($case in $testCases) {        
        foreach ($rule in $scriptAnalyzerRules) {
            It "$($case.fileName).$($rule.ruleName)" -Tag "General", $($case.fileName), $case.ruleName, "PSScriptAnalyzer" -TestCases @{
                fileName = $case.filePath
                ruleName = $rule.ruleName
            } {
                $results = Invoke-ScriptAnalyzer -Path $fileName -IncludeRule $ruleName -Recurse
                foreach ($result in $results) {
                    switch ($result.Severity) {
                        "Information" {
                            Set-ItResult -Skipped -Because "serverity is Information. Violation in $($result.ScriptName) at line $($result.Line) with message: `"$($result.Message)`""
                        }
                        default {
                            "problem in $($result.ScriptName) at line $($result.Line) with message: `"$($result.Message)`"" | Should -BeNullOrEmpty
                        }
                    }
                }

                $results | Where-Object {$_.Severity -ne "Information"} | Foreach-Object {
                    "problem in $($_.ScriptName) at line $($_.Line) with message: `"$($_.Message)`""
                } | Should -BeNullOrEmpty
            }
        }        
    }    
}