# Example for tenantAppManagementPolicy

# Only one tenantAppManagementPolicy exists within the tenant, so only one configuration can exist!

```json
{
    "displayname": "Default app management tenant policy",
    "description": "Default tenant policy that enforces app management restrictions on applications and service principals. To apply policy to targeted resources, create a new policy under appManagementPolicies collection.",
    "isEnabled": true,
    "applicationRestrictions": {
        "passwordCredentials": [
            {
                "restrictionType": "passwordAddition",
                "maxLifetime": null,
                "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
            },
            {
                "restrictionType": "passwordLifetime",
                "maxLifetime": "P4DT12H30M5S",
                "restrictForAppsCreatedAfterDateTime": "2017-01-01T10:37:00Z"
            },
            {
                "restrictionType": "symmetricKeyAddition",
                "maxLifetime": null,
                "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
            },
            {
                "restrictionType": "customPasswordAddition",
                "maxLifetime": null,
                "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
            },
            {
                "restrictionType": "symmetricKeyLifetime",
                "maxLifetime": "P40D",
                "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
            }
        ],
        "keyCredentials":[
            {
                "restrictionType": "asymmetricKeyLifetime",
                "maxLifetime": "P30D",
                "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
            },
        ]
    },
    "servicePrincpialRestrictions": {
        "passwordCredentials": [
            {
                "restrictionType": "passwordAddition",
                "maxLifetime": null,
                "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
            },
            {
                "restrictionType": "passwordLifetime",
                "maxLifetime": "P4DT12H30M5S",
                "restrictForAppsCreatedAfterDateTime": "2017-01-01T10:37:00Z"
            },
            {
                "restrictionType": "symmetricKeyAddition",
                "maxLifetime": null,
                "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
            },
            {
                "restrictionType": "customPasswordAddition",
                "maxLifetime": null,
                "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
            },
            {
                "restrictionType": "symmetricKeyLifetime",
                "maxLifetime": "P40D",
                "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
            }
        ],
        "keyCredentials":[
            {
                "restrictionType": "asymmetricKeyLifetime",
                "maxLifetime": "P30D",
                "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
            },
        ]
    }
}
```

For further information refer to https://learn.microsoft.com/en-us/graph/api/resources/tenantappmanagementpolicy?view=graph-rest-beta