# Example directoryRoles.json

# Example for role with group and singleUser as role member
```json
{
    "present": true,
    "displayName": "Role displayname",
    "members": [
        {
            "type": "group",
            "reference": "some group"
        },
        {
            "type": "singleUser",
            "reference": "givenname.sn@tenant.onmicrosoft.com"
        }
    ]
}

```