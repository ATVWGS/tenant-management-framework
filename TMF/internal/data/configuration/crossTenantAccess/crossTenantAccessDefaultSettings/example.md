# Example crossTenantAccessDefaultSettings.json
There can only be one item in this configuration file. Displayname is set by EntraID to default value and cannot be changed.

```json
{
    "displayName": "CrossTenantAccessDefaultSettings",
    "inboundTrust": {
        "isMfaAccepted": false,
        "isCompliantDeviceAccepted": false,
        "isHybridAzureADJoinedDeviceAccepted": false
    },
    "b2bCollaborationOutbound": {
        "usersAndGroups": {
            "accessType": "allowed",
            "targets": [
                {
                    "target": "AllUsers",
                    "targetType": "user"
                }
            ]
        },
        "applications": {
            "accessType": "allowed",
            "targets": [
                {
                    "target": "AllApplications",
                    "targetType": "application"
                }
            ]
        }
    },
    "b2bCollaborationInbound": {
        "usersAndGroups": {
            "accessType": "allowed",
            "targets": [
                {
                    "target": "AllUsers",
                    "targetType": "user"
                }
            ]
        },
        "applications": {
            "accessType": "allowed",
            "targets": [
                {
                    "target": "AllApplications",
                    "targetType": "application"
                }
            ]
        }
    },
    "b2bDirectConnectOutbound": {
        "usersAndGroups": {
            "accessType": "blocked",
            "targets": [
                {
                    "target": "AllUsers",
                    "targetType": "user"
                }
            ]
        },
        "applications": {
            "accessType": "blocked",
            "targets": [
                {
                    "target": "AllApplications",
                    "targetType": "application"
                }
            ]
        }
    },
    "b2bDirectConnectInbound": {
        "usersAndGroups": {
            "accessType": "blocked",
            "targets": [
                {
                    "target": "AllUsers",
                    "targetType": "user"
                }
            ]
        },
        "applications": {
            "accessType": "blocked",
            "targets": [
                {
                    "target": "AllApplications",
                    "targetType": "application"
                }
            ]
        }
    },
    "automaticUserConsentSettings": {
        "inboundAllowed": false,
        "outboundAllowed": false
    },
    "tenantRestrictions": {
        "devices": null,
        "usersAndGroups": {
            "accessType": "blocked",
            "targets": [
                {
                    "target": "AllUsers",
                    "targetType": "user"
                }
            ]
        },
        "applications": {
            "accessType": "blocked",
            "targets": [
                {
                    "target": "AllApplications",
                    "targetType": "application"
                }
            ]
        }
    },
    "invitationRedemptionIdentityProviderConfiguration": {
        "primaryIdentityProviderPrecedenceOrder": [
            "azureActiveDirectory",
            "externalFederation",
            "socialIdentityProviders"
        ],
        "fallbackIdentityProvider": "defaultConfiguredIdp"
    }
}

```