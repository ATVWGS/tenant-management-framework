# Introduction 

# Authentication
We are using the Microsoft.Graph module to make changes. This module also has a sub-module for authentication. You can connect using the following command.
```powershell
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"
```
https://github.com/microsoftgraph/msgraph-sdk-powershell

Please make sure you are connected to the correct Tenant before invoking configurations! 

The required scopes depend on what components (resources) you want to configure.
| Component (Resource) | Required scopes                                 |
|----------------------|-------------------------------------------------|
| Groups               | Group.ReadWrite.All, GroupMember.ReadWrite.All  |
| Users                | User.ReadWrite.All                              |

You can use *Get-TmfRequiredScope* to get the required scopes.
```powershell
Connect-MgGraph -Scopes (Get-TmfRequiredScope -All)
```