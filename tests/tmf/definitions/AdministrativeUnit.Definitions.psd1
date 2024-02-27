@{
    "administrativeUnits" = @(
        @{
            "displayName" = "Test - {{ timestamp }} - AdministrativeUnit"
            "description" =  "This is an administrative unit"
            "visibility" = "Public"
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - Dynamic administrativeUnit"
            "description" = "This is a dynamic administrative unit"
            "visibility" = "Public"
            "membershipType" = "dynamic"
            "membershipRule" = "(user.accountenabled -eq true)"
            "membershipRuleProcessingState" = "ON"
            "present" = $true
        }
    )
}