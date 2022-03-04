# Example agreement.json

### An agreement with a single file
```json
{
  "displayName": "An example agreement with a single files",
  "isViewingBeforeAcceptanceRequired": true,
  "isPerDeviceAcceptanceRequired": false,
  "userReacceptRequiredFrequency": "P90D",
  "termsExpiration": {
    "startDateTime": "2014-01-01T00:00:00Z",
    "frequency": "PT1M"
  },
  "files": [
    {
      "fileName": "Example Terms of Use.pdf",
      "language": "en",
      "isDefault": true,
      "filePath": "files/Example Terms of Use.pdf"
    }
  ],
  "present": true
}
```

### Agreement with multiple files
```json
{
  "displayName": "An example agreement with multiple files",
  "isViewingBeforeAcceptanceRequired": true,
  "isPerDeviceAcceptanceRequired": false,
  "userReacceptRequiredFrequency": "P90D",
  "files": [
    {
      "fileName": "Example Terms of Use.pdf",
      "language": "en",
      "isDefault": true,
      "filePath": "files/Example Terms of Use.pdf"
    },
    {
      "fileName": "Example Terms of Use.pdf",
      "language": "de",
      "isDefault": false,
      "filePath": "files/Example Terms of Use.pdf"
    }
  ],
  "present": true
}
```

### Microsoft Graph resource types and documents
https://docs.microsoft.com/en-us/graph/api/resources/agreement?view=graph-rest-beta