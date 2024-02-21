@{
    "groups" = @(
        @{
          "displayName" = "Test - TMF - AP Group"
          "description" = "This is a security group"
          "groupTypes" = @()
          "securityEnabled" = $true
          "isAssignableToRole" = $false
          "mailEnabled" = $false
          "present" = $true
        }
        @{
            "displayName" = "Test - TMF - AP Requestor Group"
            "description" = "This is a security group"
            "groupTypes" = @()
            "securityEnabled" = $true
            "isAssignableToRole" = $false
            "mailEnabled" = $false
            "present" = $true
        }
        @{
          "displayName" = "Test - TMF - AP Approver Group"
          "description" = "This is a security group"
          "groupTypes" = @()
          "securityEnabled" = $true
          "isAssignableToRole" = $false
          "mailEnabled" = $false
          "present" = $true
        }
    )
    "accessPackages" = @(
      @{	
        "displayName" = "Test - TMF - Access Package"
        "oldNames" = @()
        "description" =  "This is a TMF test access package."
        "isHidden" = $false
        "isRoleScopesVisible" = $true
        "catalog" = "Test - TMF - Access Package Catalog"
        "present" = $true
        "accessPackageResources" =  @(
            @{
                "originSystem" = "AadGroup"
                "resourceRole" = "Member"
                "resourceIdentifier" = "Test - TMF - AP Group"
            }
        )
        "assignmentPolicies" = @(
            @{
                "displayName" = "Initial policy"
                "description" = "Access Package Assignment Policy has been created with Tenant Management Framework"
                "allowedTargetScope" = "specificDirectoryUsers"
                "present" = $true
                "specificAllowedTargets" = @(
                    @{
                        "reference" = "Test - TMF - AP Requestor Group"
                        "type" = "groupMembers"
                        "description" = "Test - TMF - AP Requestor Group"
                    }
                )
                "expiration" = @{
                    "endDateTime" = $null
                    "duration" = "P90D"
                    "type" = "afterDuration"
                }
                "requestorSettings" = @{
                    "enableTargetsToSelfAddAccess" = $true
                    "enableTargetsToSelfUpdateAccess" = $false
                    "enableTargetsToSelfRemoveAccess" = $true
                    "allowCustomAssignmentSchedule" = $true
                    "enableOnBehalfRequestorsToAddAccess" = $true
                    "enableOnBehalfRequestorsToUpdateAccess" = $false
                    "enableOnBehalfRequestorsToRemoveAccess" = $false
                    "onBehalfRequestors" = @()
                }
                "requestApprovalSettings" = @{
                    "isApprovalRequiredForAdd" = $true
                    "isApprovalRequiredForUpdate" = $true
                    "stages" = @(
                        @{
                            "durationBeforeAutomaticDenial" = "P14D"
                            "isApproverJustificationRequired" = $true
                            "isEscalationEnabled" = $false
                            "durationBeforeEscalation" = "P5D"
                            "primaryApprovers" = @(
                                @{
                                    "reference" = "Test - TMF - AP Approver Group"
                                    "type" = "groupMembers"
                                    "description" = "Test - TMF - AP Approver Group"
                                }
                            )
                            "fallbackPrimaryApprovers" = @()
                            "escalationApprovers" = @()
                            "fallbackEscalationApprovers" =@()
                        }
                    )
                }
                "reviewSettings" = @{
                    "isEnabled" = $true
                    "expirationBehavior" = "keepAccess"
                    "isRecommendationEnabled" = $true
                    "isReviewerJustificationRequired" = $true
                    "isSelfReview" = $true
                    "schedule" = @{
                        "startDateTime" = "2030-04-18T09:34:49.4485321Z"
                        "expiration" = @{
                            "endDateTime" = $null
                            "duration" = "P7D"
                            "type" = "afterDuration"
                        }
                        "recurrence" = @{
                            "pattern" = @{
                                "type" = "absoluteMonthly"
                                "interval" = 1
                                "month" = 0
                                "dayOfMonth" = 0
                                "daysOfWeek" = @()
                                "firstDayOfWeek" = $null
                                "index" = $null
                            }
                            "range" = @{
                                "type" = "noEnd"
                                "numberOfOccurrences" = 0
                                "recurrenceTimeZone" = $null
                                "startDate" = $null
                                "endDate" = $null
                            }
                        }
                    }
                    "primaryReviewers" = @(
                        @{
                            "reference" = "Test - TMF - AP Approver Group"
                            "type" = "groupMembers"
                            "description" = "Test - TMF - AP Approver Group"
                        }                    
                    )
                    "fallbackReviewers" = @()
                }
            }
        )
      }
    )
    "accessPackageCatalogs" = @(
      @{    
          "displayName" = "Test - TMF - Access Package Catalog"
          "description" = "Test - TMF - Access Package Catalog"
          "isExternallyVisible" = $false
          "present" = $true
      }
    )
}