# Example authorizationPolicies.json

# Only one authorizationPolicy exists within the tenant, so only one configuration can exist!

# Possible values for "allowInvitesFrom" are: none, adminsAndGuestInviters, adminsGuestInvitersAndAllMembers, everyone
# Possible values for "guestUserRole" are: User, Guest User, Restricted Guest User
# Refer to https://docs.microsoft.com/en-us/graph/api/resources/authorizationpolicy?view=graph-rest-1.0

```json

[
	{
		"displayName": "Authorization Policy",
        "allowInvitesFrom": "adminsAndGuestInviters",
        "allowedToSignUpEmailBasedSubscriptions": false,
        "allowedToUseSSPR": true,
        "allowEmailVerifiedUsersToJoinOrganization": false,
        "blockMsolPowerShell": false,
        "guestUserRole": "Guest User",
        "allowedToCreateApps": false,
        "allowedToCreateSecurityGroups": false,
        "allowedToReadOtherUsers": true,
		"allowedToReadBitlockerKeysForOwnedDevice": true,
        "permissionGrantPolicyIdsAssignedToDefaultUserRole": []
	}
]

```