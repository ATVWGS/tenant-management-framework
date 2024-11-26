![Logo](./assets/images/logo.png)

Tenant Management Framework <!-- omit in toc -->
===========================

![GitHub](https://img.shields.io/github/license/ATVWGS/tenant-management-framework)
[![TMF](https://img.shields.io/powershellgallery/v/TMF.svg?label=TMF)](https://www.powershellgallery.com/packages/TMF/)

# 1. Introduction 
The Tenant Management Framework is a Powershell module that is able to create, update and
delete resources or settings via the Microsoft Graph API. The module provides simple
Powershell cmdlets to deploy and manage a set of predefined configuration files. The basic idea is
based on the [Active Directory Management Framework](https://admf.one).

![Showcase](./assets/images/showcase.gif)

## 1.1. Goals
- Deliver a PowershellModule with standardized
commands to deploy Tenant configurations
- Provide a default configuration file format that is easy
to read and to manage
- Give the administrators pre-build configurations with
best practices
- Enable administrators to create a reusable tenant
configurations

## 1.2. Benefits
- Reproducable configuration
- Easy readable, storable and shareable configurations
- Enforced change documentation and versioning by adding a source control
- Enables staging concept
- Less prone to human error
- Increased efficiency

# 2. Getting started
## 2.1. Installation
Checkout the [Powershell Gallery](https://www.powershellgallery.com/packages/TMF/)!

## 2.2. Importing
You can simply import the module using *Import-Module TMF* if the module has been placed in one of your module directory. (Checkout $env:PSModulePath)
It is also possible to directly import the module using *Import-Module <PATH_TO_MODULE>/TMF/TMF.psd1*

## 2.3. Authentication
We are using the Microsoft.Graph module to make changes in the targeted Azure AD Tenant. This module also has a sub-module for authentication against Microsoft Graph. You can connect using the following command.
```powershell
PS> Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"
```
https://github.com/microsoftgraph/msgraph-sdk-powershell

Please make sure you are connected to the correct Tenant before invoking configurations! 

The required scopes depend on what components (resources) you want to configure.

| Resource                                                         | Required scopes                                                                                                              |
|------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| AccessReviews													   | AccessReview.ReadWrite.All																									  |
| AdministrativeUnits                                             | AdministrativeUnit.ReadWrite.All, Directory.AccessAsUser.All, RoleManagement.ReadWrite.Directory                             |
| Agreements (Terms of Use)                                        | Agreement.ReadWrite.All                                                                                                      |
| AuthenticationContextClassReferences                             | AuthenticationContext.ReadWrite.All, Policy.ReadWrite.ConditionalAccess													  |
| ConditionalAccessPolicies                                      | Policy.ReadWrite.ConditionalAccess, Policy.Read.All, RoleManagement.Read.Directory, Application.Read.All, Agreement.Read.All |
| CrossTenantAccess (policy, defaultSettings, partnerSettings)     | Policy.ReadWrite.CrossTenantAccess   																						  |
| CustomSecurityAttributes                                       | CustomSecAttributeDefinition.ReadWrite.All                                                                                   |
| DirectoryRoles												   | RoleManagement.ReadWrite.Directory                                                                                           |
| DirectorySettings											   | Directory.ReadWrite.All																									  |
| EntitlementManagement (Access Packages, Access Package Catalogs)| EntitlementManagement.ReadWrite.All                                                                                          |
| Groups                                                           | Group.ReadWrite.All, GroupMember.ReadWrite.All                                                                               |
| NamedLocations                                                  | Policy.ReadWrite.ConditionalAccess                                                                                           |
| OrganizationalBrandings										   | OrganizationalBranding.ReadWrite.All, Organization.ReadWrite.All															  |
| Policies (authentication/authorization policies)                 | Policy.ReadWrite.AuthenticationMethod, Policy.ReadWrite.Authorization, Policy.ReadWrite.AuthenticationFlows                  |
| RoleManagement (assignments, definitions, management policies)  | RoleManagement.ReadWrite.Directory, Directory.AccessAsUser.All, RoleEligibilitySchedule.ReadWrite.Directory,                 |
|                                                                  | RoleAssignmentSchedule.ReadWrite.Directory, RoleManagementPolicy.ReadWrite.Directory                                      |
| Users                                                            | User.ReadWrite.All                                                                                                           |


You can also use *Get-TmfRequiredScope* to get the required scopes and combine it with *Connect-MgGraph*.
```powershell
PS> Connect-MgGraph -Scopes (Get-TmfRequiredScope -All)
PS> Connect-MgGraph -Scopes (Get-TmfRequiredScope -Groups -RoleManagement)
```

## 2.4. Configurations
A Tenant Management Framework configuration is a collection of resource definition files in a predefined folder structure. The definition files describe instances of different resource types (eg. Groups, Conditional Access Policies, Named Locations) in the [JavaScript Object Notation (.json)](https://de.wikipedia.org/wiki/JavaScript_Object_Notation). 

### 2.4.1. configuration.json
Configurations always contain a *configuration.json* file at the root level. This file contains the properties that describe a configuration and is automatically created when using [*New-TmfConfiguration*](#323-how-can-i-create-a-configuration).

```json
{
    "Name":  "Example Configuration",
    "Description":  "This is a example configuration.",
    "Author":  "Mustermann, Max",
    "Weight":  50,
    "Prerequisite":  [
                        "Default Configuration"
                     ]
}
```

| Property     | Description                                                                      
|--------------|----------------------------------------------------------------------------------
| Name         | The name of the configuration. Must be uniqe when using multiple configurations.
| Description  | Description of the configuration. Here you can discribe, for which tenants this configurations should be used.
| Author       | The responsible team or person for this configuration.
| Weight       | When activating multiple configurations, the configuration with the highest weight is loaded last. This means that a resource definition will be overwriten, if the last configuration contains a definition with the same displayName.
| Prerequisite | With this setting you can define a relationship to an another configuration by the configuration name. For example when a configurations requires a baseline configuration. It is also possible to allow different configurations as prerequisite using an OR-operator. This can be helpful when the target tenants are slightly different. For example: TenantConfig1 || TenantConfig2 || TenantConfig3

#### 2.4.1.1. Prerequisite OR-operator example

```json
{
    "Name":  "Example Configuration",
    "Description":  "This is a example configuration.",
    "Author":  "Mustermann, Max",
    "Weight":  50,
    "Prerequisite":  [
                        "Default_Config",
                        "DEV_Tenant_Config || QA_Tenant_Config || PROD_Tenant_Config"
                     ]
}
```

### 2.4.2. Folder structure
For each supported resource type there is a subfolder. These subfolders always contain an empty .json file and example.md. 

The empty *.json* file is used to define resource instances. As an example a resource instance can be the definition of an Azure AD Security group or a Conditional Access policy. You can place multiple *.json* in a single resource type subfolder. By creating multiple *.json* files it is possible to structure resource definitions in a understandable way.

 **The folder names are mandatory for the functionality of the framework! Folders that do not represent a supported resource type will be ignored!**

The *example.md* file contains example resource instances and further information.


```markdown
# Folder structure of a newly created configuration
├───accessReviews
│       accessReviews.json
│       example.md
│
├───administrativeUnits
│       administrativeUnits.json
│       example.md
│
├───agreements
│   │   agreements.json
│   │   example.md
│   │
│   └───files
│           Example Terms of Use.pdf
│
├───authenticationContextClassReferences
│       authenticationContextClassReferences.json
│       example.md
│
├───conditionalAccessPolicies
│       example.md
│       policies.json
│
├───crossTenantAccess
│   ├───crossTenantAccessDefaultSettings
│   │       crossTenantAccessDefaultSettings.json
│   │       example.md
│   │       
│   ├───crossTenantAccessPartnerSettings
│   │       crossTenantAccessPartnerSettings.json
│   │       example.md
│   │       
│   └───crossTenantAccessPolicy
│           crossTenantAccessPolicy.json
│           example.md
│
├───customSecurityAttributes
│   ├───attributeSets
│   │       attributeSets.json
│   │       example.md
│   │
│   └───customSecurityAttributeDefinitions
│           customSecurityAttributeDefinitions.json
│           example.md
|
├───directoryRoles
│       directoryRoles.json
│       example.md
│
├───directorySettings
│       directorySettings.json
│       example.md
│
├───entitlementManagement
│   ├───accessPackageCatalogs
│   │       accessPackageCatalogs.json
│   │       example.md
│   │
│   └───accessPackages
│           accessPackages.json
│           example.md
│
├───groups
│       example.md
│       groups.json
│
├───namedLocations
│       example.md
│       namedLocations.json
│
├───organizationalBrandings
│       example.md
│       organizationalBrandings.json
│
├───policies
│   ├───appManagementPolicies
│   │       appManagementPolicies.json
│   │       example.md
│   │
│   ├───authenticationFlowsPolicies
│   │       authenticationFlowsPolicies.json
│   │       example.md
│   │
│   ├───authenticationMethodsPolicies
│   │       authenticationMethodsPolicies.json
│   │       example.md
│   │
│   ├───authenticationStrengthPolicies
│   │       authenticationStrengthPolicies.json
│   │       example.md
│   │
│   ├───authorizationPolicies
│   │       authorizationPolicies.json
│   │       example.md
│   │
│   └───tenantAppManagementPolicy
│           tenantAppManagementPolicy.json
│           example.md
│
├───roleManagement
│   ├───roleAssignments
│   │       roleAssignments.json
│   │       example.md
│   │
│   ├───roleDefinitions
│   │       roleDefinitions.json
│   │       example.md
│   │
│   ├───roleManagementPolicies
│   │       roleManagementPolicies.json
│   │       example.md
│   │
│   └───roleManagementPolicyRuleTemplates
│           roleManagementPolicyRuleTemplates.json
│           example.md
│
├───stringMappings
│       stringMappings.json
│
└───users
        example.md
        users.json
```

### 2.4.3. How can I create a configuration?
You can create new configuration by simple using the function *New-TmfConfiguration*. This function will create the required folder structure and the *configuration.json* file in the given location.
```powershell
PS> New-TmfConfiguration -Name "Example Configuration" -Description "This is an example configuration for the Tenant Management Framework!" -Author "Mustermann, Max" -Weight 50 -OutPath "$env:USERPROFILE\Desktop\Example_Configuration" -Force

[16:02:04][New-TmfConfiguration] Creating configuration directory C:\Users\username\Desktop\Example_Configuration. [DONE]
[16:02:04][New-TmfConfiguration] Copying template structure to C:\Users\username\Desktop\Example_Configuration. [DONE]
[16:02:05][Activate-TmfConfiguration] Activating Example Configuration (C:\Users\username\Desktop\Example_Configuration\configuration.json). This configuration will be considered when applying Tenant configuration. [DONE]
[16:02:05][Activate-TmfConfiguration] Sorting all activated configurations by weight. [DONE]
[16:02:05][New-TmfConfiguration] Creation has finished! Have fun! [DONE]
```

The *-Force* paramter tells the functions to automatically create the target directory or overwrite a configuration at the target directory. In the example it would create the folder "Example_Configuration".

A newly created configuration will be automatically activated. This means when using *Load-TmfConfiguration* the defined resources are loaded from the *.json* files and can be directly invoked or tested against the connected tenant.

### 2.4.4. How can I activate or deactivate a configuration?
To invoke or test defined resources against a tenant, you need to activate the containing configuration at the beginning. This means that you have to tell the TMF which configurations you want it to consider in the next steps.

This activation can simply be done using *Activate-TmfConfiguration*.
```powershell
PS> Activate-TmfConfiguration "$env:USERPROFILE\Desktop\Example_Configuration" -Force

[16:10:46][Activate-TmfConfiguration] Activating Example Configuration (C:\Users\username\Desktop\Example_Configuration\configuration.json). This configuration will be considered when applying Tenant configuration. [DONE]
[16:10:46][Activate-TmfConfiguration] Sorting all activated configurations by weight. [DONE]
```

You can use *Get-TmfActiveConfiguration* to checkout all already activated configurations.
```powershell
PS> Get-TmfActiveConfiguration

Name         : Example Configuration
Path         : C:\Users\username\Desktop\Example_Configuration
Description  : This is an example configuration for the Tenant Management Framework!
Author       : Mustermann, Max
Weight       : 50
Prerequisite : {}
```

To deactivate a configuration use *Deactivate-TmfConfiguration*. After deactivating a configuration the TMF won't considere it in further steps.
```powershell
Deactivate-TmfConfiguration -Name "Example Configuration" # By name
Deactivate-TmfConfiguration -Path "$env:USERPROFILE\Desktop\Example_Configuration" # By path
Deactivate-TmfConfiguration -All # Or all activated configurations!


[16:18:08][Deactivate-TmfConfiguration] Deactivating Example Configuration. This configuration will not be considered when applying Tenant configuration. [DONE]
```

### 2.4.5. Storing configurations
We recommend you to store configurations in a git repository. By adding a source control system you get enforced documentation and versioning.
In our case we store multiple configurations (Default configuration, DEV configuration, QA configuration and so on) in a single Azure DevOps repository.

## 2.5. General functions
### 2.5.1. Load-TmfConfiguration - Load definition files from configurations
The *Load-TmfConfiguration* function checks all *.json* files from the activated configurations and registers them into a runtime store. Technically this is the same process as if you use a register function for a single resource type (eg. *Register-TmfGroup*). All loaded resource definitions are considered when using test or invoke functions.

```powershell
PS> Load-TmfConfiguration
```

### 2.5.2. Get-TmfDesiredConfiguration - Show the current desired configuration

You can check the currently loaded desired configuration with *Get-TmfDesiredConfiguration*. This returns the desired configuration as a hashtable.

```powershell
PS> Get-TmfDesiredConfiguration

Name                           Value
----                           -----
accessPackages                 {}
groups                         {@{displayName=Some group; description=This is a security group; groupTypes=System.String[]; securityEnabled=True; mailEnabled=False; mailNickname=someGroupForMembers; present=True... 
namedLocations                 {}
accessPackageCatalogs          {}
conditionalAccessPolicies      {}
agreements                     {}
stringMappings                 {}

# You can also checkout single resource definitions
PS> (Get-TmfDesiredConfiguration)["groups"]

displayName     : Some group
description     : This is a security group
groupTypes      : {}
securityEnabled : True
mailEnabled     : False
mailNickname    : someGroupForMembers
present         : True
sourceConfig    : Example Configuration
owners          : {group.owner@example.org}
members         : {max.mustermann@example.org}

# Filtering is also possible with Where-Object
(Get-TmfDesiredConfiguration)["groups"] | Where-Object {$_.displayName -eq "Some group"}

displayName     : Some group
description     : This is a security group
groupTypes      : {}
securityEnabled : True
mailEnabled     : False
mailNickname    : someGroupForMembers
present         : True
sourceConfig    : Example Configuration
owners          : {group.owner@example.org}
members         : {max.mustermann@example.org}
```

### 2.5.3. Test-Tmf* - Test definitions against Graph
It is possible to run tests for a single resource type, for an resouce type group (eg. Entitlement Management) or for a whole tenant.

If you want to only test your configured groups, you can use *Test-TmfGroup*. This will only consider all definitions of the resource type "groups".

```powershell
PS> Test-TmfGroup

ActionType           : Create
ResourceType         : Group
ResourceName         : Example group
Changes              :
Tenant               : TENANT_NAME
TenantId             : d369908f-8803-46bc-90cb-3c82854ddf93
DesiredConfiguration : @{displayName=Example group; description=This is an example security group; groupTypes=System.String[]; securityEnabled=True; mailEnabled=False; mailNickname=someGroupForMembers;
                       present=True; sourceConfig=Example Configuration}
GraphResource        :
```

The resource type specific test functions always return test result objects. These objects show you, which actions are required in your tenant, to achive the desired configuration.

Additionally you can test only specific resources of a resource type group by adding the -specificResources parameter. This parameter accepts a string array including wildcards.

```powershell
PS> Test-TmfGroup -specificResources "Example *"

ActionType           : Create
ResourceType         : Group
ResourceName         : Example group
Changes              :
Tenant               : TENANT_NAME
TenantId             : d369908f-8803-46bc-90cb-3c82854ddf93
DesiredConfiguration : @{displayName=Example group; description=This is an example security group; groupTypes=System.String[]; securityEnabled=True; mailEnabled=False; mailNickname=someGroupForMembers;
                       present=True; sourceConfig=Example Configuration}
GraphResource        :
```

You can test all available resource types using *Test-TmfTenant*. The *Test-TmfTenant* function and also all resource type group (eg. *Test-TmfEntitlementManagement*) functions automatically beautify the test results.

```powershell
PS> Test-TmfTenant

[20:35:51][Test-TmfTenant] Currently connected to <TENANT_NAME> (d369908f-XXXX-XXXX-90cb-3c82854ddf93)
[20:35:52][Test-TmfTenant] Starting tests for groups
[20:35:52][TMF] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (Create)
```

With *Beautify-TmfTestResult* you are able to beautify the results of any resouce type specific test command.

```powershell
PS> Test-TmfGroup | Beautify-TmfTestResult

[20:37:34][TMF] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (Create)
```

### 2.5.4. Invoke-Tmf* - Perform actions against Graph
The invoke functions are available for a single resource type, for a resouce type group (eg. Entitlement Management) or for the whole tenant. These functions are capable of creating, updating or deleting resources using Microsoft Graph. The executed actions depend on the results the test functions return.

Example based on Access Packages:
- *Invoke-TmfAccessPackage:* Only invokes actions for the defined Access Packages
- *Invoke-TmfEntitlementManagement:* Invokes the required actions for Access Packages and also for all other resource types required for Entitlement Management.
- *Invoke-TmfTenant*: Invokes the required actions for each resource type defined in your configurations.

```powershell
PS> Invoke-TmfGroup

[20:44:17][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (Create)
[20:44:17][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Completed.

PS> Invoke-TmfTenant

[20:49:46][Invoke-TmfTenant] Currently connected to TENANT_NAME (d369908f-8803-46bc-90cb-3c82854ddf93)
Is this the correct tenant? [y/n]: y
[20:49:48][Invoke-TmfTenant] Invoking groups
[20:49:49][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (NoActionRequired)
[20:49:49][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Completed.
```

Additionally you can invoke only specific resources of a resource type group by adding the -specificResources parameter. This parameter accepts a string array including wildcards.

```powershell
PS> Invoke-TmfGroup -specificResources "Example*"

[20:44:17][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (Create)
[20:44:17][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Completed.
```

### 2.5.5. Register-Tmf* - Add definitions temporarily
You can use the register functions to manually register a resource definition. When registering a resource definition it will be added to the desired configuration. 

A resource must be registered before the Tenant Management Framework can test it's configuration against the Tenant.

*The displayName property must be uniqe in the desired configuration!* Resources are searched by the displayName.


## 2.6. Resources types
The supported resources are based on the endpoints and resource types provided by [Microsoft Graph](https://developer.microsoft.com/en-us/graph).
Most of the definition files use the json syntax that the API endpoint also uses.

### 2.6.1. General properties
All main resource types support the following general properties.

| Name | Type | Use case | Not supported by |
|------|------|----------|------------------|
| displayName | string | Is the mainly used identifier of a resource. We are always using the displayName to search resources. | |
| oldNames | string[] | Allows you to rename a resource by searching it using an old name. **Example:** When group "Group A" should now be called "Group B", you can specify "Group A" in the oldNames property and set the displayName to "Group B". The TMF will update the displayName in the tenant automatically. | entitlementManagement (accessPackages, accessPackageCatalogs, accessPackageResource, accessPackageAssignmentPolicies) |
| present | bool | Is _true_ by default. If you set it to _false_, the resource is deleted. | |

### 2.6.2. Groups
An example definition for a simple Azure AD security group with a predefined member and a predefined owner.

```json
{   
    "displayName": "Some group",
    "description": "This is a security group",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someGroupForMembers",
    "members": ["max.mustermann@example.org"],
    "owners": ["group.owner@example.org"],
    "present": true
}
```

Please check the [Groups example.md](./TMF/internal/data/configuration/groups/example.md) for further information.

### 2.6.3. Conditional Access Policies
An example policy definition that would affect all members of a group to accept ToU and and provide MFA.

```json
{
    "displayName" : "Require MFA and ToU for all members of Some group",
    "excludeGroups": ["Some group for CA"],
    "excludeUsers": ["max.mustermann@TENANT_NAME.onmicrosoft.com"],        
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
    "present" : true
}
```

An example policy definition that would enable an authenticationStrengthPolicy for filtered apps.

```json
{
    "displayName" : "Require authentication strength for filtered apps",
    "excludeGroups": ["Some group for CA"],
    "excludeUsers": ["max.mustermann@TENANT_NAME.onmicrosoft.com"],        
    "includeLocations": ["All"],
    "applicationFilter": {
        "mode": "include",
        "rule": "CustomSecurityAttribute.TestSet2_TestAttribute2 -contains \"Value4\" -or CustomSecurityAttribute.TestSet2_TestAttribute3 -contains \"Value1\""
    },
    "clientAppTypes": ["All"],
    "includePlatforms": ["All"],
    "grantControls": {
        "authenticationStrength": "TestASP",
        "builtInControls": [],
        "operator": "OR"
    },
    "state" : "enabledForReportingButNotEnforced",
    "present" : true
}
```

Please check the [Conditional Access Policy example.md](./TMF/internal/data/configuration/conditionalAccessPolicies/example.md) for further information.

### 2.6.4. Named Locations
An example IP Named Location definition.

```json
{
    "type": "ipNamedLocation",
    "displayName": "Untrusted IP named location",
    "isTrusted": false,
    "ipRanges": [
        {
            "@odata.type": "#microsoft.graph.iPv4CidrRange",
            "cidrAddress": "12.34.221.11/22"
        },
        {
            "@odata.type": "#microsoft.graph.iPv6CidrRange",
            "cidrAddress": "2001:0:9d38:90d6:0:0:0:0/63"
        }
    ],
    "present": true
}
```

Please check the [Named Location example.md](./TMF/internal/data/configuration/namedLocations/example.md) for further information.

### 2.6.5. Agreements (Terms of Use)

An example Agreement definition with a single PDF file added.

```json
{
  "displayName": "An example agreement with a single files",
  "isViewingBeforeAcceptanceRequired": true,
  "isPerDeviceAcceptanceRequired": false,
  "userReacceptRequiredFrequency": "P90D",
  "termsExpiration": {
    "startDateTime": "05.03.2021 00:00:00",
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

Please check the [Agreements example.md](./TMF/internal/data/configuration/agreements/example.md) for further information.

### 2.6.6. Entitlement Management
Entitlement Management can be done by the following resource types. For further information about Azure AD Entitlement Management you can read the official documentation: https://docs.microsoft.com/en-us/azure/active-directory/governance/entitlement-management-overview.

#### 2.6.6.1. Access Package Catalogs
A simple Access Package Catalog definition.

```json
{    
    "displayName": "Access package catalog for testing",
    "description": "Sample access package catalog",
    "isExternallyVisible": false,
    "present": true
}
```

Please check the [Access Package Catalogs example.md](./TMF/internal/data/configuration/entitlementManagement/accessPackageCatalogs/example.md) for further information.

#### 2.6.6.2. Access Packages

```json
{	
    "displayName":  "Sample package",
    "oldNames": [],
    "description":  "This is a sample access package.",
    "isHidden":  false,
    "isRoleScopesVisible":  true,
    "catalog":  "Sample catalog",
    "present":  true,
    "accessPackageResources":  [
        {
            "originSystem":  "AadGroup",
            "resourceRole":  "Member",
            "resourceIdentifier":  "Some group"
        }
    ],
    "assignmentPolicies": [
        {
            "displayName": "Sample assignment policy",
            "description": "Access Package Assignment Policy has been created with Tenant Management Framework",
            "allowedTargetScope": "specificDirectoryUsers",
            "present": true,
            "specificAllowedTargets": [
                {
                    "reference": "Some group",
                    "type": "groupMembers",
                    "description": "Some group"
                }
            ],
            "expiration": {
                "endDateTime": null,
                "duration": "P90D",
                "type": "afterDuration"
            },
            "requestorSettings": {
                "enableTargetsToSelfAddAccess": true,
                "enableTargetsToSelfUpdateAccess": false,
                "enableTargetsToSelfRemoveAccess": true,
                "allowCustomAssignmentSchedule": true,
                "enableOnBehalfRequestorsToAddAccess": true,
                "enableOnBehalfRequestorsToUpdateAccess": false,
                "enableOnBehalfRequestorsToRemoveAccess": false,
                "onBehalfRequestors": []
            },
            "requestApprovalSettings": {
                "isApprovalRequiredForAdd": true,
                "isApprovalRequiredForUpdate": true,
                "stages": [
                    {
                        "durationBeforeAutomaticDenial": "P14D",
                        "isApproverJustificationRequired": true,
                        "isEscalationEnabled": false,
                        "durationBeforeEscalation": "P5D",
                        "primaryApprovers": [
                            {
                                "reference": "Some group",
                                "type": "groupMembers",
                                "description": "Some group"
                            }
                        ],
                        "fallbackPrimaryApprovers": [],
                        "escalationApprovers": [
                            {
                                "reference": "foo.bar@tenant.onmicrosoft.com",
                                "type": "singleUser"
                            }
                        ],
                        "fallbackEscalationApprovers": []
                    }
                ]
            },
            "reviewSettings": {
                "isEnabled": true,
                "expirationBehavior": "keepAccess",
                "isRecommendationEnabled": true,
                "isReviewerJustificationRequired": true,
                "isSelfReview": true,
                "schedule": {
                    "startDateTime": "2023-04-18T09:34:49.4485321Z",
                    "expiration": {
                        "endDateTime": null,
                        "duration": "P7D",
                        "type": "afterDuration"
                    },
                    "recurrence": {
                        "pattern": {
                            "type": "absoluteMonthly",
                            "interval": 1,
                            "month": 0,
                            "dayOfMonth": 0,
                            "daysOfWeek": [],
                            "firstDayOfWeek": null,
                            "index": null
                        },
                        "range": {
                            "type": "noEnd",
                            "numberOfOccurrences": 0,
                            "recurrenceTimeZone": null,
                            "startDate": null,
                            "endDate": null
                        }
                    }
                },
                "primaryReviewers": [
                    {
                        "reference": "Some group",
                        "type": "groupMembers",
                        "description": "Some group"
                    }                    
                ],
                "fallbackReviewers": []
            }
        }
    ]
}
```

Please check the [Access Packages example.md](./TMF/internal/data/configuration/entitlementManagement/accessPackages/example.md) for further information.

##### Access Package Resources <!-- omit in toc --> 
Access Package Resources are directly defined in the depending Access Package definition.

##### Access Package Assignment Policies <!-- omit in toc -->
Access Package Assignment Policies are directly defined the depending Access Package definition.

### 2.6.7. Administrative Units
A simple Administrative Unit definition.

```json
{
    "displayName": "Administrative Unit for Testing",
    "description": "This AU is used for testing",
    "visibility": "Public",
    "members": ["max.mustermann@tmacdev.onmicrosoft.com"],
    "groups": [],
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

Please check the [Administrative Units example.md](./TMF/internal/data/configuration/administrativeUnits/example.md) for further information.

### 2.6.8. Access Reviews

```json
{
    "displayName": "Displayname of the access review",
    "present": true,
    "scope": {
      "type": "group",
      "reference": "some group"
    },
    "reviewers": [
        {
            "type": "groupMembers",
            "reference":"some group"
        }
    ],
    "settings": {
        "mailNotificationsEnabled": true,
        "reminderNotificationsEnabled": true,
        "justificationRequiredOnApproval": true,
        "defaultDecisionEnabled": false,
        "defaultDecision": "None",
        "instanceDurationInDays": 14,
        "autoApplyDecisionsEnabled": false,
        "recommendationsEnabled": true,
        "recurrence": {
            "pattern": {
                "type": "absoluteMonthly",
                "interval": 3,
                "month": 0,
                "dayOfMonth": 0,
                "daysOfWeek": [],
                "firstDayOfWeek": "sunday",
                "index": "first"
            },
            "range": {
                "type": "noEnd",
                "numberOfOccurrences": 0,
                "recurrenceTimeZone": null,
                "startDate": "2022-03-01",
                "endDate": "9999-12-31"
            }
        }
    }
  }
```
Please check the [Access Reviews example.md](./TMF/internal/data/configuration/accessReviews/example.md) for further information.

### 2.6.9. Directory Roles

```json
{
    "present": true,
    "displayName": "Role displayname",
    "members": [
        {
            "type": "group",
            "reference": "some group"
        },
        {
            "type": "singleUser",
            "reference": "givenname.sn@tenant.onmicrosoft.com"
        }
    ]
}

```
Please check the [Directory Roles example.md](./TMF/internal/data/configuration/directoryRoles/example.md) for further information.


### 2.6.10. Policies

#### 2.6.10.1. authenticationFlowsPolicies

```json
[
	{
		"displayName": "Authentication flows policy",
		"selfServiceSignUpEnabled": false
	}
]
```
Please check the [.... example.md](./TMF/internal/data/configuration/policies/authenticationFlowsPolicies/example.md) for further information.


#### 2.6.10.2. authenticationMethodsPolicies

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
Please check the [.... example.md](./TMF/internal/data/configuration/policies/authenticationMethodsPolicies/example.md) for further information.


#### 2.6.10.3. authenticationStrengthPolicies

```json
[
    {
        "present": true,
        "displayName": "TestASP",
        "description": "Test Authentication Strength Policies",
        "allowedCombinations": [
            "deviceBasedPush"
        ]
    }
]
```

Please check the [.... example.md](./TMF/internal/data/configuration/policies/authenticationStrengthPolicies/example.md) for further information.

#### 2.6.10.4. authorizationPolicies

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
Please check the [.... example.md](./TMF/internal/data/configuration/policies/authorizationPolicies/example.md) for further information.

#### 2.6.10.5. appManagementPolicies

```json

[
	{
        "displayName": "appManagementPolicyTest",
        "description": "Test policy for appManagement",
        "isEnabled": true,
        "restrictions": {
            "passwordCredentials": [
                {
                    "restrictionType": "passwordAddition",
                    "maxLifetime": null,
                    "restrictForAppsCreatedAfterDateTime": "2023-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "passwordLifetime",
                    "maxLifetime": "P365D",
                    "restrictForAppsCreatedAfterDateTime": "2023-01-01T10:37:00Z"
                }
            ],
            "keyCredentials": [
                {
                    "restrictionType": "asymmetricKeyLifetime",
                    "maxLifetime": "P90D",
                    "restrictForAppsCreatedAfterDateTime": "2023-01-01T10:37:00Z"
                }
            ]
        },
        "appliesTo": [
            "application1",
            "application2"
        ],
        "present": true		
    }
]

```
Please check the [.... example.md](./TMF/internal/data/configuration/policies/appManagementPolicies/example.md) for further information.

#### 2.6.10.6. tenantAppManagementPolicies

```json
[
    {
        "displayname": "Default app management tenant policy",
        "description": "Default tenant policy that enforces app management restrictions on applications and service principals. To apply policy to targeted resources, create a new policy under appManagementPolicies collection.",
        "isEnabled": true,
        "applicationRestrictions": {
            "passwordCredentials": [
                {
                    "restrictionType": "passwordAddition",
                    "maxLifetime": null,
                    "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "passwordLifetime",
                    "maxLifetime": "P4DT12H30M5S",
                    "restrictForAppsCreatedAfterDateTime": "2017-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "symmetricKeyAddition",
                    "maxLifetime": null,
                    "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "customPasswordAddition",
                    "maxLifetime": null,
                    "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "symmetricKeyLifetime",
                    "maxLifetime": "P40D",
                    "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
                }
            ],
            "keyCredentials":[
                {
                    "restrictionType": "asymmetricKeyLifetime",
                    "maxLifetime": "P30D",
                    "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
                },
            ]
        },
        "servicePrincpialRestrictions": {
            "passwordCredentials": [
                {
                    "restrictionType": "passwordAddition",
                    "maxLifetime": null,
                    "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "passwordLifetime",
                    "maxLifetime": "P4DT12H30M5S",
                    "restrictForAppsCreatedAfterDateTime": "2017-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "symmetricKeyAddition",
                    "maxLifetime": null,
                    "restrictForAppsCreatedAfterDateTime": "2021-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "customPasswordAddition",
                    "maxLifetime": null,
                    "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
                },
                {
                    "restrictionType": "symmetricKeyLifetime",
                    "maxLifetime": "P40D",
                    "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
                }
            ],
            "keyCredentials":[
                {
                    "restrictionType": "asymmetricKeyLifetime",
                    "maxLifetime": "P30D",
                    "restrictForAppsCreatedAfterDateTime": "2015-01-01T10:37:00Z"
                },
            ]
        }
    }
]


```

### 2.6.11. roleManagement

#### 2.6.11.1. roleAssignments

##### Eligible role assignment for a group on a directory role with no expiration
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
##### Eligible role assignment for a group on an administrativeUnit with no expiration
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
##### Eligible role assignment for a group on the owner role on subscription level with endTime
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
Please check the [.... example.md](./TMF/internal/data/configuration/roleManagement/roleAssignments/example.md) for further information.


#### 2.6.11.2. roleDefinitions

##### Custom role definition for Azure Resources
```json

{
    "present": true,
    "displayName": "Some role name",
    "description": "Some description",
    "subscriptionReference": "Subscription name",
    "assignableScopes": [
        "/subscriptions/subscriptionID",
        "/subscriptions/subscriptionID/ResourceGroups/resourceGroupName"
    ],
    "permissions": [
        {
            "actions": [
                "Microsoft.Resources/subscriptions/resourceGroups/write",
                "Microsoft.Resources/subscriptions/resourceGroups/delete"
            ],
            "notActions": [],
            "dataActions": [],
            "notDataActions": []
        }
    ]
}
```
##### Custom role definition for EntraID
```json

{
    "present": true,
    "displayName": "Some role name",
    "description": "Some description",
    "rolePermissions": [
        {
            "allowedResourceActions": [
                "microsoft.directory/groups/standard/read",
                "microsoft.directory/groups/memberOf/read",
                "microsoft.directory/groups/members/read",
                "microsoft.directory/groups/owners/read"
            ],
            "condition": null
        }
    ]
}
```
Please check the [.... example.md](./TMF/internal/data/configuration/roleManagement/roleDefinitions/example.md) for further information.


#### 2.6.11.3. roleManagementPolicies

##### RoleManagementPolicy for directory role without approval
```json
{
    "roleReference": "directory role name",
    "activationApprover": [],
    "scopeReference": "/",
    "scopeType": "directory",
    "ruleTemplate": "some rule template"
}
```

##### RoleManagementPolicy for AzureResource role on subscription level with approver
```json
{
    "roleReference": "role name",
    "subscriptionReference": "subscription name",
    "scopeReference": "subscription name",
    "scopeType": "subscription",
    "activationApprover": [
        {
            "reference": "userPrincipalName",
            "type": "user"
        }
    ],
    "ruleTemplate": "some rule template"
}
```
Please check the [.... example.md](./TMF/internal/data/configuration/roleManagement/roleManagementPolicies/example.md) for further information.


#### 2.6.11.4. roleManagementPolicyRuleTemplates

roleManagementPolicyRuleTemplates include all rules but the "Approval_EndUser_Assignment". The approvers are set within the roleManagementPolicies configurations.

##### RoleManagementPolicy ruleset with maximum 9 months eligible assignment possible, permanent active assignment possible and activation duration of 12 hours
```json
{
    "displayName": "AzureAD_Tier0",
    "rules": [
      {
        "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
        "id": "Expiration_Admin_Eligibility",
        "isExpirationRequired": true,
        "maximumDuration": "P270D",
        "target": {
            "caller": "Admin",
            "operations": [
                "All"
            ],
            "level": "Eligibility",
            "inheritableSettings": [],
            "enforcedSettings": []
        }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_Admin_Eligibility",
          "enabledRules": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
          "id": "Expiration_Admin_Assignment",
          "isExpirationRequired": false,
          "maximumDuration": "P270D",
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_Admin_Assignment",
          "enabledRules": [
              "Justification"
          ],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
          "id": "Expiration_EndUser_Assignment",
          "isExpirationRequired": true,
          "maximumDuration": "PT12H",
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_EndUser_Assignment",
          "enabledRules": [
              "Justification"
          ],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyAuthenticationContextRule",
          "id": "AuthenticationContext_EndUser_Assignment",
          "isEnabled": false,
          "claimValue": null,
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      }
    ]
  }
  ```
Please check the [.... example.md](./TMF/internal/data/configuration/roleManagement/roleManagementPolicyRuleTemplates/example.md) for further information.

### 2.6.12 Custom security attributes

#### 2.6.12.1 attributeSets

```json
    {
		"displayName": "TestSet",
		"description": "Attribute set for testing",
		"maxAttributesPerSet": 3,
		"present": true
	}
```
Please check the [.... example.md](./TMF/internal/data/configuration/customSecurityAttributes/attributeSets/example.md) for further information.

#### 2.6.12.2 customSecurityAttributeDefinitions

```json
    {
        "attributeSet": "AttributeSetForTest",
        "displayName": "TestAttribute1",
        "description": "Test attribute 1",
        "isCollection": false,
        "isSearchable": true,
        "present": true,
        "status": "Available",
        "type": "String",
        "usePreDefinedValuesOnly": true,
        "allowedValues": [
            {
                "displayName": "Value1",
                "isActive": true
            },
            {
                "displayName": "Value2",
                "isActive": false
            }
        ]
    }
```
Please check the [.... example.md](./TMF/internal/data/configuration/customSecurityAttributes/customSecurityAttributDefinitions/example.md) for further information.

### 2.6.13. AuthenticationContextClassReferences

```json
[
    {
        "displayName": "authenticationContext example",
        "id": "c1",
        "description": "authenticationContext example",
        "isAvailable": true,
        "present": true
    }
]

```

Please check the [.... example.md](./TMF/internal/data/configuration/authenticationContextClassReferences/example.md) for further information.

### 2.6.14. CrossTenantAccess

#### 2.6.14.1 CrossTenantAccessDefaultSettings

```json
[
    {
        "displayName": "CrossTenantAccessDefaultSettings",
        "inboundTrust": {
            "isMfaAccepted": false,
            "isCompliantDeviceAccepted": false,
            "isHybridAzureADJoinedDeviceAccepted": false
        },
        "b2bCollaborationOutbound": {
            "usersAndGroups": {
                "accessType": "allowed",
                "targets": [
                    {
                        "target": "AllUsers",
                        "targetType": "user"
                    }
                ]
            },
            "applications": {
                "accessType": "allowed",
                "targets": [
                    {
                        "target": "AllApplications",
                        "targetType": "application"
                    }
                ]
            }
        },
        "b2bCollaborationInbound": {
            "usersAndGroups": {
                "accessType": "allowed",
                "targets": [
                    {
                        "target": "AllUsers",
                        "targetType": "user"
                    }
                ]
            },
            "applications": {
                "accessType": "allowed",
                "targets": [
                    {
                        "target": "AllApplications",
                        "targetType": "application"
                    }
                ]
            }
        },
        "b2bDirectConnectOutbound": {
            "usersAndGroups": {
                "accessType": "blocked",
                "targets": [
                    {
                        "target": "AllUsers",
                        "targetType": "user"
                    }
                ]
            },
            "applications": {
                "accessType": "blocked",
                "targets": [
                    {
                        "target": "AllApplications",
                        "targetType": "application"
                    }
                ]
            }
        },
        "b2bDirectConnectInbound": {
            "usersAndGroups": {
                "accessType": "blocked",
                "targets": [
                    {
                        "target": "AllUsers",
                        "targetType": "user"
                    }
                ]
            },
            "applications": {
                "accessType": "blocked",
                "targets": [
                    {
                        "target": "AllApplications",
                        "targetType": "application"
                    }
                ]
            }
        },
        "automaticUserConsentSettings": {
            "inboundAllowed": false,
            "outboundAllowed": false
        },
        "tenantRestrictions": {
            "devices": null,
            "usersAndGroups": {
                "accessType": "blocked",
                "targets": [
                    {
                        "target": "AllUsers",
                        "targetType": "user"
                    }
                ]
            },
            "applications": {
                "accessType": "blocked",
                "targets": [
                    {
                        "target": "AllApplications",
                        "targetType": "application"
                    }
                ]
            }
        },
        "invitationRedemptionIdentityProviderConfiguration": {
            "primaryIdentityProviderPrecedenceOrder": [
                "azureActiveDirectory",
                "externalFederation",
                "socialIdentityProviders"
            ],
            "fallbackIdentityProvider": "defaultConfiguredIdp"
        }
    }
]

```

Please check the [.... example.md](./TMF/internal/data/configuration/crossTenantAccess/crossTenantAccessDefaultSettings/example.md) for further information.

#### 2.6.14.2 CrossTenantAccessPartnerSettings

```json
[
    {
        "displayName": "tenantName",
        "tenantId": "tenantId",
        "present": true,
        "inboundTrust": {
            "isMfaAccepted": false,
            "isCompliantDeviceAccepted": true,
            "isHybridAzureADJoinedDeviceAccepted": false
        },
        "b2bCollaborationOutbound": null,
        "b2bCollaborationInbound": {
            "usersAndGroups": {
                "accessType": "allowed",
                "targets": [
                    {
                        "target": "some GroupID",
                        "targetType": "group"
                    }
                ]
            },
            "applications": {
                "accessType": "allowed",
                "targets": [
                    {
                        "target": "some ApplicationId",
                        "targetType": "application"
                    }
                ]
            }
        },
        "b2bDirectConnectOutbound": null,
        "b2bDirectConnectInbound": null,
        "tenantRestrictions": null,
        "invitationRedemptionIdentityProviderConfiguration": null,
        "automaticUserConsentSettings": {
            "inboundAllowed": null,
            "outboundAllowed": true
        }
    }
]

```

Please check the [.... example.md](./TMF/internal/data/configuration/crossTenantAccess/crossTenantAccessPartnerSettings/example.md) for further information.

#### 2.6.14.3. CrossTenantAccessPolicy

```json
[
    {
        "displayName": "CrossTenantAccessPolicy",
        "allowedCloudEndpoints": ["partner.microsoftonline.cn"]
    }
]

```

Please check the [.... example.md](./TMF/internal/data/configuration/crossTenantAccess/crossTenantAccessPolicy/example.md) for further information.

### 2.6.15. DirectoryRoles

```json
[
    {
        "present": true,
        "displayName": "Role displayname",
        "members": [
            {
                "type": "group",
                "reference": "some group"
            },
            {
                "type": "singleUser",
                "reference": "givenname.sn@tenant.onmicrosoft.com"
            }
        ]
    }
]

```

Please check the [.... example.md](./TMF/internal/data/configuration/directoryRoles/example.md) for further information.

### 2.6.16. DirectorySettings

#### Example for directory setting "Application"
```json
{
    "displayName": "Application",
    "present": true,
    "EnableAccessCheckForPrivilegedApplicationUpdates": true
}
```

#### Example for directory setting "Password Rule Settings" with disabled onPrem settings
```json
{
    "displayName": "Password Rule Settings",
    "present": true,
    "BannedPasswordCheckOnPremisesMode": "Audit|Enforced",
    "EnableBannedPasswordCheckOnPremises": false,
    "EnableBannedPasswordCheck": true,
    "LockoutDurationInSeconds": 60,
    "LockoutThreshold": 5,
    "BannedPasswordList": "password"
}
```

#### Example for directory setting "Group.Unified"
```json
{
    "displayName": "Group.Unified",
    "present": true,
    "NewUnifiedGroupWritebackDefault": true,
    "EnableMIPLabels": true,
    "CustomBlockedWordsList": "word1,word2",
    "EnableMSStandardBlockedWords": false,
    "ClassificationDescriptions": "Public:Information with no restrictions,Internal:Information that is intended for internal use only and not for the general public",
    "DefaultClassification": "Internal",
    "PrefixSuffixNamingRequirement": "[pre][suffix]",
    "AllowGuestsToBeGroupOwner": false,
    "AllowGuestsToAccessGroups": true,
    "GuestUsageGuidelinesUrl": "https://someUrl.com",
    "GroupCreationAllowedGroupId": "",
    "AllowToAddGuests": true,
    "UsageGuidelinesUrl": "https://someUrl.com",
    "ClassificationList": "Internal,Public",
    "EnableGroupCreation": true
}
```

#### Example for directory setting "Prohibited Names Settings"
```json
{
    "displayName": "Prohibited Names Settings",
    "present": true,
    "CustomBlockedSubStringsList": "substring1,substring2",
    "CustomBlockedWholeWordsList": "word1,word2"
}
```

#### Example for directory setting "Custom Policy Settings"
```json
{
    "displayName": "Custom Policy Settings",
    "present": true,
    "CustomConditionalAccessPolicyUrl": "https://someUrl.com"
}
```

#### Example for directory setting "Consent Policy Settings"
```json
{
    "displayName": "Consent Policy Settings",
    "present": true,
    "BlockUserConsentForRiskyApps": true,
    "EnableAdminConsentRequests": false
}
```

Please check the [.... example.md](./TMF/internal/data/configuration/directorySettings/example.md) for further information.

### 2.6.17. OrganizationalBrandings

##### Example for default organizational branding
```json
{
    "present": true,
    "displayName": "default",
    "backgroundColor": "#ffffff",
    "customAccountResetCredentialsUrl": "Your custom URL",
    "customCannotAccessYourAccountText": "Your custom text",
    "customCannotAccessYourAccountUrl": "Your custom URL",
    "customForgotMyPasswordText": "Your custom text",
    "customPrivacyAndCookiesText": "Your custom text",
    "customPrivacyAndCookiesUrl": "Your custom URL",
    "customResetItNowText": "Your custom text",
    "customTermsOfUseText": "Your custom text",
    "customTermsOfUseUrl": "Your custom URL",
    "headerBackgroundColor": "#000000",
    "signInPageText": "Your custom text",
    "usernameHintText": "Your custom text"
}
```
#### Example for localized organizational branding
```json
{
    "present": true,
    "displayName": "en-US",
    "backgroundColor": "#ffffff",
    "signInPageText": "Another custom sign in text",
    "usernameHintText": "Another custom username hint text"
}
```

Please check the [.... example.md](./TMF/internal/data/configuration/organizationalBrandings/example.md) for further information.

### 2.6.18. String mapping
String mappings can help you with parameterization of your TMF configurations.

You can create mappings between strings and the values they should be replaced with. Place the mappings in the *stringMappings.json* file in the *stringMappings* folder of your configuration.


| Property    | Description                                                                                |
|-------------|--------------------------------------------------------------------------------------------|
| name        | The name of the replacement string. Only digits (0-9) and letters (a-z A-Z) are allowed.   |
| replace     | The future value after replacing.                                                          |

```json
{
    "name": "GroupManagerName",
    "replace": "group.manager@example.org"
}
```

Currently not all resource properties are considered. All string properties on the first level are replaced. String mappings also work when resolving users (eg. group owners or members), groups (in CA policies), applications (in CA Policies), namedLocations (in CA policies), agreements (in CA policies), accessPackages, accessPackageCatalogs, accessPackageResources, accessPackageAssignmentPolicies.

| Resource       | Supported properties                                                                       |
|----------------|--------------------------------------------------------------------------------------------|
| agreements     | displayName, userReacceptRequiredFrequency                                                 |
| groups         | description, mailNickname, members, owners                                                 |
| namedLocations | displayName                                                                                |


To use the string mapping in a configuration file, you need to mention it by the name you provided in curly braces. Example: *{{ GroupManagerName }}*

```json
{   
    "displayName": "Some group",
    "description": "This is a security group. The group manager is {{ GroupManagerName }}",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someGroupForMembers",
    "members": ["max.mustermann@example.org"],
    "owners": ["group.owner@example.org"],
    "present": true
}
```

## 2.7. Examples
### 2.7.1. Example: A Conditional Access policy set and the required groups
First of all you need to create a new configuration using *New-TmfConfiguration*
```powershell
New-TmfConfiguration -Name "Simple Group Example" -Author "Mustermann, Max" -Weight 50 -OutPath "$env:USERPROFILE\Desktop\Simple_Group_Example" -Force
```
After that you need to add the definition for the include group into your configuration. We will include this group into our Conditional Access Policy. Just place the definition it into the *groups/groups.json* file in your newly created configuration.

The *groups.json* should now look like that.
```json
[
  {   
      "displayName": "Some group to include into Conditional Access",
      "description": "This is a simple security group", 
      "securityEnabled": true,
      "mailEnabled": false,
      "mailNickname": "someGroupForConditionalAccess",
      "present": true
  }
]
```
The same is possible for the exclude group. Just add an additional group definition.
```json
[
  {   
      "displayName": "Some group to include into Conditional Access",
      "description": "This is a simple security group", 
      "securityEnabled": true,
      "mailEnabled": false,
      "mailNickname": "someGroupIncludeConditionalAccess",
      "present": true
  },
  {   
      "displayName": "Some group to exclude from Conditional Access",
      "description": "This is a simple security group", 
      "securityEnabled": true,
      "mailEnabled": false,
      "mailNickname": "someGroupExcludeConditionalAccess",
      "present": true
  }
]
```
The required groups are now defined. Finally we can define our Conditional Access Policy. For this example we just want MFA required for all members of the group *Some group to include into Conditional Access*.

You can add the following example Conditional Access Policy definition to *conditionalAccessPolicies/policies.json*.

```json
{
    "displayName" : "An example Conditional Access Policy",
    "excludeGroups": ["Some group to include into Conditional Access"],
    "excludeGroups": ["Some group to exclude from Conditional Access"],        
    "includeApplications": ["All"],        
    "includeLocations": ["All"],
    "clientAppTypes": ["browser", "mobileAppsAndDesktopClients"],
    "includePlatforms": ["All"],
    "grantControls": {
        "builtInControls": ["mfa"],
        "operator": "AND"
    },
    "state" : "enabled",
    "present" : true
}
```

Now that all required resource are defined, we can invoke the required actions. Simply use *Invoke-TmfTenant* to do the actions directly or use *Test-TmfTenant* to only test the configuration without changing anything.

```powershell
Invoke-TmfTenant
```

## 2.8. Adding existing resources to your configuration
### 2.8.1. Named Locations (ipRange)

```powershell
Import-Module TMF -DisableNameChecking
Connect-MgGraph -Scopes (Get-TmfRequiredScope -NamedLocations)

$namedLocations = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/identity/conditionalAccess/namedLocations/?`$filter=isof('microsoft.graph.ipNamedLocation')").value | Select-Object @{n = "displayName"; e = {$_["displayName"]}}, @{n = "type";e = {"ipNamedLocation"}}, @{n = "ipRanges";e = {$_["ipRanges"]}}, @{n = "isTrusted";e = {$_["isTrusted"]}}
foreach ($location in $namedLocations) {
    $ipRanges = @()
    switch ($location.ipRanges.GetType().Name) {
        "Object[]" {
            $location.ipRanges | ForEach-Object {
                $ipRanges += [PSCustomObject]@{
                    "@odata.type" = $_["@odata.type"]
                    "cidrAddress" = $_["cidrAddress"]
                }
            }
         }
        default {
            $ipRanges += [PSCustomObject]@{
                "@odata.type" = $location.ipRanges["@odata.type"]
                "cidrAddress" = $location.ipRanges["cidrAddress"]
            }
        }
    }
    $location.ipRanges = $ipRanges
}
$namedLocations | ConvertTo-Json -Depth 6 | Out-File -FilePath "namedLocations.json" -Encoding UTF8
```

### 2.8.2. Conditional Access Policies
```powershell
Import-Module TMF -DisableNameChecking
Connect-MgGraph -Scopes (Get-TmfRequiredScope -ConditionalAccessPolicies)

$policies = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/identity/conditionalAccess/policies").Value | Select-Object @{n = "displayName"; e = {$_["displayName"]}}, @{n = "conditions"; e = {$_["conditions"]}}, @{n = "grantControls"; e = {$_["grantControls"]}}, @{n = "state"; e = {$_["state"]}}
foreach ($policy in $policies) {    
    #region conditions properties to first level
    foreach ($property in $policy.conditions.GetEnumerator()) {
        if ($property.Value) {
            switch ($property.Value.GetType().Name) {
                "Hashtable" {
                    foreach ($childProperty in $policy.conditions.$($property.Key).GetEnumerator()) {
                        if ($childProperty.Value) {
                            Add-Member -InputObject $policy -MemberType NoteProperty -Name $childProperty.Key -Value $childProperty.Value
                        }
                    }
                }
                default {
                    Add-Member -InputObject $policy -MemberType NoteProperty -Name $property.Key -Value $property.Value
                }
            }                
        }            
    }   
    #endregion
}
$policies | ConvertTo-Json -Depth 6 | Out-File -FilePath "policies.json"  -Encoding UTF8
```

### 2.8.3. Groups
```powershell
Connect-MgGraph -Scopes (Get-TmfRequiredScope -Groups)
Select-MgProfile -Name beta

$groups = Get-MgGroup -Property id, displayName, description, groupTypes, securityEnabled, mailEnabled, visibility, mailNickname | Select-Object id, displayName, description, groupTypes, securityEnabled, mailEnabled, visibility, mailNickname
foreach ($group in $groups) {
    <# Uncomment if you want to add the group members to your configuration.
    $members = @(Get-MgGroupMember -GroupId $group.Id -Property userPrincipalName | Foreach-Object {$_.AdditionalProperties["userPrincipalName"]})
    if ($members) {
        Add-Member -InputObject $group -MemberType NoteProperty -Name "members" -Value $members
    } #>

    <# Uncomment if you want to add the group owners to your configuration.
    $owners = @(Get-MgGroupOwner -GroupId $group.Id -Property userPrincipalName | Foreach-Object {$_.AdditionalProperties["userPrincipalName"]})
    if ($owners) {
        Add-Member -InputObject $group -MemberType NoteProperty -Name "owners" -Value $owners
    } #>

    Add-Member -InputObject $group -MemberType NoteProperty -Name "present" -Value $true
}
$groups | ConvertTo-Json -Depth 6 | Out-File -FilePath "groups.json" -Encoding UTF8
```
