# All required runtime variables.

$script:supportedComponents = @(
    "groups",
    "namedLocations",
    "termsOfUse",
    "users",
    "conditionalAccess"
)
Set-Variable -Name supportedComponents -Option ReadOnly

$script:activatedConfigurations = @() # Overview of all activated configurations
$script:desiredConfiguration = @{} # The desired configuration. Contains the definitions for each object type.
