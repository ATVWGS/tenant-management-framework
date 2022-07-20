# Example authenticationMethodsPolicies.json

# Only one authenticationMethodsPolicy exists within the tenant, so only one configuration can exist!

```json
[
	{
		"displayName": "Authentication Methods Policy",
		"registrationEnforcement": {
			"authenticationMethodsRegistrationCampaign": {
				"snoozeDurationInDays": 1,
				"state": "default",
				"excludeTargets": [],
				"includeTargets": [
					{
						"id": "all_users",
						"targetType": "group",
						"targetedAuthenticationMethod": "microsoftAuthenticator"
					}
				]
			}
		},
		"authenticationMethodConfigurations": [
		
			{
				"id": "Fido2",
				"state": "disabled",
				"isSelfServiceRegistrationAllowed": true,
				"isAttestationEnforced": true
			},
			{
				"id": "MicrosoftAuthenticator",
				"state": "disabled"
			},
			{
				"id": "Sms",
				"state": "disabled"
			},
			{
				"id": "TemporaryAccessPass",
				"state": "disabled",
				"defaultLifetimeInMinutes": 60,
				"defaultLength": 8,
				"minimumLifetimeInMinutes": 60,
				"maximumLifetimeInMinutes": 480,
				"isUsableOnce": false
			},
			{
				"id": "Email",
				"state": "enabled",
				"allowExternalIdToUseEmailOtp": "enabled"
			},
			{
				"id": "X509Certificate",
				"state": "disabled",
				"certificateUserBindings": [
					{
						"x509CertificateField": "PrincipalName",
						"userProperty": "onPremisesUserPrincipalName",
						"priority": 1
					},
					{
						"x509CertificateField": "RFC822Name",
						"userProperty": "userPrincipalName",
						"priority": 2
					}
				],
				"authenticationModeConfiguration": {
					"x509CertificateAuthenticationDefaultMode": "x509CertificateSingleFactor",
					"rules": []
				}
			}
		]
	}
]
```