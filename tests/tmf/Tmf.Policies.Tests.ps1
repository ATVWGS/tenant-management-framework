Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName,
    [Parameter(Mandatory = $true)]
    [string] $AccessToken
)

Import-Module "$PSScriptRoot\..\helpers.psm1"

#region Some test resource definitions
$global:graphUri = "https://graph.microsoft.com/beta/policies"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\Policy.Definitions.psd1"
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)
}

Describe 'Tmf.Policies.authenticationStrengthPolicies.Register' {
    It "should successfully register authenticationStrengthPolicy definitions" {
        foreach ($authenticationStrengthPolicy in $global:definitions["authenticationStrengthPolicies"]) {
            Write-Host ($authenticationStrengthPolicy | ConvertTo-Json -Depth 10)
            { Register-TmfAuthenticationStrengthPolicy @authenticationStrengthPolicy -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).authenticationStrengthPolicies | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.Policies.AuthenticationStrengthPolicies.Invoke.Creation' {

    It "should successfully test the TMF configuration" {
        { Test-TmfAuthenticationStrengthPolicy -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfAuthenticationStrengthPolicy -Verbose } | Should -Not -Throw
    }
}


Describe 'Tmf.Policies.AuthenticationStrengthPolicies.Validate.Creation' {

    BeforeAll {
        Start-Sleep 5
    }
    
    $testCases = $global:definitions["authenticationStrengthPolicies"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/authenticationStrengthPolicies?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
    }
}

Describe 'Tmf.Policies.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        $global:definitions["authenticationStrengthPolicies"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }
    
    It "should successfully register authenticationStrengthPolicy definitions" {
        foreach ($authenticationStrengthPolicy in $global:definitions["authenticationStrengthPolicies"]) {
            Register-TmfAuthenticationStrengthPolicy @authenticationStrengthPolicy -Verbose
        }
        (Get-TmfDesiredConfiguration).authenticationStrengthPolicies | Should -Not -BeNullOrEmpty        
    }

    #Remove policies
    It "should successfully test the authenticationStrengthPolicy definitions" {
        { Test-TmfAuthenticationStrengthPolicy -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the authenticationStrengthPolicy definitions" {
        { Invoke-TmfAuthenticationStrengthPolicy -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.Policies.AuthenticationStrengthPolicies.Validate.Deletion' {
    BeforeAll {
        Start-Sleep 5
    }
    $testCases = $global:definitions["authenticationStrengthPolicies"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/authenticationStrengthPolicies?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}