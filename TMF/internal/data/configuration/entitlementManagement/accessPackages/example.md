# Example accessPackage.json

```json
{
    "displayName" : "Access Package",
    "description" : "description",
    "isHidden" : true,
    "isRoleScopesVisible" : true,
    "catalog": "General",
    
    "accessPackageResources" : [
        {
            "resourceIdentifier": "Some group",
            "originSystem": "AadGroup",
            "present": true
        }
    ],
    "assignementPolicies" : [
        {
            "displayName" : "policyDisplayName",
            "description" : "policyDescription",
            "canExtend" : false,
            "durationInDays" : 14,
            
            "accessRevieIsEnabled" : true,
            "accessReviewRecurrenceType" : "monthly",
            "accessReviewReviewerType" : "Reviewer",
            "accessReviewDurationInDays" : 14,
            "accessReviewer" : ["Some group"],
            
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
