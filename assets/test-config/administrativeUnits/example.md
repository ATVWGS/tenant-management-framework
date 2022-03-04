# Example policies.json
Additional properties will be added in the future.

### Administrative roles for use in administrative units
- Authentication administrator  - Has access to view, set, and reset authentication method information for any non-admin user.
- Groups administrator          - Can manage all aspects of groups and group settings like naming and expiration policies.
- Helpdesk administrator        - Can reset passwords for non-administrators and Helpdesk administrators.
- License administrator         - Ability to assign, remove and update license assignments.
- Password administrator        - Can reset passwords for non-administrators and Password administrators.
- User administrator            - Can manage all aspects of users and groups, including resetting passwords for limited admins.

## Create administrative unit
### Example with possible settings, when visibility not defined the standard "public" is used. Other option is "HiddenMembership"
When set to "HiddenMembership", only members of the administrative unit can list other members of the administrative unit. For best performance you shouldn't include existing values that haven't changed.
```json
{
  "displayName": "provide display Name",
  "description": "provide description",
  "visibility": "Public or HiddenMembership",
  "present": true
}
```

## Create administrative unit with members
- Members can be users or groups
- To remove all groups or members, simply write an empty array e.g. "groups": []

```json
{
  "displayName": "provide display Name",
  "description": "provide description",
  "visibility": "Public or HiddenMembership",
  "members": ["User 1","User 2"],
  "groups": ["Group 1", "Group 2"],
  "present": true
}
```

## Create administrative unit with members, groups and scoped role Membership (Users with administrative roles)

```json
{
  "displayName": "provide display Name",
  "description": "provide description",
  "visibility": "Public or HiddenMembership",
  "members": ["User 1","User 2"],
  "groups": ["Group 1", "Group 2"],
  "scopedRoleMembers": [
    {
      "role": "Groups Administrator",
      "identity": "Max Mustermann"
    },
    {
      "role": "User Administrator",
      "identity": "Max Mustermann"
    }
  ],
  "present": true
}
```
## Microsoft Graph resource types and documents
https://docs.microsoft.com/de-de/graph/api/resources/administrativeunit?view=graph-rest-1.0
https://4sysops.com/archives/an-introduction-to-azure-ad-administrative-units/