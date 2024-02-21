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
$global:graphUri = "https://graph.microsoft.com/beta/identityGovernance/entitlementManagement"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\EntitlementManagement.Definitions.psd1"
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)
}

Describe 'Tmf.EntitlementManagement.Groups.Register' {
    It "should successfully register groups definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Write-Host ($group | ConvertTo-Json -Depth 10)
            { Register-TmfGroup @group -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).groups | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.EntitlementManagement.Groups.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfGroup -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfGroup -Verbose } | Should -Not -Throw
    }
}

#Let's wait until groups can be queried after creation
Start-Sleep 10

Describe 'Tmf.EntitlementManagement.AccessPackageCatalogs.Register' {
    It "should successfully register AccessPackageCatalogs definitions" {
        foreach ($accessPackageCatalog in $global:definitions["accessPackageCatalogs"]) {
            Write-Host ($accessPackageCatalog | ConvertTo-Json -Depth 10)
            { Register-TmfAccessPackageCatalog @accessPackageCatalog -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).accessPackageCatalogs | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.EntitlementManagement.AccessPackage.Register' {
    It "should successfully register accessPackages definitions" {
        foreach ($accessPackage in $global:definitions["accessPackages"]) {
            Write-Host ($accessPackage | ConvertTo-Json -Depth 10)
            { Register-TmfAccessPackage @accessPackage  -Verbose } | Should -Not -Throw
        }
        (Get-TmfDesiredConfiguration).accessPackages | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.EntitlementManagement.Invoke.Creation' {

    It "should successfully test the TMF configuration" {
        { Test-TmfEntitlementManagement -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfEntitlementManagement -DoNotRequireTenantConfirm -Verbose } | Should -Not -Throw
    }

    #Let's wait until resources can be queried after creation
    Start-Sleep 10
    
    $testCases = $global:definitions["accessPackageCatalogs"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/accessPackageCatalogs?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
    }

    $testCases = $global:definitions["accessPackages"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/accessPackages?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
    }
}

#Let's wait until resources can be queried after creation
Start-Sleep 10

Describe 'Tmf.EntitlementManagement.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        $global:definitions["accessPackageAssignmentPolicies"] | Foreach-Object {
            $_["present"] = $false
        }
        $global:definitions["accessPackageCatalogs"] | Foreach-Object {
            $_["present"] = $false
        }
        $global:definitions["accessPackages"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }

    It "should successfully register accessPackages definitions" {
        foreach ($accessPackage in $global:definitions["accessPackages"]) {
            Register-TmfAccessPackage @accessPackage -Verbose
        }
        (Get-TmfDesiredConfiguration).accessPackages | Should -Not -BeNullOrEmpty        
    }
    
    It "should successfully register accessPackageCatalogs definitions" {
        foreach ($accessPackageCatalog in $global:definitions["accessPackageCatalogs"]) {
            Register-TmfAccessPackageCatalog @accessPackageCatalog -Verbose
        }
        (Get-TmfDesiredConfiguration).accessPackageCatalogs | Should -Not -BeNullOrEmpty        
    }

    #First remove accessPackages
    It "should successfully test the accessPackages configuration" {
        { Test-TmfAccessPackage -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the accessPackages configuration" {
        { Invoke-TmfAccessPackage -Verbose } | Should -Not -Throw
    }

    #Second remove accessPackageCatalogs
    It "should successfully test the accessPackageCatalogs configuration" {
        { Test-TmfAccessPackageCatalog -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the accessPackageCatalogs configuration" {
        { Invoke-TmfAccessPackageCatalog -Verbose } | Should -Not -Throw
    }

    $testCases = $global:definitions["accessPackages"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$uri/accessPackages?`$filter=displayName eq '$displayname'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}

Describe 'Tmf.EntitlementManagement.Groups.Invoke.Deletion' {
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