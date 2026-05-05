# Example for adminConsentRequestPolicy
```json
{
  "present": true,
  "displayName": "adminConsentRequestPolicy",
  "notifyReviewers": true,
  "remindersEnabled": true,
  "isEnabled": true,
  "requestDurationInDays": 30,
  "reviewers": [
    {
        "reference": "someUser@domain.com",
        "type": "singleUser"
    },
    {
      "reference": "Global Administrator",
      "type": "roleMembers"
    },
    {
      "reference": "Some group",
      "type": "groupMembers"
    }
  ]
}
```