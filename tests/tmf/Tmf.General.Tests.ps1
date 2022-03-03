Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName,
    [Parameter(Mandatory = $true)]
    [string] $AccessToken
)

if ($PSVersionTable.OS -match "Microsoft Windows") {
    $global:testConfigPath = "$PSScriptRoot\test-config"
}
else {
    $global:testConfigPath = "/tmp/test-config"
}

#region Some test resource definitions
$timestamp = Get-Date -UFormat "%Y%m%d"
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
    namedLocations = @(
        @{
            "type" = "ipNamedLocation"
            "displayName" = "Test - $timestamp - Trusted Named Location"
            "isTrusted" = $true
            "ipRanges" = @(
                @{
                    "@odata.type" = "#microsoft.graph.iPv4CidrRange"
                    "cidrAddress" = "12.34.221.11/22"
                },
                @{
                    "@odata.type" = "#microsoft.graph.iPv4CidrRange"
                    "cidrAddress" = "12.34.221.12/22"
                }
            )
        }
    )
}
#endregion

Describe 'Tmf.General.Config.Creation' {
    It "should successfully create new TMF configuration" {
        { New-TmfConfiguration -OutPath $global:testConfigPath -DoNotAutoActivate -Name "test-config" -Author "Pester Tester" -Weight 0 -Force } | Should -Not -Throw

        "$global:testConfigPath\configuration.json" | Should -Exist
        foreach ($folder in (Get-ChildItem -Path "$ModuleRoot\internal\data\configuration\" -Depth 0 -Directory)) {
            "$global:testConfigPath\$($folder.Name)" | Should -Exist
        }
    }
}

Describe 'Tmf.General.Config.Processing' {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken $AccessToken

    BeforeAll {
        $global:definitions.GetEnumerator() | Foreach-Object {
            $targetFilePath = Get-ChildItem -Path "$global:testConfigPath\$($_.Name)" -Depth 0 -Filter "*.json" | Select-Object -First 1 -ExpandProperty FullName
            $_.Value | ConvertTo-Json -Depth 10 | Out-File -FilePath $targetFilePath -Encoding utf8
        }
    }

    It "should successfully activate TMF configuration" {
        { Activate-TmfConfiguration -ConfigurationPaths $global:testConfigPath } | Should -Not -Throw
        Get-TmfActiveConfiguration | Should -Not -BeNullOrEmpty
        Get-TmfDesiredConfiguration | Should -Not -BeNullOrEmpty
        
        Get-ChildItem $global:testConfigPath -Exclude "configuration.json" -Filter "*.json" -Recurse 
        | Where-Object {$_.Length -gt 2} | Split-Path -Parent | Foreach-Object {
            (Get-TmfDesiredConfiguration).Keys | Should -Contain $_.split("\")[-1]
        }
    }
}

Describe 'Tmf.General.Invoke.Creation' {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\helpers.psm1" -Force
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfTenant } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfTenant -DoNotRequireTenantConfirm } | Should -Not -Throw
    }

    foreach ($type in $global:definitions.GetEnumerator()) {
        $global:testCases = $type.Value | Foreach-Object {
            return @{
                "displayName" = $_["displayName"]
                "uri" = $graphUris[$type.Name]
            }
        }
        It "should have created <displayName> (uri: <uri>)" -TestCases $testCases {
            Param ($displayName, $uri)
            $uri = "$uri/?`$filter=displayName eq '$displayName'"
            (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value | Should -Not -HaveCount 0
        }
    }
}

Describe 'Tmf.General.Invoke.Deletion' {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\helpers.psm1" -Force
        
        #region Set present to false for each definition
        $global:definitions.GetEnumerator() | Foreach-Object {
            $_.Value | Foreach-Object { $_["present"] = $false }
            $targetFilePath = Get-ChildItem -Path "$global:testConfigPath\$($_.Name)" -Depth 0 -Filter "*.json" | Select-Object -First 1 -ExpandProperty FullName
            $_.Value | ConvertTo-Json -Depth 10 | Out-File -FilePath $targetFilePath -Encoding utf8
        }
        #endregion
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfTenant } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfTenant -DoNotRequireTenantConfirm } | Should -Not -Throw
    }

    foreach ($type in $global:definitions.GetEnumerator()) {
        $global:testCases = $type.Value | Foreach-Object {
            return @{
                "displayName" = $_["displayName"]
                "uri" = $graphUris[$type.Name]
                "type" = $type.Name
            }
        }
        It "should have deleted <displayName> (uri: <uri>)" -TestCases $testCases {
            Param ($displayName, $uri, $type)
            $uri = "$uri/?`$filter=displayName eq '$displayName'"
            if ($type -eq "namedLocations") {
                Start-Sleep -Seconds 10
            }

            $result = (Invoke-MgGraphRequest -Method GET -Uri $uri -Verbose).Value

            if ($type -eq "namedLocations" -and $result.Count -gt 0) {
                Set-ItResult -Skipped -Because "the namedLocations Microsoft Graph endpoint is very slow."
            }
            
            $result | Should -HaveCount 0
        }
    }
}

Describe 'Tmf.General.Config.Cleanup' {
    It "should successfully deactivate TMF configuration" {
        { Deactivate-TmfConfiguration -All } | Should -Not -Throw
        Get-TmfActiveConfiguration | Should -BeNullOrEmpty
        Get-TmfDesiredConfiguration | Should -BeNullOrEmpty
    }
}

AfterAll {
    #Remove-Item -Path $global:testConfigPath -Recurse -Force
}