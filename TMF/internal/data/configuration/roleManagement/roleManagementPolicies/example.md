# Example roleManagementPolicies.json

# RoleManagementPolicy for directory role with approver group
```json
{
    "roleReference": "directory role name",
    "activationApprover": [
        {
            "reference": "Some group",
            "type": "group"
        }
    ],
    "scopeReference": "/",
    "scopeType": "directory",
    "ruleTemplate": "some rule template"
}
```

# RoleManagementPolicy for directory role without approval
```json
{
    "roleReference": "directory role name",
    "activationApprover": [],
    "scopeReference": "/",
    "scopeType": "directory",
    "ruleTemplate": "some rule template"
}
```

# RoleManagementPolicy for AzureResource role on subscription level with approver
```json
{
    "roleReference": "role name",
    "subscriptionReference": "subscription name",
    "scopeReference": "subscription name",
    "scopeType": "subscription",
    "activationApprover": [
        {
            "reference": "userPrincipalName",
            "type": "user"
        }
    ],
    "ruleTemplate": "some rule template"
}
```

# RoleManagementPolicy for AzureResource role on resourceGroup level without approval
```json
{
    "roleReference": "role name",
    "subscriptionReference": "subscription name",
    "scopeReference": "resourceGroup name",
    "scopeType": "resourceGroup",
    "activationApprover": [],
    "ruleTemplate": "some rule template"
}