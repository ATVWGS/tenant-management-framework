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
$global:graphUri = "https://graph.microsoft.com/beta/roleManagement"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\RoleManagement.Definitions.psd1"
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)
}

Describe 'Tmf.RoleManagement.Groups.Register' {
    It "should successfully register groups definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Write-Host ($group | ConvertTo-Json -Depth 10)
            { Register-TmfGroup @group -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).groups | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.RoleManagement.Groups.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfGroup -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfGroup -Verbose } | Should -Not -Throw
    }
}

#Let's wait until groups can be queried after creation
Start-Sleep 10

Describe 'Tmf.RoleManagement.RoleDefinitions.Register' {
    It "should successfully register roleDefinition definitions" {
        foreach ($roleDefinition in $global:definitions["roleDefinitions"]) {
            Write-Host ($roleDefinition | ConvertTo-Json -Depth 10)
            { Register-TmfRoleDefinition @roleDefinition -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).roleDefinitions | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.RoleManagement.RoleManagementPolicyRuleTemplates.Register' {
    It "should successfully register roleManagementPolicyRuleTemplates definitions" {
        foreach ($ruleTemplate in $global:definitions["roleManagementPolicyRuleTemplates"]) {
            Write-Host ($ruleTemplate | ConvertTo-Json -Depth 10)
            { Register-TmfRoleManagementPolicyRuleTemplate @ruleTemplate -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).roleManagementPolicyRuleTemplates | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.RoleManagement.RoleManagementPolicies.Register' {
    It "should successfully register roleManagementPolicies definitions" {
        foreach ($policy in $global:definitions["roleManagementPolicies"]) {
            Write-Host ($policy | ConvertTo-Json -Depth 10)
            { Register-TmfRoleManagementPolicy @policy -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).roleManagementPolicies | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.RoleManagement.RoleAssignments.Register' {
    It "should successfully register roleAssignments definitions" {
        foreach ($assignment in $global:definitions["roleAssignments"]) {
            Write-Host ($assignment | ConvertTo-Json -Depth 10)
            { Register-TmfRoleAssignment @assignment -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).roleAssignments | Should -Not -BeNullOrEmpty        
    }
}


Describe 'Tmf.RoleManagement.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfRoleManagement -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfRoleManagement -DoNotRequireTenantConfirm -Verbose } | Should -Not -Throw
    }

    $testCases = $global:definitions["roleDefinitions"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/directory/roleDefinitions?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
    }
}

Describe 'Tmf.RoleManagement.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        $global:definitions["roleAssignments"] | Foreach-Object {
            $_["present"] = $false
        }
        $global:definitions["roleDefinitions"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }

    It "should successfully register roleDefinition definitions" {
        foreach ($roleDefinition in $global:definitions["roleDefinitions"]) {
            Register-TmfRoleDefinition @roleDefinition -Verbose
        }
        (Get-TmfDesiredConfiguration).roleDefinitions | Should -Not -BeNullOrEmpty        
    }
    
    It "should successfully register roleAssignments definitions" {
        foreach ($assignment in $global:definitions["roleAssignments"]) {
            Register-TmfRoleAssignment @assignment -Verbose
        }
        (Get-TmfDesiredConfiguration).roleAssignments | Should -Not -BeNullOrEmpty        
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfRoleManagement -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfRoleManagement -DoNotRequireTenantConfirm -Verbose } | Should -Not -Throw
    }

    $testCases = $global:definitions["roleDefinitions"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/directory/roleDefinitions?`$filter=displayName eq '$displayname'"
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
        $uri = "$uri/?`$filter=displayName eq '$displayName'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}