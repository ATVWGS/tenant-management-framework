@{
    "groups" = @(
        @{
            "displayName" = "Test - {{ timestamp }} - Security Group"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - Security Group - Mail Enabled"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - Security Group - Dynamic Membership"
            "description" = "This is a security group"
            "groupTypes" = @(
                "DynamicMembership"             
            )
            "securityEnabled" = $true
            "membershipRule" = "(user.userType -eq `"Guest`")"
            "mailEnabled" = $false
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - M365 Group"
            "description" = "This is a M365 group"
            "groupTypes" = @(
                "Unified"
            )
            "securityEnabled" = $false
            "members"= @()
            "mailEnabled" = $false
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - M365 Group - No Welcome Mail"
            "description" = "This is a M365 group"
            "groupTypes" = @(
                "Unified"
            )
            "resourceBehaviorOptions" = @(
                "WelcomeEmailDisabled"
            )
            "securityEnabled" = $false
            "members"= @()
            "mailEnabled" = $false
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - M365 Group - Dynamic Membership"
            "description" = "This is a M365 group"
            "groupTypes" = @(
                "DynamicMembership",
                "Unified"
            )
            "securityEnabled" = $false
            "membershipRule" = "(user.userType -eq `"Guest`")"
            "mailEnabled" = $false
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - Security Group - Assigned Licenses"
            "description" = "This is a group with assigned licenses"
            "groupTypes" = @()
            "securityEnabled" = $true
            "mailEnabled" = $false
            "assignedLicenses" = @(
                @{
                    "skuId" = "FLOW_FREE"
                    "disabledPlans" = @(
                        "FLOW_P2_VIRAL"
                    )
                }
            )
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - Security Group - Privileged Access"
            "description" = "This is a group with assigned licenses"
            "groupTypes" = @()
            "securityEnabled" = $true
            "mailEnabled" = $false
            "isAssignableToRole" = $true
            "privilegedAccess" = $true
            "present" = $true
        }
    )
}