Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName,
    [Parameter(Mandatory = $true)]
    [string] $AccessToken
)

#region Some test resource definitions
$timestamp = Get-Date -UFormat "%Y%m%d"
$global:graphUri = "https://graph.microsoft.com/beta/groups"
$global:definitions = @{
    groups = @(
        @{
            "displayName" = "Test - $timestamp - Group for conditionalAccessPolicies"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "mailNickname" = "testGroupForConditionalAccessPolicies"
            "present" = $true
        }
        @{
            "displayName" = "Test - $timestamp - Group for conditionalAccessPolicies 2"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "mailNickname" = "testGroupForConditionalAccessPolicies2"
            "present" = $true
        }
    )
}
#endregion

Describe 'Tmf.Groups.Register' {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken $AccessToken

    It "should successfully register group definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Register-TmfGroup @group
        }
        Get-TmfDesiredConfiguration | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.Groups.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfGroup } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfTenant -DoNotRequireTenantConfirm } | Should -Not -Throw
    }

    
    $testCases = $global:definitions["groups"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUris[$type.Name]
        }
    }
    It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$global:graphUri/?`$filter=displayName eq '$displayName'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
    }
}

Describe 'Tmf.General.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        $global:definitions["groups"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }

    It "should successfully register group definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Register-TmfGroup @group
        }
        Get-TmfDesiredConfiguration | Should -Not -BeNullOrEmpty        
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfGroup } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfGroup } | Should -Not -Throw
    }

    $testCases = $global:definitions["groups"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUris[$type.Name]
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$global:graphUri/?`$filter=displayName eq '$displayName'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}