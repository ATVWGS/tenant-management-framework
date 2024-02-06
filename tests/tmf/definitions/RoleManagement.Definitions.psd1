@{
    "groups" = @(
        @{
            "displayName" = "Test - roleManagement - Security Group"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "isAssignableToRole" = $true
            "mailEnabled" = $false
            "present" = $true
        }
    )
    "roleAssignments" = @(
        @{
            "type" = "eligible"
            "principalReference" = "Test - roleManagement - Security Group"
            "principalType" = "group"
            "roleReference" = "Cloud Device Deleter"
            "directoryScopeType" = "directory"
            "directoryScopeReference" = "/"
            "startDateTime" = "2022-09-06T16:26:49Z"
            "expirationType" = "noExpiration"
            "present" = $true
        }
        @{
            "type" = "active"
            "principalReference" = "Test - roleManagement - Security Group"
            "principalType" = "group"
            "roleReference" = "Directory Readers"
            "directoryScopeType" = "directory"
            "directoryScopeReference" = "/"
            "startDateTime" = "2022-09-06T16:26:49Z"
            "expirationType" = "noExpiration"
            "present" = $true
        }
    )
    "roleDefinitions" = @(
        @{
            "present" = $true
            "displayName" = "Cloud Device Deleter"
            "description" = "Allows deletion of cloud devices"
            "rolePermissions" = @(
                @{
                    "allowedResourceActions" = @(
                        "microsoft.directory/devices/delete"
                    )
                    "condition" = $null
                }
            )
        }
    )
    "roleManagementPolicies" = @(
        @{
            "roleReference" = "Cloud Device Deleter"
            "scopeReference" = "/"
            "scopeType" = "directory"
            "ruleTemplate" = "AzureAD_Tier1"
            "activationApprover" = @()
        }
    )
    "roleManagementPolicyRuleTemplates" = @(
        @{
            "displayName" = "AzureAD_Tier1"
            "rules" = @(
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
                  "isExpirationRequired" = $false
                  "maximumDuration" = "P365D"
                  "id" = "Expiration_Admin_Eligibility"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Eligibility"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Admin"
                  "isDefaultRecipientsEnabled" = $false
                  "notificationLevel" = "All"
                  "id" = "Notification_Admin_Admin_Eligibility"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Eligibility"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Requestor"
                  "isDefaultRecipientsEnabled" = $true
                  "notificationLevel" = "All"
                  "id" = "Notification_Requestor_Admin_Eligibility"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Eligibility"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
               @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Approver"
                  "isDefaultRecipientsEnabled" = $true
                  "notificationLevel" = "All"
                  "id" = "Notification_Approver_Admin_Eligibility"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Eligibility"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
                  "enabledRules" = @()
                  "id" = "Enablement_Admin_Eligibility"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Eligibility"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
                  "isExpirationRequired" = $false
                  "maximumDuration" = "P180D"
                  "id" = "Expiration_Admin_Assignment"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
                  "enabledRules" = @(
                    "Justification"
                  )
                  "id" = "Enablement_Admin_Assignment"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Admin"
                  "isDefaultRecipientsEnabled" = $false
                  "notificationLevel" = "All"
                  "id" = "Notification_Admin_Admin_Assignment"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Requestor"
                  "isDefaultRecipientsEnabled" = $true
                  "notificationLevel" = "All"
                  "id" = "Notification_Requestor_Admin_Assignment"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Approver"
                  "isDefaultRecipientsEnabled" = $true
                  "notificationLevel" = "All"
                  "id" = "Notification_Approver_Admin_Assignment"
                  "target" = @{
                    "caller" = "Admin"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
                  "isExpirationRequired" = $true
                  "maximumDuration" = "PT12H"
                  "id" = "Expiration_EndUser_Assignment"
                  "target" = @{
                    "caller" = "EndUser"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
                  "enabledRules" = @(
                    "Justification"
                  )
                  "id" = "Enablement_EndUser_Assignment"
                  "target" = @{
                    "caller" = "EndUser"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyAuthenticationContextRule"
                  "isEnabled" = $false
                  "claimValue" = ""
                  "id" = "AuthenticationContext_EndUser_Assignment"
                  "target" = @{
                    "caller" = "EndUser"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Admin"
                  "isDefaultRecipientsEnabled" = $false
                  "notificationLevel" = "All"
                  "id" = "Notification_Admin_EndUser_Assignment"
                  "target" = @{
                    "caller" = "EndUser"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Requestor"
                  "isDefaultRecipientsEnabled" = $true
                  "notificationLevel" = "All"
                  "id" = "Notification_Requestor_EndUser_Assignment"
                  "target" = @{
                    "caller" = "EndUser"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
                @{
                  "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
                  "notificationType" = "Email"
                  "recipientType" = "Approver"
                  "isDefaultRecipientsEnabled" = $true
                  "notificationLevel" = "All"
                  "id" = "Notification_Approver_EndUser_Assignment"
                  "target" = @{
                    "caller" = "EndUser"
                    "operations" = @(
                      "All"
                    )
                    "level" = "Assignment"
                    "inheritableSettings" = @()
                    "enforcedSettings" = @()
                  }
                }
            )
        }
    )
}