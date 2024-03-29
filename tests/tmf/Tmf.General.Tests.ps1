Param (
    [Parameter(Mandatory = $true)]
    [string] $ModuleRoot,
    [Parameter(Mandatory = $true)]
    [string] $ModuleName,
    [Parameter(Mandatory = $true)]
    [string] $AccessToken
)

Import-Module "$PSScriptRoot\..\helpers.psm1"

if ($PSVersionTable.OS -match "Microsoft Windows") {
    $global:testConfigPath = "$env:TMP\test-config"
}
else {
    $global:testConfigPath = "$PWD/test-config"
}

#region Some test resource definitions
$global:graphUris = @{
    "groups" = "https://graph.microsoft.com/beta/groups"
    "namedLocations" = "https://graph.microsoft.com/beta/identity/conditionalAccess/namedLocations"
}
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\General.Definitions.psd1"
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
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)

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
        
        Get-ChildItem $global:testConfigPath -Exclude "configuration.json" -Filter "*.json" -Recurse `
        | Where-Object {$_.Length -gt 2} | Split-Path -Parent | Foreach-Object {
                (Get-TmfDesiredConfiguration).Keys | Should -Contain $_.split("\")[-1]
        }
    }
}

Describe 'Tmf.General.Invoke.Creation' {
    BeforeEach {
        Start-Sleep -Seconds 10 # Ensure Graph has enough time to process our requests
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfTenant } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfTenant -DoNotRequireTenantConfirm } | Should -Not -Throw
    }

    foreach ($type in $global:definitions.GetEnumerator()) {
        $testCases = $type.Value | Foreach-Object {
            return @{
                "displayName" = $_["displayName"]
                "uri" = $global:graphUris[$type.Name]
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
        #region Set present to false for each definition
        $global:definitions.GetEnumerator() | Foreach-Object {
            $_.Value | Foreach-Object { $_["present"] = $false }
            $targetFilePath = Get-ChildItem -Path "$global:testConfigPath\$($_.Name)" -Depth 0 -Filter "*.json" | Select-Object -First 1 -ExpandProperty FullName
            $_.Value | ConvertTo-Json -Depth 10 | Out-File -FilePath $targetFilePath -Encoding utf8 -Force
        }
        #endregion

        Start-Sleep -Seconds 10 # Give Microsoft Graph some time to process our requests
    }

    It "should successfully reload the TMF configuration" {
        { Load-TmfConfiguration -ReturnDesiredConfiguration | ConvertTo-Json -Depth 10 } | Should -Not -Throw
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfTenant } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfTenant -DoNotRequireTenantConfirm } | Should -Not -Throw
    }

    foreach ($type in $global:definitions.GetEnumerator()) {
        $testCases = $type.Value | Foreach-Object {
            return @{
                "displayName" = $_["displayName"]
                "uri" = $global:graphUris[$type.Name]
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
    # Remove-Item -Path $global:testConfigPath -Recurse -Force
}