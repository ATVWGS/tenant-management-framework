@{
    groups = @(
        @{
            "displayName" = "Test - TMF - Security Group for Access Review"
            "description" = "This is a security group to be used in an Access Review"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "present" = $true
        }
        @{
            "displayName" = "Test - TMF - Security Group for Reviewer"
            "description" = "This is a security group to be used as Reviewer"
            "groupTypes" = @()
            "securityEnabled" = $true
            "members"= @()
            "mailEnabled" = $false
            "present" = $true
        }
    )
    accessReviews = @(
        @{
            "displayName" = "Test  - {{ timestamp }} - AccessReview Group"
            "present"= $true
            "scope"= @{
              "type"= "group"
              "reference"= "Test - TMF - Security Group for Access Review"
            }
            "reviewers"= @(
                @{
                    "type"= "groupMembers"
                    "reference"="Test - TMF - Security Group for Reviewer"
                }
            )
            "settings"= @{
                "mailNotificationsEnabled"= $true
                "reminderNotificationsEnabled"= $true
                "justificationRequiredOnApproval"= $true
                "defaultDecisionEnabled"= $false
                "defaultDecision"= "None"
                "instanceDurationInDays"= 14
                "autoApplyDecisionsEnabled"= $false
                "recommendationsEnabled"= $true
                "recurrence"= @{
                    "pattern"= @{
                        "type"= "absoluteMonthly"
                        "interval"= 3
                        "month"= 0
                        "dayOfMonth"= 0
                        "daysOfWeek"= @()
                        "firstDayOfWeek"= "sunday"
                        "index"= "first"
                    }
                    "range"= @{
                        "type"= "noEnd"
                        "numberOfOccurrences"= 0
                        "recurrenceTimeZone"= $null
                        "startDate"= "2030-01-01"
                        "endDate"= "9999-12-31"
                    }
                }
            }
        }
    )
}