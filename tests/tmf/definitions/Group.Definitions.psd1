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
                    "skuId" = "DEVELOPERPACK_E5"
                    "disabledPlans" = @(
                        "RMS_S_ENTERPRISE",
                        "CDS_O365_P3",
                        "LOCKBOX_ENTERPRISE",
                        "MIP_S_Exchange",
                        "EXCHANGE_S_ENTERPRISE",
                        "GRAPH_CONNECTORS_SEARCH_INDEX",
                        "Content_Explorer",
                        "MIP_S_CLP2",
                        "MIP_S_CLP1",
                        "M365_ADVANCED_AUDITING",
                        "OFFICESUBSCRIPTION",
                        "MICROSOFT_COMMUNICATION_COMPLIANCE",
                        "MTP",
                        "MCOEV",
                        "MICROSOFTBOOKINGS",
                        "COMMUNICATIONS_DLP",
                        "CUSTOMER_KEY",
                        "DATA_INVESTIGATIONS",
                        "ATP_ENTERPRISE",
                        "THREAT_INTELLIGENCE",
                        "EXCEL_PREMIUM",
                        "FORMS_PLAN_E5",
                        "INFO_GOVERNANCE",
                        "INSIDER_RISK",
                        "ML_CLASSIFICATION",
                        "EXCHANGE_ANALYTICS",
                        "PROJECTWORKMANAGEMENT",
                        "RECORDS_MANAGEMENT",
                        "MICROSOFT_SEARCH",
                        "Deskless",
                        "STREAM_O365_E5",
                        "TEAMS1",
                        "INTUNE_O365",
                        "Nucleus",
                        "EQUIVIO_ANALYTICS",
                        "ADALLOM_S_O365",
                        "PAM_ENTERPRISE",
                        "SAFEDOCS",
                        "SHAREPOINTWAC",
                        "POWERAPPS_O365_P3",
                        "BI_AZURE_P2",
                        "PROJECT_O365_P3",
                        "COMMUNICATIONS_COMPLIANCE",
                        "INSIDER_RISK_MANAGEMENT",
                        "SHAREPOINTENTERPRISE",
                        "MCOSTANDARD",
                        "SWAY",
                        "BPOS_S_TODO_3",
                        "VIVA_LEARNING_SEEDED",
                        "WHITEBOARD_PLAN3",
                        "YAMMER_ENTERPRISE",
                        "AAD_PREMIUM",
                        "AAD_PREMIUM_P2",
                        "RMS_S_PREMIUM",
                        "RMS_S_PREMIUM2",
                        "DYN365_CDS_O365_P3",
                        "MFA_PREMIUM",
                        "ADALLOM_S_STANDALONE",
                        "ATA",
                        "INTUNE_A",
                        "FLOW_O365_P3",
                        "POWER_VIRTUAL_AGENTS_O365_P3"
                    )
                }
            )
            "present" = $true
        }
        @{
            "displayName" = "Test - {{ timestamp }} - M365 Group - Hide Group"
            "description" = "This is a M365 group"
            "groupTypes" = @(
                "Unified"
            )
            "resourceBehaviorOptions" = @(
                "WelcomeEmailDisabled"
            )
            "hideFromAddressLists" = $true
            "hideFromOutlookClients" = $true
            "securityEnabled" = $false
            "members"= @()
            "mailEnabled" = $false
            "present" = $true
        }
    )
}