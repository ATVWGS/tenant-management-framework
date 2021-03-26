# All required runtime variables.
$graphVersionRequired = "beta"
$script:graphBaseUrl = "https://graph.microsoft.com/{0}" -f $graphVersionRequired

[regex] $script:guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'
[regex] $script:upnRegex = '^([A-Za-z\d\.]*)@([A-Za-z\d\.-]*)$'
[regex] $script:mailNicknameRegex = '^([A-Za-z\d\.]*)@([A-Za-z\d\.-]*)$'

$script:supportedResources = @{
    "stringMappings" = @{
        "registerFunction" = (Get-Command Register-TmfStringMapping)
        "weight" = 0
    }    
    "groups" = @{
        "registerFunction" = (Get-Command Register-TmfGroup)
        "testFunction" = (Get-Command Test-TmfGroup)
        "invokeFunction" = (Get-Command Invoke-TmfGroup)
        "weight" = 10
    }
    "namedLocations" = @{
        "registerFunction" = (Get-Command Register-TmfNamedLocation)
        "testFunction" = (Get-Command Test-TmfNamedLocation)
        "invokeFunction" = (Get-Command Invoke-TmfNamedLocation)
        "weight" = 10
    }
    "agreements" = @{
        "registerFunction" = (Get-Command Register-TmfAgreement)
        "testFunction" = (Get-Command Test-TmfAgreement)
        "invokeFunction" = (Get-Command Invoke-TmfAgreement)
        "weight" = 10
    }
    "conditionalAccessPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfConditionalAccessPolicy)
        "testFunction" = (Get-Command Test-TmfConditionalAccessPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfConditionalAccessPolicy)
        "weight" = 50
    }
} # All currently supported components.
Set-Variable -Name supportedResources -Option ReadOnly

$script:activatedConfigurations = @() # Overview of all activated configurations.
$script:desiredConfiguration = @{} # The desired configuration.