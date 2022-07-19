# Example roleDefinitions.json

# Custom role definition for Azure Resources
```json

{
    "present": true,
    "displayName": "Some role name",
    "description": "Some description",
    "subscriptionReference": "Subscription name",
    "assignableScopes": [
        "/subscriptions/subscriptionID",
        "/subscriptions/subscriptionID/ResourceGroups/resourceGroupName"
    ],
    "permissions": [
        {
            "actions": [
                "Microsoft.Resources/subscriptions/resourceGroups/write",
                "Microsoft.Resources/subscriptions/resourceGroups/delete"
            ],
            "notActions": [],
            "dataActions": [],
            "notDataActions": []
        }
    ]
}
```

# Custom role definition for AzureAD
```json

{
    "present": true,
    "displayName": "Some role name",
    "description": "Some description",
    "rolePermissions": [
        {
            "allowedResourceActions": [
                "microsoft.directory/groups/standard/read",
                "microsoft.directory/groups/memberOf/read",
                "microsoft.directory/groups/members/read",
                "microsoft.directory/groups/owners/read"
            ],
            "condition": null
        }
    ]
}
```