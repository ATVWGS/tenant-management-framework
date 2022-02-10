# Example accessReviews.json

### An access review for a group reviewed by groupmembers running quaterly with no end
```json
{
    "displayName": "Displayname of the access review",
    "present": true,
    "scope": {
      "type": "group",
      "reference": "some group"
    },
    "reviewers": [
        {
            "type": "groupMembers",
            "reference":"some group"
        }
    ],
    "settings": {
        "mailNotificationsEnabled": true,
        "reminderNotificationsEnabled": true,
        "justificationRequiredOnApproval": true,
        "defaultDecisionEnabled": false,
        "defaultDecision": "None",
        "instanceDurationInDays": 14,
        "autoApplyDecisionsEnabled": false,
        "recommendationsEnabled": true,
        "recurrence": {
            "pattern": {
                "type": "absoluteMonthly",
                "interval": 3,
                "month": 0,
                "dayOfMonth": 0,
                "daysOfWeek": [],
                "firstDayOfWeek": "sunday",
                "index": "first"
            },
            "range": {
                "type": "noEnd",
                "numberOfOccurrences": 0,
                "recurrenceTimeZone": null,
                "startDate": "2022-03-01",
                "endDate": "9999-12-31"
            }
        }
    }
  }
```
### An access review for a directoryRole (assigned to users/groups) reviewed by single users running annually with no end
```json
{
    "displayName": "Displayname of the access review",
    "present": true,
    "scope": {
      "type": "directoryRole",
      "subScope": "users_groups",
      "reference": "some directoryRole"
    },
    "reviewers": [
        {
            "type": "singleUser",
            "reference": "givenname.sn@tenant.onmicrosoft.com"
        },
        {
            "type": "singleUser",
            "reference": "givenname.sn@tenant.onmicrosoft.com"
        }
    ],
    "settings": {
        "mailNotificationsEnabled": true,
        "reminderNotificationsEnabled": true,
        "justificationRequiredOnApproval": true,
        "defaultDecisionEnabled": false,
        "defaultDecision": "None",
        "instanceDurationInDays": 21,
        "autoApplyDecisionsEnabled": false,
        "recommendationsEnabled": true,
        "recurrence": {
            "pattern": {
                "type": "absoluteMonthly",
                "interval": 12,
                "month": 0,
                "dayOfMonth": 0,
                "daysOfWeek": [],
                "firstDayOfWeek": "sunday",
                "index": "first"
            },
            "range": {
                "type": "noEnd",
                "numberOfOccurrences": 0,
                "recurrenceTimeZone": null,
                "startDate": "2022-03-01",
                "endDate": "9999-12-31"
            }
        }
    }
}
```
### An access review for a directoryRole (assigned to servicePrincipals) reviewed by a group running annually with no end
```json
{
    "displayName": "Displayname of the access review",
    "present": true,
    "scope": {
      "type": "directoryRole",
      "subScope": "servicePrincipals",
      "reference": "some directoryRole"
    },
    "reviewers": [
        {
            "type": "groupMembers",
            "reference": "some group"
        }
    ],
    "settings": {
        "mailNotificationsEnabled": true,
        "reminderNotificationsEnabled": true,
        "justificationRequiredOnApproval": true,
        "defaultDecisionEnabled": false,
        "defaultDecision": "None",
        "instanceDurationInDays": 21,
        "autoApplyDecisionsEnabled": false,
        "recommendationsEnabled": true,
        "recurrence": {
            "pattern": {
                "type": "absoluteMonthly",
                "interval": 12,
                "month": 0,
                "dayOfMonth": 0,
                "daysOfWeek": [],
                "firstDayOfWeek": "sunday",
                "index": "first"
            },
            "range": {
                "type": "noEnd",
                "numberOfOccurrences": 0,
                "recurrenceTimeZone": null,
                "startDate": "2022-03-01",
                "endDate": "9999-12-31"
            }
        }
    }
}
```