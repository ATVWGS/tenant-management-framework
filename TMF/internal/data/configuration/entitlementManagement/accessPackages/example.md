# Example accessPackage with active approvals and review

```json
{	
    "displayName":  "Sample package",
    "oldNames": [],
    "description":  "This is a sample access package.",
    "isHidden":  false,
    "isRoleScopesVisible":  true,
    "catalog":  "Sample catalog",
    "present":  true,
    "accessPackageResources":  [
        {
            "originSystem":  "AadGroup",
            "resourceRole":  "Member",
            "resourceIdentifier":  "Some group"
        }
    ],
    "assignmentPolicies": [
        {
            "displayName": "Sample assignment policy",
            "description": "Access Package Assignment Policy has been created with Tenant Management Framework",
            "allowedTargetScope": "specificDirectoryUsers",
            "present": true,
            "specificAllowedTargets": [
                {
                    "reference": "Some group",
                    "type": "groupMembers",
                    "description": "Some group"
                }
            ],
            "expiration": {
                "endDateTime": null,
                "duration": "P90D",
                "type": "afterDuration"
            },
            "requestorSettings": {
                "enableTargetsToSelfAddAccess": true,
                "enableTargetsToSelfUpdateAccess": false,
                "enableTargetsToSelfRemoveAccess": true,
                "allowCustomAssignmentSchedule": true,
                "enableOnBehalfRequestorsToAddAccess": true,
                "enableOnBehalfRequestorsToUpdateAccess": false,
                "enableOnBehalfRequestorsToRemoveAccess": false,
                "onBehalfRequestors": []
            },
            "requestApprovalSettings": {
                "isApprovalRequiredForAdd": true,
                "isApprovalRequiredForUpdate": true,
                "stages": [
                    {
                        "durationBeforeAutomaticDenial": "P14D",
                        "isApproverJustificationRequired": true,
                        "isEscalationEnabled": false,
                        "durationBeforeEscalation": "P5D",
                        "primaryApprovers": [
                            {
                                "reference": "Some group",
                                "type": "groupMembers",
                                "description": "Some group"
                            }
                        ],
                        "fallbackPrimaryApprovers": [],
                        "escalationApprovers": [
                            {
                                "reference": "foo.bar@tenant.onmicrosoft.com",
                                "type": "singleUser"
                            }
                        ],
                        "fallbackEscalationApprovers": []
                    }
                ]
            },
            "reviewSettings": {
                "isEnabled": true,
                "expirationBehavior": "keepAccess",
                "isRecommendationEnabled": true,
                "isReviewerJustificationRequired": true,
                "isSelfReview": true,
                "schedule": {
                    "startDateTime": "2023-04-18T09:34:49.4485321Z",
                    "expiration": {
                        "endDateTime": null,
                        "duration": "P7D",
                        "type": "afterDuration"
                    },
                    "recurrence": {
                        "pattern": {
                            "type": "absoluteMonthly",
                            "interval": 1,
                            "month": 0,
                            "dayOfMonth": 0,
                            "daysOfWeek": [],
                            "firstDayOfWeek": null,
                            "index": null
                        },
                        "range": {
                            "type": "noEnd",
                            "numberOfOccurrences": 0,
                            "recurrenceTimeZone": null,
                            "startDate": null,
                            "endDate": null
                        }
                    }
                },
                "primaryReviewers": [
                    {
                        "reference": "Some group",
                        "type": "groupMembers",
                        "description": "Some group"
                    }                    
                ],
                "fallbackReviewers": []
            }
        }
    ]
}  
```
# Example for accessPackage with auto-assignment policy

```json
{	
    "displayName":  "Sample package",
    "oldNames": [],
    "description":  "This package is a sample package for testing autoassignments.",
    "isHidden":  false,
    "isRoleScopesVisible":  true,
    "catalog":  "Sample catalog",
    "present":  true,
    "accessPackageResources":  [
        {
            "originSystem":  "AadGroup",
            "resourceRole":  "Member",
            "resourceIdentifier":  "Some group"
        }
    ],
    "assignmentPolicies": [
    
        {
            "displayName": "Test AutoAssign",
            "description": "Access Package Assignment Policy has been created with Tenant Management Framework",
            "allowedTargetScope": "specificDirectoryUsers",
            "specificAllowedTargets": [
                {
                    "membershipRule": "(user.userprincipalname -eq \"foo.bar@tenant.onmicrosoft.com\")",
                    "type": "attributeRuleMembers",
                    "description": "Test membershipRule"
                }
            ],
            "automaticRequestSettings": {
                "requestAccessForAllowedTargets": true
            }				
        }
    ]
}
```


The configuration of Access Packages is based on the Microsoft Graph accessPackage resource type. Also accessPackageResourceRoleScope resource type and accessPackageAssignmentPolicy resource type are required.

https://learn.microsoft.com/en-us/graph/api/resources/accesspackage?view=graph-rest-1.0
https://learn.microsoft.com/en-us/graph/api/accesspackage-post-accesspackageresourcerolescopes?view=graph-rest-beta&tabs=http&viewFallbackFrom=graph-rest-1.0
https://learn.microsoft.com/en-us/graph/api/resources/accesspackageassignmentpolicy?view=graph-rest-1.0
