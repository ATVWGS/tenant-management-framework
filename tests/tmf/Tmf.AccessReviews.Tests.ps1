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
$global:graphUri = "https://graph.microsoft.com/beta/identityGovernance/accessReviews/definitions"
$global:definitions = Get-Definitions -DataFilePath "$PSScriptRoot\definitions\AccessReview.Definitions.psd1"
#endregion

BeforeAll {
    Import-Module "$ModuleRoot\$ModuleName.psd1" -Force
    Connect-MgGraph -AccessToken ($AccessToken | ConvertTo-SecureString -AsPlainText -Force)
}

Describe 'Tmf.AccessReview.Groups.Register' {
    It "should successfully register groups definitions" {
        foreach ($group in $global:definitions["groups"]) {
            Write-Host ($group | ConvertTo-Json -Depth 10)
            { Register-TmfGroup @group -Verbose } | Should -Not -Throw
        }
        Get-TmfDesiredConfiguration | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.AccessReview.Groups.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfGroup -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfGroup -Verbose } | Should -Not -Throw
    }
}

#Let's wait until groups can be queried after creation
Start-Sleep 10

Describe 'Tmf.AccessReview.Register' {
    It "should successfully register access review definitions" {
        foreach ($accessReview in $global:definitions["accessReviews"]) {
            Write-Host ($accessReview | ConvertTo-Json -Depth 10)
            { Register-TmfAccessReview @accessReview -Verbose } | Should -Not -Throw
        }
        Get-TmfDesiredConfiguration | Should -Not -BeNullOrEmpty        
    }
}

Describe 'Tmf.AccessReview.Invoke.Creation' {
    It "should successfully test the TMF configuration" {
        { Test-TmfAccessReview -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfAccessReview -Verbose } | Should -Not -Throw
    }

    
    $testCases = $global:definitions["accessReviews"] | Foreach-Object {
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

Describe 'Tmf.AccessReview.Invoke.Deletion' {
    BeforeAll {
        #region Set present to false for each definition
        $global:definitions["accessReviews"] | Foreach-Object {
            $_["present"] = $false
        }
        #endregion
    }

    It "should successfully register access review definitions" {
        foreach ($accessReview in $global:definitions["accessReviews"]) {
            Register-TmfAccessReview @accessReview -Verbose
        }
        Get-TmfDesiredConfiguration -Verbose | Should -Not -BeNullOrEmpty        
    }

    It "should successfully test the TMF configuration" {
        { Test-TmfAccessReview -Verbose } | Should -Not -Throw
    }

    It "should successfully invoke the TMF configuration" {
        { Invoke-TmfAccessReview -Verbose } | Should -Not -Throw
    }

    $testCases = $global:definitions["accessReviews"] | Foreach-Object {
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

Describe 'Tmf.AccessReview.Groups.Invoke.Deletion' {
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