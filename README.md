# Introduction 

# Authentication
We are using the Microsoft.Graph module to make changes. This module also has a sub-module for authentication. You can connect using the following command.
```powershell
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"
```
https://github.com/microsoftgraph/msgraph-sdk-powershell

Please make sure you are connected to the correct Tenant before invoking configurations! 

The required scopes depend on what components (resources) you want to configure.
| Component (Resource)      | Required scopes                                 |
|---------------------------|-------------------------------------------------|
| Groups                    | Group.ReadWrite.All, GroupMember.ReadWrite.All  |
| Users                     | User.ReadWrite.All                              |
| Named Locations           | Policy.ReadWrite.ConditionalAccess              |
| Agreements (Terms of Use) | Agreement.ReadWrite.All                         |

You can use *Get-TmfRequiredScope* to get the required scopes.
```powershell
Connect-MgGraph -Scopes (Get-TmfRequiredScope -All)
```

# How to get started

### String mapping

You can create mappings between strings and the values they should be replaced with. Place the mappings in the *stringMappings.json* file in the *stringMappings* folder of your configuration.

| Property    | Description                                                                                |
|-------------|--------------------------------------------------------------------------------------------|
| name        | The name of the replacement string. Only digits (0-9) and letters (a-z A-Z) are allowed.   |
| replace     | The future value after replacing.                                                          |

```json
{
    "name": "GroupManagerName",
    "replace": "group.manager@volkswagen.de"
}
```

Currently not all resource properties are considered. All string properties on the first level are replaced.
| Resource       | Supported properties                                                                       |
|----------------|--------------------------------------------------------------------------------------------|
| agreements     | displayName, userReacceptRequiredFrequency                                                 |
| groups         | description, mailNickname, members, owners                                                 |
| namedLocations | displayName                                                                                |


To use the string mapping in a configuration file, you need to mention it by the name you provided in curly braces. Example: *{{ GroupManagerName }}*

```json
{   
    "displayName": "Some group",
    "description": "This is a security group. The group manager is {{ GroupManagerName }}",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someGroupForMembers",
    "members": ["max.mustermann@volkswagen.de"],
    "owners": ["group.owner@volkswagen.de"],
    "present": true
}
```