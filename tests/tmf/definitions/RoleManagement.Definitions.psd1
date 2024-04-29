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
            "roleReference" = "Usage Summary Reports Reader"
            "directoryScopeType" = "directory"
            "directoryScopeReference" = "/"
            "startDateTime" = "2030-12-31T16:26:49Z"
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
}