# resolveFunctions
Functions to resolve the ObjectIds of different Azure AD resources.
Thos functions take an input reference and search for the objects in the Tenant.

The default properties you can resolve a resource with are _displayName_ and _id_.

### Example
Searches for a group with the name _Some group_.
```powershell
Resolve-Group -InputReference "Some group"
```

Searches for a group with the mailNickname _somegroup@tenant.onmicrosoft.com_.
```powershell
Resolve-Group -InputReference "somegroup@tenant.onmicrosoft.com"
```