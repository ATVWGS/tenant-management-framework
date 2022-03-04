Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName
)

$globalIgnoredAnalyzerRules = @(
    "PSAvoidTrailingWhitespace",
    "PSReviewUnusedParameter",
    "PSUseApprovedVerbs",
    "PSUseDeclaredVarsMoreThanAssignments",
    "PSUseShouldProcessForStateChangingFunctions"
)

Describe 'General.Function.Tests' {    
    $testCases = @()    
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object {$_.RuleName -notin $globalIgnoredAnalyzerRules}

    Get-ChildItem -Path $ModuleRoot -Filter "*.ps1" -Recurse | Foreach-Object {
        $testCases += @{"fileName" = $_.Name; "baseName" = $_.BaseName; "filePath" = $_.FullName}
    }
            
    foreach ($case in $testCases) {        
        foreach ($rule in $scriptAnalyzerRules) {
            It "$($case.baseName).$($rule.ruleName)" -Tag "General", $($case.baseName), $case.ruleName, "PSScriptAnalyzer" -TestCases @{
                filePath = $case.filePath
                baseName = $case.baseName
                ruleName = $rule.ruleName
            } {
                # Skip rules based on function type
                $ignoredRules = @()
                switch ($baseName.split("-")) {
                    "Validate" {
                        $ignoredRules += "PSUseSingularNouns"
                    }
                }
                # Skip rules based on function name
                switch ($baseName) {
                    "Assert-TemplateFunctions" {
                        $ignoredRules += "PSUseSingularNouns"
                    }
                }

                if ($ruleName -in ($ignoredRules | Sort-Object -Unique)) { Set-ItResult -Skipped -Because "Ignored rule $ruleName" }

                $results = Invoke-ScriptAnalyzer -Path $filePath -IncludeRule $ruleName -Recurse
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