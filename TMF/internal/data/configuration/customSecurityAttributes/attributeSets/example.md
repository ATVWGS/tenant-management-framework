```json
{    
    "displayName": "AttributeSetForTest",
    "description": "Attribute set for testing",
    "maxAttributesPerSet": 25,
    "present": true
}
```
The displayname may not include special characters or spaces, because it is used as id for the resource! 
Max length of the displayname is 32, max length of description is 128. maxAttributesPerSet may not exceed 100.
(https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/custom-security-attributes-overview#limits-and-constraints)