# Example accessPackage.json

```json
{
    "displayName" : "Access Package",
    "description" : "description",
    "isHidden" : true,
    "isRoleScopesVisible" : true,
    "catalog": "General",
    
    "accessReviewSettings" : {
        "isEnabled" : true,
        "recurrenceType" : "monthly",
        "reviewerType" : "Reviewers",
        "durationInDays" : 14,
        "reviewers" : ["johannes.seitle@tmacdev.onmicrosoft.com"]
    },
    "assignementPolicies" : [
        {
            "displayName" : "policyDisplayName",
            "description" : "policyDescription",
            "canExtend" : false,
            "durationInDays" : 14,
            
            "accessReviewSettings" : {
                "isEnabled" : true,
                "recurrenceType" : "monthly",
                "reviewerType" : "Reviewer",
                "reviewDurationInDays" : 14,
                "accessReviewer" : ["johannes.seitle@tmacdev.onmicrosoft.com"]
            },
            
            "requestorScopeType" : "SpecificDirectorySubjects",
            "requestorAcceptRequests" : false,
            "allowedRequestors" : ["Some group"],
            
            "isApprovalRequired" : true,
            "isApprovalRequiredForExtension" : true,
            "isRequestorJustificationRequired" : true,
            "approvalMode" : "SingleStage",
            "approvalStageTimeOutInDays" : 14,
            "isApproverJustificationRequired" : false,
            "isEscalationEnabled" : true,
            "escalationTimeInMinutes" : 2880,
            "primaryApprovers" : ["Some group"],
            "escalationApprovers" : ["Some group"],
            "questions" : [""]
        }
    ]    
}
```

The configuration of Access Packages is based on the Microsoft Graph accessPackage resource type. Also accessPackageResourceRoleScope resource type and accessPackageAssignmentPolicy resource type are required.

https://docs.microsoft.com/de-de/graph/api/resources/accesspackage?view=graph-rest-beta
https://docs.microsoft.com/de-de/graph/api/accesspackage-post-accesspackageresourcerolescopes?view=graph-rest-beta&tabs=http
https://docs.microsoft.com/de-de/graph/api/resources/accesspackageassignmentpolicy?view=graph-rest-beta
