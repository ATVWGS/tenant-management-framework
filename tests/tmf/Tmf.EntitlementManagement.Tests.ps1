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
$global:testAPconfigPath = "$env:TMP\test-ap-config"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\EntitlementManagement.Definitions.psd1"
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)

    New-TmfConfiguration -OutPath $global:testAPconfigPath -DoNotAutoActivate -Name "test-ap-config" -Author "Pester Tester" -Weight 0 -Force

    $global:definitions.GetEnumerator() | Foreach-Object {
        if ($_.Name -in ("accessPackages","accessPackageCatalogs")) {
            $targetFilePath = Get-ChildItem -Path "$global:testAPconfigPath\entitlementManagement\$($_.Name)" -Depth 0 -Filter "*.json" | Select-Object -First 1 -ExpandProperty FullName
        }
        else {
            $targetFilePath = Get-ChildItem -Path "$global:testAPconfigPath\$($_.Name)" -Depth 0 -Filter "*.json" | Select-Object -First 1 -ExpandProperty FullName
        }
        $_.Value | ConvertTo-Json -Depth 10 | Out-File -FilePath $targetFilePath -Encoding utf8
    }
}

Describe 'Tmf.Activate.Configuration' {
    It "should successfully activate TMF configuration" {
        { Activate-TmfConfiguration -ConfigurationPaths $global:testAPconfigPath -Force } | Should -Not -Throw
    }
    It "should have activated TMF configuration" {
        { Get-TmfDesiredConfiguration } | Should -Not -BeNullOrEmpty
    }
}    

Describe 'Tmf.EntitlementManagement.Groups.Invoke.Creation' {
    It "should successfully test the TMF group configuration" {
        { Test-TmfGroup -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF group configuration" {
        { Invoke-TmfGroup -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.EntitlementManagement.AccessPackageCatalogs.Invoke.Creation' {

    It "should successfully invoke the Access Package Catalog configuration" {
        { Invoke-TmfAccessPackageCatalog -Verbose } | Should -Not -Throw
    }

}

Describe 'Tmf.EntitlementManagement.Test.Configuration' {
    It "should successfully test the TMF configuration" {
        { Test-TmfEntitlementManagement -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.EntitlementManagement.Invoke.Creation' {

    BeforeAll {
        Start-Sleep 10
    }

    It "should successfully invoke the EntitlementManagement configuration" {
        { Invoke-TmfEntitlementManagement -DoNotRequireTenantConfirm -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.EntitlementManagement.Validate.Creation' {

    BeforeAll {
        #Let's wait until resources can be queried after creation
        Start-Sleep 10
    }    
    
    $testCases = $global:definitions["accessPackageCatalogs"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$($uri)/accessPackageCatalogs?`$filter=displayName eq '$($displayname)'"
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
        $uri = "$($uri)/accessPackages?`$filter=displayName eq '$($displayname)'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
    }
}

Describe 'Tmf.EntitlementManagement.AccessPackages.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        (Get-TmfDesiredConfiguration).accessPackages | Foreach-Object {
            $_.present = $false
        }
        #endregion
    }

    #First remove accessPackages
    It "should successfully test the accessPackages configuration" {
        { Test-TmfAccessPackage -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the accessPackages configuration" {
        { Invoke-TmfAccessPackage -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.EntitlementManagement.AccessPackageCatalogs.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        (Get-TmfDesiredConfiguration).accessPackageCatalogs | Foreach-Object {
            $_.present = $false
        }
        #endregion
    }
    #Second remove accessPackageCatalogs
    It "should successfully test the accessPackageCatalogs configuration" {
        { Test-TmfAccessPackageCatalog -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the accessPackageCatalogs configuration" {
        { Invoke-TmfAccessPackageCatalog -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.EntitlementManagement.AccessPackages.Validate.Deletion' {
    $testCases = $global:definitions["accessPackages"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$($uri)/accessPackages?`$filter=displayName eq '$($displayname)'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}

Describe 'Tmf.EntitlementManagement.AccessPackageCatalogs.Validate.Deletion' {
    $testCases = $global:definitions["accessPackageCatalogs"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = $global:graphUri
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$($uri)/accessPackageCatalogs?`$filter=displayName eq '$($displayname)'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}

Describe 'Tmf.EntitlementManagement.Groups.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        (Get-TmfDesiredConfiguration).groups | Foreach-Object {
            $_.present = $false
        }
        #endregion
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfGroup -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfGroup -Verbose } | Should -Not -Throw
    }
}

Describe 'Tmf.EntitlementManagement.Groups.Validate.Deletion' {
    $testCases = $global:definitions["groups"] | Foreach-Object {
        return @{
            "displayName" = $_["displayName"]
            "uri" = "https://graph.microsoft.com/beta/groups"
        }
    }
    It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
        Param ($displayName, $uri)
        $uri = "$($uri)?`$filter=displayName eq '$($displayName)'"
        (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 1
    }
}

AfterAll {
   # Remove-Item -Path $global:testAPconfigPath -Recurse -Force
}