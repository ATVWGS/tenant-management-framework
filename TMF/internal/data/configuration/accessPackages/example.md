# Example accessPackage.json

```json
{    
    "description":"Sample access package",
    "displayName":"Access package for testing",
    "isHidden":false,
    "catalog":"Some accessPackageCatalog",
    "isRoleScopesVisible": false,
    "accessPackageAssignmentPolicy": [],
    "accessPackageResourceRoleScope": [
        {
            "accessPackageResourceRole" : {
                "displayName":"Member",
                "originSystem":"AadGroup",
                "accessPackageResource":{
                    "displayName": "Some resource",
                    "resourceType": "O365 Group"
                }
            },
            "accessPackageResourceScope":{
                "originId":"b31fe1f1-3651-488f-bd9a-1711887fd4ca","originSystem":"AadGroup"
            }
        },
    ],
    "present": true
}
```

The configuration of Access Packages is based on the Microsoft Graph accessPackage resource type. Also accessPackageResourceRoleScope resource type and accessPackageAssignmentPolicy resource type are required.

https://docs.microsoft.com/de-de/graph/api/resources/accesspackage?view=graph-rest-beta
https://docs.microsoft.com/de-de/graph/api/accesspackage-post-accesspackageresourcerolescopes?view=graph-rest-beta&tabs=http
https://docs.microsoft.com/de-de/graph/api/resources/accesspackageassignmentpolicy?view=graph-rest-beta
