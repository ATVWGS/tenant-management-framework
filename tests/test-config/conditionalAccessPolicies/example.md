# Example policies.json
Additional properties will be added in the future.

### Example with possible settings
```json
{
    "displayName" : "Require MFA and ToU for all members of Some group",
    "excludeGroups": ["Some group"],
    "excludeRoles": [],
    "excludeUsers": ["max.mustermann@volkswagen.de"],
    "includeGroups": [],
    "includeRoles": [],
    "includeUsers": ["All"],
    "includeApplications": ["All"],
    "excludeLocations": [],
    "includeLocations": ["All"],
    "clientAppTypes": ["browser", "mobileAppsAndDesktopClients"],
    "includePlatforms": ["All"],
    "excludePlatforms": [],
    "signInRiskLevels": ["String"],
    "userRiskLevels": [""],
    "grantControls": {
        "builtInControls": [],
        "customAuthenticationFactors": [],
        "operator": "",
        "termsOfUse": []
    },
    "sessionControls": {
        "applicationEnforcedRestrictions": null,
        "persistentBrowser": null,
        "cloudAppSecurity": {
            "cloudAppSecurityType": "blockDownloads",
            "isEnabled": true
        },
        "signInFrequency": {
            "value": 4,
            "type": "hours",
            "isEnabled": true
        }
    },    
    "state" : "enabledForReportingButNotEnforced",
    "present" : true
}
```

# Policy that affects all members of a group to accept ToU and and provide MFA
```json
{
    "displayName" : "Require MFA and ToU for all members of Some group",
    "excludeGroups": ["Some group for CA"],
    "excludeUsers": ["johannes.seitle@tmacdev.onmicrosoft.com"],        
    "includeApplications": ["All"],        
    "includeLocations": ["All"],
    "clientAppTypes": ["browser", "mobileAppsAndDesktopClients"],
    "includePlatforms": ["All"],
    "grantControls": {
        "builtInControls": ["mfa"],
        "operator": "AND",
        "termsOfUse": ["ToU for Some group"]
    },
    "state" : "enabledForReportingButNotEnforced",
    "present" : false
}
```

### Microsoft Graph resource types and documents
conditionalAccessPolicy resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccesspolicy?view=graph-rest-1.0
conditionalAccessConditionSet resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccessconditionset?view=graph-rest-1.0
conditionalAccessDevices resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccessdevices?view=graph-rest-beta
conditionalAccessLocations resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccesslocations?view=graph-rest-1.0
conditionalAccessPlatforms resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccessplatforms?view=graph-rest-1.0
conditionalAccessApplications resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccessapplications?view=graph-rest-1.0
conditionalAccessUsers resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccessusers?view=graph-rest-1.0
conditionalAccessGrantControls resource type https://docs.microsoft.com/de-de/graph/api/resources/conditionalaccessgrantcontrols?view=graph-rest-1.0