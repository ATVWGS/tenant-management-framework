# The following types are supported by now: onTokenIssuanceStartCustomExtension, onTokenIssuanceStartCustomExtension, onAttributeCollectionSubmitCustomExtension, onPasswordSubmitCustomExtension
# Example customAuthenticationExtension type: onTokenIssuanceStartCustomExtension

```json
{
  "present": false,
  "@odata.type": "#microsoft.graph.onTokenIssuanceStartCustomExtension",
  "displayName": "onTokenIssuanceStartCustomExtension",
  "description": "description",
  "authenticationConfiguration": {
    "resourceId": "api://{FQDN}/{appID}",
    "@odata.type": "#microsoft.graph.azureAdTokenAuthentication"
  },
  "endpointConfiguration": {
    "targetUrl": "https://{endpointURL}",
    "@odata.type": "#microsoft.graph.httpRequestEndpoint"
  },
  "clientConfiguration": {
    "timeoutInMilliseconds": 2000,
    "maximumRetries": 1
  },
  "claimsForTokenConfiguration": [
    {
      "claimIdInApiResponse": "property1"
    },
    {
      "claimIdInApiResponse": "property2"
    }
  ]
}
```
# Example customAuthenticationExtension type: onAttributeCollectionStartCustomExtension
```json
{
  "present": true,
  "@odata.type": "#microsoft.graph.onAttributeCollectionStartCustomExtension",
  "displayName": "onAttributeCollectionStartCustomExtension",
  "description": "description",
  "authenticationConfiguration": {
    "resourceId": "api://{FQDN}/{appID}",
    "@odata.type": "#microsoft.graph.azureAdTokenAuthentication"
  },
  "endpointConfiguration": {
    "targetUrl": "https://{endpointURL}",
    "@odata.type": "#microsoft.graph.httpRequestEndpoint"
  },
  "clientConfiguration": {
    "timeoutInMilliseconds": 2000,
    "maximumRetries": 1
  }
}
```

# Example customAuthenticationExtension type: onAttributeCollectionSubmitCustomExtension
```json
{
  "present": true,
  "@odata.type": "#microsoft.graph.onAttributeCollectionSubmitCustomExtension",
  "displayName": "onAttributeCollectionSubmitCustomExtension",
  "oldNames": ["onAttributeCollectionSubmitCustomExtensionOldName"],
  "description": "description",
  "authenticationConfiguration": {
    "resourceId": "api://{FQDN}/{appID}",
    "@odata.type": "#microsoft.graph.azureAdTokenAuthentication"
  },
  "endpointConfiguration": {
    "targetUrl": "https://{endpointURL}",
    "@odata.type": "#microsoft.graph.httpRequestEndpoint"
  },
  "clientConfiguration": {
    "timeoutInMilliseconds": 2000,
    "maximumRetries": 1
  }
}
```

# Example customAuthenticationExtension type: onPasswordSubmitCustomExtension
```json
{
  "present": true,
  "@odata.type": "#microsoft.graph.onPasswordSubmitCustomExtension",
  "displayName": "onPasswordSubmitCustomExtension",
  "description": "description",
  "authenticationConfiguration": {
    "resourceId": "api://{FQDN}/{appID}",
    "@odata.type": "#microsoft.graph.azureAdTokenAuthentication"
  },
  "endpointConfiguration": {
    "targetUrl": "https://{endpointURL}",
    "@odata.type": "#microsoft.graph.httpRequestEndpoint"
  },
  "clientConfiguration": {
    "timeoutInMilliseconds": 2000,
    "maximumRetries": 1
  }
}
```