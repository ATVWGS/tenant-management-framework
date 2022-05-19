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
$global:graphUri = "https://graph.microsoft.com/beta/groups"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\Group.Definitions.psd1"
$global:definitions["groups"] | Foreach-Object { $_["mailNickname"] = $_["displayName"].replace(" ","").replace("-","") }
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken $AccessToken
}

Describe 'Tmf.Groups.Register' {
    It "should successfully register group definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Write-Host ($group | ConvertTo-Json)
            { Register-TmfGroup @group } | Should -Not -Throw
        }
        Get-TmfDesiredConfiguration | Should -Not -BeNullOrEmpty        
    }

    $testCases = @(
        @{
            "because" = "membershipRule requires groupType DynamicMembership"
            "definition" = @{
                "displayName" = "Security Group"
                "groupTypes" = @()
                "membershipRule" = "does not matter"
            }
        }
        @{
            "because" = "membershipRule requires groupType DynamicMembership"
            "definition" = @{
                "displayName" = "Security Group"
                "groupTypes" = @()
                "resourceBehaviorOptions" = @("WelcomeEmailDisabled")
            }
        }
    )
    It "should throw an exception" -TestCases $testCases {
        Param ($because, $definition)
        { Register-TmfGroup @definition } | Should -Throw -Because $because
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
            "uri" = $global:graphUri
        }
    }
    It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/?`$filter=displayName eq '$displayName'"
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
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/?`$filter=displayName eq '$displayName'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}