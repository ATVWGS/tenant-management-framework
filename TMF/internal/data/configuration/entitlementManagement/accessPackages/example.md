# Example accessPackage.json

```json
{
    "displayName":"Access Package",
    "description":"Access Package description",
    "isHidden":true,
    "isRoleScopesVisible":true,
    "catalog":"General",
    "present":true,
    "accessPackageResources":[
        {
            "resourceIdentifier":"Some group",
            "resourceRole":"Member",
            "originSystem":"AadGroup"
        }
    ],
    "assignmentPolicies":[
        {
            "displayName":"Initial policy",
            "canExtend":false,
            "durationInDays":8,
            "accessReviewSettings":{
                "isEnabled":false,
                "recurrenceType":"monthly",
                "reviewerType":"Reviewers",
                "durationInDays":14,
                "reviewers":[
                    {
                        "type":"singleUser",
                        "reference":"max.mustermann@tmacdev.onmicrosoft.com",
                        "isBackup":false
                    },
                    {
                        "type":"requestorManager",
                        "managerLevel":1,
                        "isBackup":false
                    }
                ]
            },
            "requestApprovalSettings":{
                "isApprovalRequired":true,
                "isApprovalRequiredForExtension":false,
                "isRequestorJustificationRequired":true,
                "approvalMode":"SingleStage",
                "approvalStages":[
                    {
                        "approvalStageTimeOutInDays":14,
                        "isApproverJustificationRequired":true,
                        "isEscalationEnabled":false,
                        "escalationTimeInMinutes":11520,
                        "primaryApprovers":[
                            {
                                "type":"singleUser",
                                "reference":"johannes.seitle@tmacdev.onmicrosoft.com",
                                "isBackup":false
                            }
                        ]
                    }
                ]
            },
            "requestorSettings":{
                "scopeType":"SpecificDirectorySubjects",
                "acceptRequests":true,
                "allowedRequestors":[
                    {
                        "type":"singleUser",
                        "reference":"max.mustermann@tmacdev.onmicrosoft.com",
                        "isBackup":false
                    }
                ]
            }
        }
    ]
}    
```

The configuration of Access Packages is based on the Microsoft Graph accessPackage resource type. Also accessPackageResourceRoleScope resource type and accessPackageAssignmentPolicy resource type are required.

https://docs.microsoft.com/de-de/graph/api/resources/accesspackage?view=graph-rest-beta
https://docs.microsoft.com/de-de/graph/api/accesspackage-post-accesspackageresourcerolescopes?view=graph-rest-beta&tabs=http
https://docs.microsoft.com/de-de/graph/api/resources/accesspackageassignmentpolicy?view=graph-rest-beta
