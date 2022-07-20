# Example groups.json
Additional properties will be added in the future.

### A security group with static membership
```json
{   
    "displayName": "Some group",
    "description": "This is a security group",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someGroupForMembers",
    "members": ["max.mustermann@volkswagen.de"],
    "owners": ["group.owner@volkswagen.de"],
    "present": true
}
```

### A privileged access group which is assignableToRole
```json
{   
    "displayName": "Some group",
    "description": "This is a security group",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "privilegedAccess": true,
    "isAssignableToRole": true,
    "mailNickname": "someGroupForMembers",
    "present": true
}
```

### A security group with dynamic membership
```json
{   
    "displayName": "Some group with dynamic membership",
    "description": "This is a security group",
    "groupTypes": ["dynamicMembership"],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someDynamicGroup",
    "membershipRule" : "(user.userPrincipalName -match \".*@volkswagen.de$\"",
    "owners": ["group.owner@volkswagen.de"],
    "present": true
}
```

### A Microsoft 365 group with static membership
```json
{   
    "displayName": "Some group with dynamic membership",
    "description": "This is a security group",
    "groupTypes": ["Unified"],
    "securityEnabled": false,
    "mailEnabled": true,
    "visibility": "Public",
    "mailNickname": "someDynamicGroup",
    "members": ["max.mustermann@volkswagen.de"],
    "owners": ["group.owner@volkswagen.de"],
    "present": true
}
```

### A Microsoft 365 group with dynamic membership
```json
{   
    "displayName": "Some group with dynamic membership",
    "description": "This is a security group",
    "groupTypes": ["Unified", "DynamicMembership"],
    "securityEnabled": false,
    "mailEnabled": true,
    "visibility": "HiddenMembership",
    "mailNickname": "someDynamicGroup",
    "members": ["max.mustermann@volkswagen.de"],
    "owners": ["group.owner@volkswagen.de"],
    "present": true
}
```

### A security group with static membership and assignedLicenses
```json
{   
    "displayName": "Some group",
    "description": "This is a security group",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someGroupForMembers",
    "members": ["max.mustermann@volkswagen.de"],
    "owners": ["group.owner@volkswagen.de"],
    "assignedLicenses": [
        {
            "skuId": "licenseID",
            "disabledPlans": [
                "disabledPlan1ID",
                "disabledPlan2ID"
            ]
        }
    ],
    "present": true
}
```

### Microsoft Graph resource types and documents
https://docs.microsoft.com/de-de/graph/api/resources/group?view=graph-rest-1.0
https://docs.microsoft.com/de-de/graph/api/group-post-groups?view=graph-rest-1.0&tabs=http

Group types: https://docs.microsoft.com/de-de/graph/api/resources/groups-overview?view=graph-rest-1.0