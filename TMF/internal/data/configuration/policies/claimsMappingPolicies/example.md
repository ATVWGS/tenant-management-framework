# Example for claimsMappingPolicy

```json
{
    "present": true,
    "displayName": "AddOnPremisesSamAccountNameToToken",
    "isOrganizationDefault": false,
    "definition": [
      "{\n    \"ClaimsMappingPolicy\": {\n        \"Version\": 1,\n        \"IncludeBasicClaimSet\": \"true\",\n        \"ClaimsSchema\": [\n            {\n                \"Source\": \"user\",\n                \"ID\": \"onpremisessamaccountname\",\n                \"JwtClaimType\": \"samAccountName\"\n            }\n        ]\n    }\n}"
    ],
    "appliesTo": [
        "TestApp1"
    ]
}
```