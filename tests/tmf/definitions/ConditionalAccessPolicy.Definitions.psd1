@{
    groups = @(
        @{
            "displayName" = "Test - TMF - CA Exclusion Group"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "isAssignableToRole" = $false
            "mailEnabled" = $false
            "present" = $true
        }
    )
    conditionalAccessPolicies = @(
        @{
            "displayName" = "Block Access to Microsoft Forms"
            "excludeGroups" = @("Test - TMF - CA Exclusion Group")
            "includeApplications" = @("Microsoft Forms")
            "includeUsers" = @("All")
            "includeLocations" = @("All")
            "clientAppTypes" = @("browser", "mobileAppsAndDesktopClients")
            "includePlatforms" = @("All")
            "grantControls" = @{
                "builtInControls" = @("block")
                "operator" = "OR"
            }
            "state" = "enabledForReportingButNotEnforced"
            "present" = $true
        }    
    )
}