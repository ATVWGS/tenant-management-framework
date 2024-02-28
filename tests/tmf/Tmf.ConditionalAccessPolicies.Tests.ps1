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
$global:graphUri = "https://graph.microsoft.com/beta/policies/conditionalAccessPolicies"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\ConditionalAccessPolicy.Definitions.psd1"
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)
}

Describe 'Tmf.ConditionalAccessPolicies.Groups.Register' {
    It "should successfully register groups definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Write-Host ($group | ConvertTo-Json -Depth 10)
            { Register-TmfGroup @group -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).groups | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.ConditionalAccessPolicies.Groups.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfGroup -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfGroup -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.ConditionalAccessPolicies.Register' {
    It "should successfully register conditionalAccessPolicy definitions" {
        foreach ($conditionalAccessPolicy in $global:definitions["conditionalAccessPolicies"]) {
            Write-Host ($conditionalAccessPolicy | ConvertTo-Json -Depth 10)
            { Register-TmfConditionalAccessPolicy @conditionalAccessPolicy -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).conditionalAccessPolicies | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.ConditionalAccessPolicies.Invoke.Creation' {

    It "should successfully test the TMF configuration" {
        { Test-TmfConditionalAccessPolicy -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfConditionalAccessPolicy -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.ConditionalAccessPolicies.Validate.Creation' {

    BeforeAll {
        #Let's wait until resources can be queried after creation
        Start-Sleep 10
    }
        
    $testCases = $global:definitions["conditionalAccessPolicies"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$($uri)?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
    }
}

Describe 'Tmf.ConditionalAccessPolicies.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        $global:definitions["conditionalAccessPolicies"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }

    It "should successfully register conditionalAccessPolicy definitions" {
        foreach ($conditionalAccessPolicy in $global:definitions["conditionalAccessPolicies"]) {
            Register-TmfConditionalAccessPolicy @conditionalAccessPolicy -Verbose
        }
        (Get-TmfDesiredConfiguration).conditionalAccessPolicies | Should -Not -BeNullOrEmpty        
    }

    #Remove conditionalAccessPolicies
    It "should successfully test the conditionalAccessPolicy configuration" {
        { Test-TmfConditionalAccessPolicy -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the conditionalAccessPolicy configuration" {
        { Invoke-TmfConditionalAccessPolicy -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.ConditionalAccessPolicies.Validate.Deletion' {

    BeforeAll {
        Start-Sleep 10
    }

    $testCases = $global:definitions["conditionalAccessPolicies"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$($uri)?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}

Describe 'Tmf.RoleManagement.Groups.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        $global:definitions["groups"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }

    It "should successfully register groups definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Register-TmfGroup @group -Verbose
        }
        Get-TmfDesiredConfiguration -Verbose | Should -Not -BeNullOrEmpty        
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfGroup -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfGroup -Verbose } | Should -Not -Throw
    }

    $testCases = $global:definitions["groups"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = "https://graph.microsoft.com/beta/groups"
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$($uri)?`$filter=displayName eq '$displayName'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}