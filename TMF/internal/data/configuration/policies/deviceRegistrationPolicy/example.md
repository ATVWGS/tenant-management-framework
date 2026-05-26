# Example deviceRegistrationPolicy configuration
## allowed @odata.type values: allowedToRegister -> "#microsoft.graph.allDeviceRegistrationMembership" or "#microsoft.graph.noDeviceRegistrationMembership"
## allowed @odata.type values: allowedToJoin/registeringUsers -> "#microsoft.graph.allDeviceRegistrationMembership" or "#microsoft.graph.noDeviceRegistrationMembership" or "#microsoft.graph.enumeratedDeviceRegistrationMembership"

```json
{
  "present": true,
  "displayName": "deviceRegistrationPolicy",
  "multiFactorAuthConfiguration": "notRequired",
  "userDeviceQuota": 50,
  "azureADRegistration": {
    "allowedToRegister": {
      "@odata.type": "#microsoft.graph.allDeviceRegistrationMembership"
    },
    "isAdminConfigurable": false
  },
  "localAdminPassword": {
    "isEnabled": false
  },
  "azureADJoin": {
    "allowedToJoin": {
      "users": [
        "someUserUPN"
      ],
      "@odata.type": "#microsoft.graph.enumeratedDeviceRegistrationMembership",
      "groups": [
        "someGroupDisplayName"
      ]
    },
    "localAdmins": {
      "registeringUsers": {
        "users": [
            "someUserUPN"
        ],
        "@odata.type": "#microsoft.graph.enumeratedDeviceRegistrationMembership",
        "groups": [
            "someGroupDisplayName"
        ]
      },
      "enableGlobalAdmins": true
    },
    "isAdminConfigurable": true
  }
}
```