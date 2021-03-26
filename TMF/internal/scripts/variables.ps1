# All required runtime variables.
$graphVersionRequired = "beta"
$script:graphBaseUrl = "https://graph.microsoft.com/{0}" -f $graphVersionRequired

[regex] $script:guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'
[regex] $script:upnRegex = '^([A-Za-z\d\.]*)@([A-Za-z\d\.-]*)$'

$script:supportedComponents = @{
    "stringMappings" = (Get-Command Register-TmfStringMapping)
    "groups" = (Get-Command Register-TmfGroup)
    "namedLocations" = (Get-Command Register-TmfNamedLocation)
    "agreements" = (Get-Command Register-TmfAgreement)
    "accessPackages" = (Get-Command Register-TmfAccessPackage)
} # All currently supported components.
Set-Variable -Name supportedComponents -Option ReadOnly

$script:activatedConfigurations = @() # Overview of all activated configurations.

$script:desiredConfiguration = @{} # The desired configuration.