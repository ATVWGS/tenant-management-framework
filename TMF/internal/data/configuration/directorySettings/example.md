# Example for directory setting "Application"
```json
{
    "displayName": "Application",
    "present": true,
    "EnableAccessCheckForPrivilegedApplicationUpdates": true
}
```

# Example for directory setting "Password Rule Settings" with disabled onPrem settings
```json
{
    "displayName": "Password Rule Settings",
    "present": true,
    "BannedPasswordCheckOnPremisesMode": "Audit|Enforced",
    "EnableBannedPasswordCheckOnPremises": false,
    "EnableBannedPasswordCheck": true,
    "LockoutDurationInSeconds": 60,
    "LockoutThreshold": 5,
    "BannedPasswordList": "password"
}
```

# Example for directory setting "Group.Unified"
```json
{
    "displayName": "Group.Unified",
    "present": true,
    "NewUnifiedGroupWritebackDefault": true,
    "EnableMIPLabels": true,
    "CustomBlockedWordsList": "word1,word2",
    "EnableMSStandardBlockedWords": false,
    "ClassificationDescriptions": "Public:Information with no restrictions,Internal:Information that is intended for internal use only and not for the general public",
    "DefaultClassification": "Internal",
    "PrefixSuffixNamingRequirement": "[pre][suffix]",
    "AllowGuestsToBeGroupOwner": false,
    "AllowGuestsToAccessGroups": true,
    "GuestUsageGuidelinesUrl": "https://someUrl.com",
    "GroupCreationAllowedGroupId": "",
    "AllowToAddGuests": true,
    "UsageGuidelinesUrl": "https://someUrl.com",
    "ClassificationList": "Internal,Public",
    "EnableGroupCreation": true
}
```

# Example for directory setting "Prohibited Names Settings"
```json
{
    "displayName": "Prohibited Names Settings",
    "present": true,
    "CustomBlockedSubStringsList": "substring1,substring2",
    "CustomBlockedWholeWordsList": "word1,word2"
}
```

# Example for directory setting "Custom Policy Settings"
```json
{
    "displayName": "Custom Policy Settings",
    "present": true,
    "CustomConditionalAccessPolicyUrl": "https://someUrl.com"
}
```

# Example for directory setting "Consent Policy Settings"
```json
{
    "displayName": "Consent Policy Settings",
    "present": true,
    "BlockUserConsentForRiskyApps": true,
    "EnableAdminConsentRequests": false
}
```