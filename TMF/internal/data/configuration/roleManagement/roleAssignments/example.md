# Example roleAssignments.json

# Eligible role assignment for a group on the owner role on subscription level with endTime
```json
{
    "present": true,
    "type": "eligible",
    "principalReference": "Some group",
    "principalType": "group",
    "roleReference": "Owner",
    "subscriptionReference": "Subscription name",
    "scopeReference": "Subscription name",
    "scopeType": "subscription",
    "startDateTime": "2022-03-30T00:00:00.00Z",
    "expirationType": "AfterDateTime",
    "endDateTime": "2023-03-30T00:00:00.00Z"
}
```

# Eligible role assignment for a user on the owner role on resourceGroup level with endTime

```json
{
    "present": true,
    "type": "eligible",
    "principalReference": "userprincipalname",
    "principalType": "user",
    "roleReference": "Owner",
    "subscriptionReference": "Subscription name",
    "scopeReference": "resourceGroup name",
    "scopeType": "resourceGroup",
    "startDateTime": "2022-03-30T00:00:00.00Z",
    "expirationType": "AfterDateTime",
    "endDateTime": "2023-03-30T00:00:00.00Z"
}
```

# Active role assignment for a group on the owner role on subscription level with no Expiration
```json
{
    "present": true,
    "type": "active",
    "principalReference": "Some group",
    "principalType": "group",
    "roleReference": "Owner",
    "subscriptionReference": "Subscription name",
    "scopeReference": "Subscription name",
    "scopeType": "subscription",
    "startDateTime": "2022-03-30T00:00:00.00Z",
    "expirationType": "noExpiration"
}
```

### Add an eligible role assignment on subscription level with expiration by duration
```json
{
    "present": "true",
    "type": "eligible",
    "principalReference": "some name",
    "principalType": "group",
    "roleReference": "some role name",
    "subscriptionReference": "subscription name",
    "scopeReference": "subscription name",
    "scopeType": "subscription",
    "startDateTime": "2022-03-24T00:00:00.00Z",
    "expirationType": "AfterDuration",
    "endDateTime": null,
    "duration": "P365D"
}
```

# Eligible role assignment for a group on a directory role with no expiration
```json
{
    "present": true,
    "type": "eligible",
    "principalReference": "Group name",
    "principalType": "group",
    "roleReference": "directory role name",
    "directoryScopeReference": "/",
    "directoryScopeType": "directory",
    "startDateTime": "2022-04-28T00:00:00.00Z",
    "expirationType": "noExpiration"
}
```

# Active role assignment for a user on a directory role with endTime
```json
{
    "present": true,
    "type": "active",
    "principalReference": "userprincipalname",
    "principalType": "user",
    "roleReference": "directory role name",
    "directoryScopeReference": "/",
    "directoryScopeType": "directory",
    "startDateTime": "2022-04-28T00:00:00.00Z",
    "expirationType": "AfterDateTime",
    "endDateTime": "2023-03-30T00:00:00.00Z"
}
```

# Eligible role assignment for a group on an administrativeUnit with no expiration
```json
{
    "present": true,
    "type": "eligible",
    "principalReference": "Group name",
    "principalType": "group",
    "roleReference": "directory role name",
    "directoryScopeReference": "name of administrativeUnit",
    "directoryScopeType": "administrativeUnit",
    "startDateTime": "2022-04-28T00:00:00.00Z",
    "expirationType": "noExpiration"
}
```

# Eligible member role assignment on a privileged access group for a group with no expiration
```json
{
    "present": true,
    "type": "eligible",
    "principalReference": "Group name",
    "principalType": "group",
    "roleReference": "member",
    "groupReference": "name of privileged access group",
    "directoryScopeType": "group",
    "startDateTime": "2022-04-28T00:00:00.00Z",
    "expirationType": "noExpiration"
}
```

# Eligible owner role assignment on a privileged access group for a user with AfterDuration expiration of 180 days
```json
{
    "present": true,
    "type": "eligible",
    "principalReference": "userprincipalname",
    "principalType": "user",
    "roleReference": "owner",
    "groupReference": "name of privileged access group",
    "directoryScopeType": "group",
    "startDateTime": "2022-04-28T00:00:00.00Z",
    "duration": "P180D",
    "expirationType": "AfterDuration"
}
```

# Active member role assignment on a privileged access group for a serviceprincipal with AfterDateTime expiration
```json
{
    "present": true,
    "type": "active",
    "principalReference": "serviceprincipalname",
    "principalType": "servicePrincipal",
    "roleReference": "member",
    "groupReference": "name of privileged access group",
    "directoryScopeType": "group",
    "startDateTime": "2022-04-28T00:00:00.00Z",
    "endDateTime": "2022-12-31T00:00:00.00Z",
    "expirationType": "AfterDateTime"
}
```