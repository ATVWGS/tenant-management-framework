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
		"description" = "Test - TMF - Access Package"
		"isHidden" = $false
		"isRoleScopesVisible" = $true
		"catalog" = "Test - TMF - Access Package Catalog"
		"present" = $true
		"accessPackageResources" = @(
		  @{
			"originSystem" = "AadGroup"
			"resourceRole" = "Member"
			"resourceIdentifier" = "Test - TMF - AP Group"
		  }
        )
		"assignmentPolicies" = @(
			@{
				"displayName" = "Initial Policy (30 Days)"
				"allowedTargetScope" = "specificDirectoryUsers"
				"specificAllowedTargets" = @(
					@{
						"reference" = "Test - TMF - AP Requestor Group"
						"type" = "groupMembers"
						"description" = "Test - TMF - AP Requestor Group"
					}
                )
				"expiration" = @{
					"endDateTime" = $null
					"duration" = "P30D"
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
				  "isApprovalRequiredForUpdate" = $false
				  "isApprovalRequiredforAdd" = $true
				  "stages" = @(
					@{
					  "durationBeforeAutomaticDenial" = "P14D"
					  "isApproverJustificationRequired" = $true
					  "isEscalationEnabled" = $false
					  "durationBeforeEscalation" = "P5D"
					  "primaryApprovers" = @(
						@{
						  "reference" = "Test - TMF - AP Approver Group"
						  "isBackup" = $true
						  "type" = "groupMembers"
						}
                      )
					  "fallbackPrimaryApprovers" = @()
					  "escalationApprovers" = @()
					  "fallbackEscalationApprovers" = @()
					}
                  )
				}
				"reviewSettings" = @{
					  "isEnabled" = $false
					  "expirationBehavior" = "keepAccess"
					  "isRecommendationEnabled" = $true
					  "isReviewerJustificationRequired" = $true
					  "isSelfReview" = $true
					  "schedule" = @{
							"startDateTime"= "2030-04-18T09:34:49.4485321Z"
							"expiration" = @{
								"endDateTime" = $null
								"duration" = "P14D"
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