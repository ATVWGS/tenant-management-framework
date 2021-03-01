# All required runtime variables.

$script:supportedComponents = @{
    "groups" = (Get-Command Register-TmfGroup)
}
Set-Variable -Name supportedComponents -Option ReadOnly

$script:activatedConfigurations = @() # Overview of all activated configurations
$script:desiredConfiguration = @{} # The desired configuration. Contains the definitions for each object type.
