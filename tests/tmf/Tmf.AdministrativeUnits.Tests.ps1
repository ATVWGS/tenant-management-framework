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
$global:graphUri = "https://graph.microsoft.com/beta/administrativeUnits"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\AdministrativeUnit.Definitions.psd1"
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)
}

Describe 'Tmf.AdministrativeUnits.Register' {
    It "should successfully register administrativeUnit definitions" {
        foreach ($AU in $global:definitions["administrativeUnits"]) {
            Write-Host ($AU | ConvertTo-Json -Depth 10)
            { Register-TmfAdministrativeUnit @AU -Verbose } | Should -Not -Throw
        }
        Get-TmfDesiredConfiguration | Should -Not -BeNullOrEmpty        
    }

    $testCases = @(
        @{
            "because" = "membershipRule requires membershipType dynamic"
            "definition" = @{
                "displayName" = "Dynamic AU"
                "membershipRule" = "does not matter"
            }
        }
        @{
            "because" = "members requires membershipType assigned"
            "definition" = @{
                "displayName" = "Security Group"
                "membershipType" = "dynamic"
                "members" = @("does not matter")
            }
        }
    )
    It "should throw an exception" -TestCases $testCases {
        Param ($because, $definition)
        { Register-TmfAdministrativeUnit @definition -Verbose } | Should -Throw -Because $because
    }
}

Describe 'Tmf.AdministrativeUnit.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfAdministrativeUnit -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfTenant -DoNotRequireTenantConfirm -Verbose } | Should -Not -Throw
    }

    
    $testCases = $global:definitions["administrativeUnits"] | Foreach-Object {
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
        $global:definitions["administrativeUnits"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }

    It "should successfully register administrativeUnit definitions" {
        foreach ($AU in $global:definitions["administrativeUnits"]) {
            Register-TmfAdministrativeUnit @AU -Verbose
        }
        Get-TmfDesiredConfiguration -Verbose | Should -Not -BeNullOrEmpty        
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfAdministrativeUnit -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfAdministrativeUnit -Verbose } | Should -Not -Throw
    }

    $testCases = $global:definitions["administrativeUnits"] | Foreach-Object {
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