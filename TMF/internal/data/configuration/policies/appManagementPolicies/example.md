# Example for appManagementPolicy

# appliesTo is a string array that contains all application displaynames on which the policy should be enforced.

```json
{
    "displayName": "appManagementPolicyTest",
    "description": "Test policy for appManagement",
    "isEnabled": true,
    "restrictions": {
        "passwordCredentials": [
            {
                "restrictionType": "passwordAddition",
                "maxLifetime": null,
                "restrictForAppsCreatedAfterDateTime": "2023-01-01T10:37:00Z"
            },
            {
                "restrictionType": "passwordLifetime",
                "maxLifetime": "P365D",
                "restrictForAppsCreatedAfterDateTime": "2023-01-01T10:37:00Z"
            }
        ],
        "keyCredentials": [
            {
                "restrictionType": "asymmetricKeyLifetime",
                "maxLifetime": "P90D",
                "restrictForAppsCreatedAfterDateTime": "2023-01-01T10:37:00Z"
            }
        ]
    },
    "appliesTo": [
        "application1",
        "application2"
    ],
    "present": true		
}

For further information refer to https://learn.microsoft.com/en-us/graph/api/resources/appmanagementpolicy?view=graph-rest-beta