# All required runtime variables.
[regex] $guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'
[regex] $upnRegex = '^([A-Za-z\d\.]*)@([A-Za-z\d\.-]*)$'

$graphVersionRequired = "beta"
$script:graphBaseUrl = "https://graph.microsoft.com/{0}" -f $graphVersionRequired

$script:supportedComponents = @{
    "groups" = (Get-Command Register-TmfGroup)
}
Set-Variable -Name supportedComponents -Option ReadOnly

$script:activatedConfigurations = @() # Overview of all activated configurations
$script:desiredConfiguration = @{} # The desired configuration. Contains the definitions for each object type.