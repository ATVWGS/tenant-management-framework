@{
    groups = @(
        @{
            "displayName" = "Test - {{ timestamp }} - Group for conditionalAccessPolicies"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "mailNickname" = "testGroupForConditionalAccessPolicies"
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - Group for conditionalAccessPolicies 2"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "mailNickname" = "testGroupForConditionalAccessPolicies2"
            "present" = $true
        }
    )
    namedLocations = @(
        @{
            "type" = "ipNamedLocation"
            "displayName" = "Test - {{ timestamp }} - Trusted Named Location"
            "isTrusted" = $true
            "ipRanges" = @(
                @{
                    "@odata.type" = "#microsoft.graph.iPv4CidrRange"
                    "cidrAddress" = "12.34.221.11/22"
                },
                @{
                    "@odata.type" = "#microsoft.graph.iPv4CidrRange"
                    "cidrAddress" = "12.34.221.12/22"
                }
            )
        }
    )
}