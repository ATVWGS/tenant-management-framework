# All required runtime variables.
$graphVersionRequired = "beta"
$script:graphBaseUrl = "https://graph.microsoft.com/{0}" -f $graphVersionRequired
$script:graphBaseUrl1 = "https://graph.microsoft.com/v1.0"
$script:apiBaseUrl = "https://management.azure.com/"
$script:apiVersion = "api-version=2022-01-01"

[regex] $script:guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'
[regex] $script:upnRegex = '^([A-Za-z\d\.\-]*)@([A-Za-z\d\.-]*)$'
[regex] $script:mailNicknameRegex = '^([A-Za-z\d\.]*)@([A-Za-z\d\.-]*)$'
[regex] $script:asterisk = '^\*?\w+\*?$'

$script:activatedConfigurations = @() # Overview of all activated configurations.
$script:desiredConfiguration = @{} # The desired configuration.
$script:cache = @{} # Multi purpose cache variable