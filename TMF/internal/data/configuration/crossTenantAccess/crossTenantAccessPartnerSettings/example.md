# Example crossTenantAccessPartnerSettings.json
To reset values back to default settings, set value back to null!

# Example takes all settings from default configuration
```json
{
    "displayName": "tenantName",
    "tenantId": "tenantId",
    "present": true,
    "inboundTrust": null,
    "b2bCollaborationOutbound": null,
    "b2bCollaborationInbound": null,
    "b2bDirectConnectOutbound": null,
    "b2bDirectConnectInbound": null,
    "tenantRestrictions": null,
    "invitationRedemptionIdentityProviderConfiguration": null,
    "automaticUserConsentSettings": {
        "inboundAllowed": null,
        "outboundAllowed": null
    }
}
```

# Example which overrides settings from default configuration
```json
{
    "displayName": "tenantName",
    "tenantId": "tenantId",
    "present": true,
    "inboundTrust": {
        "isMfaAccepted": false,
        "isCompliantDeviceAccepted": true,
        "isHybridAzureADJoinedDeviceAccepted": false
    },
    "b2bCollaborationOutbound": null,
    "b2bCollaborationInbound": {
        "usersAndGroups": {
            "accessType": "allowed",
            "targets": [
                {
                    "target": "some GroupID",
                    "targetType": "group"
                }
            ]
        },
        "applications": {
            "accessType": "allowed",
            "targets": [
                {
                    "target": "some ApplicationId",
                    "targetType": "application"
                }
            ]
        }
    },
    "b2bDirectConnectOutbound": null,
    "b2bDirectConnectInbound": null,
    "tenantRestrictions": null,
    "invitationRedemptionIdentityProviderConfiguration": null,
    "automaticUserConsentSettings": {
        "inboundAllowed": null,
        "outboundAllowed": true
    }
}
```