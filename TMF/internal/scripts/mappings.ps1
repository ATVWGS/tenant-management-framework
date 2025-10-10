$script:supportedResources = @{
    "stringMappings" = @{
        "registerFunction" = (Get-Command Register-TmfStringMapping)
        "weight" = 0
    }    
    "groups" = @{
        "registerFunction" = (Get-Command Register-TmfGroup)
        "testFunction" = (Get-Command Test-TmfGroup)
        "invokeFunction" = (Get-Command Invoke-TmfGroup)
        "exportFunction" = (Get-Command Export-TmfGroup)          
        "weight" = 10
    }
    "users" = @{
        "registerFunction" = (Get-Command Register-TmfUser)
        "testFunction" = (Get-Command Test-TmfUser)
        "invokeFunction" = (Get-Command Invoke-TmfUser)
        "exportFunction" = (Get-Command Export-TmfUser)
        "weight" = 11
    }
    "namedLocations" = @{
        "registerFunction" = (Get-Command Register-TmfNamedLocation)
        "testFunction" = (Get-Command Test-TmfNamedLocation)
        "invokeFunction" = (Get-Command Invoke-TmfNamedLocation)
        "weight" = 10
    }
    "agreements" = @{
        "registerFunction" = (Get-Command Register-TmfAgreement)
        "testFunction" = (Get-Command Test-TmfAgreement)
        "invokeFunction" = (Get-Command Invoke-TmfAgreement)
        "weight" = 10
    }
    "administrativeUnits" = @{ 
        "registerFunction" = (Get-Command Register-TmfAdministrativeUnit)
        "testFunction" = (Get-Command Test-TmfAdministrativeUnit)
        "invokeFunction" = (Get-Command Invoke-TmfAdministrativeUnit)
        "exportFunction" = (Get-Command Export-TmfAdministrativeUnit)
        "weight" = 9
    }
    "conditionalAccessPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfConditionalAccessPolicy)
        "testFunction" = (Get-Command Test-TmfConditionalAccessPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfConditionalAccessPolicy)
        "validateFunctions" = @{
            "deviceFilter" = (Get-Command Validate-ConditionalAccessFilter)
            "conditions" = (Get-Command Validate-ConditionalAccessConditionSet)
            "applications" = (Get-Command Validate-ConditionalAccessApplications)
            "applicationFilter" = (Get-Command Validate-ConditionalAccessApplicationFilter)
            "authenticationStrength" = (Get-Command Validate-ConditionalAccessAuthenticationStrength)
            "users" = (Get-Command Validate-ConditionalAccessUsers)
            "devices" = (Get-Command Validate-ConditionalAccessDevices)
            "locations" = (Get-Command Validate-ConditionalAccessLocations)
            "platforms" = (Get-Command Validate-ConditionalAccessPlatforms)
            "grantControls" = (Get-Command Validate-ConditionalAccessGrantControls)
            "sessionControls" = (Get-Command Validate-ConditionalAccessSessionControls)
            "applicationEnforcedRestrictions" = (Get-Command Validate-ApplicationEnforcedRestrictionsSessionControl)
            "cloudAppSecurity" = (Get-Command Validate-CloudAppSecuritySessionControl)
            "persistentBrowser" = (Get-Command Validate-PersistentBrowserSessionControl)
            "signInFrequency" = (Get-Command Validate-SignInFrequencySessionControl)
        }
        "weight" = 50
    }
    "accessPackageCatalogs" = @{
        "registerFunction" = (Get-Command Register-TmfAccessPackageCatalog)
        "testFunction" = (Get-Command Test-TmfAccessPackageCatalog)
        "invokeFunction" = (Get-Command Invoke-TmfAccessPackageCatalog)
    "exportFunction" = (Get-Command Export-TmfAccessPackageCatalog)
        "parentType" = "entitlementManagement"
        "weight" = 54
    }
    "accessPackageResources" = @{
        "testFunction" = (Get-Command Test-TmfAccessPackageResource)
        "invokeFunction" = (Get-Command Invoke-TmfAccessPackageResource)
    "exportFunction" = (Get-Command Export-TmfAccessPackageResource)
        "parentType" = "entitlementManagement"
        "weight" = 55
    }
    "accessPackages" = @{
        "registerFunction" = (Get-Command Register-TmfAccessPackage)
        "testFunction" = (Get-Command Test-TmfAccessPackage)
        "invokeFunction" = (Get-Command Invoke-TmfAccessPackage)
    "exportFunction" = (Get-Command Export-TmfAccessPackage)
        "parentType" = "entitlementManagement"
        "weight" = 56
    }
    "accessPackageAssignmentPolicies" = @{     
        "testFunction" = (Get-Command Test-TmfAccessPackageAssignmentPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfAccessPackageAssignmentPolicy)
    "exportFunction" = (Get-Command Export-TmfAccessPackageAssignmentPolicy)
        "validateFunctions" = @{
            "reviewSettings" = (Get-Command Validate-AssignmentReviewSettings)
            "requestApprovalSettings" = (Get-Command Validate-RequestApprovalSettings)
            "requestorSettings" = (Get-Command Validate-RequestorSettings)
            "stages" = (Get-Command Validate-ApprovalStage)    
            "allowedRequestors" = (Get-Command Validate-SubjectSet)
            "primaryApprovers" = (Get-Command Validate-SubjectSet)
            "escalationApprovers" = (Get-Command Validate-SubjectSet)
            "fallbackPrimaryApprovers" = (Get-Command Validate-SubjectSet)
            "fallbackEscalationApprovers" = (Get-Command Validate-SubjectSet)
            "primaryReviewers" = (Get-Command Validate-SubjectSet)
            "fallbackReviewers" = (Get-Command Validate-SubjectSet)
            "schedule" = (Get-Command Validate-AssignmentReviewSchedule)
            "onBehalfRequestors" = (Get-Command Validate-SubjectSet)
            "specificAllowedTargets" = (Get-Command Validate-SubjectSet)
            "recurrence" = (Get-Command Validate-AssignmentReviewRecurrence)
            "pattern" = (Get-Command Validate-AssignmentReviewPattern)
            "range" = (Get-Command Validate-AssignmentReviewRange)
        }
        "parentType" = "entitlementManagement"
        "weight" = 57
    }
    "accessReviews" = @{
        "registerFunction" = (Get-Command Register-TmfAccessReview)
        "testFunction" = (Get-Command Test-TmfAccessReview)
        "invokeFunction" = (Get-Command Invoke-TmfAccessReview)
    "exportFunction" = (Get-Command Export-TmfAccessReview)
        "validateFunctions" = @{
            "scope" = (Get-Command Validate-AccessReviewScope)
            "settings" = (Get-Command Validate-AccessReviewSettings)
            "recurrence" = (Get-Command Validate-AccessReviewRecurrence)
            "pattern" = (Get-Command Validate-AccessReviewPattern)
            "range" = (Get-Command Validate-AccessReviewRange)
            "reviewers" = (Get-Command Validate-AccessReviewReviewers)
            "fallbackReviewers" = (Get-Command Validate-AccessReviewReviewers)
        }
        "weight" = 60
    }
    "directoryRoles" = @{
        "registerFunction" = (Get-Command Register-TmfDirectoryRole)
        "testFunction" = (Get-Command Test-TmfDirectoryRole)
        "invokeFunction" = (Get-Command Invoke-TmfDirectoryRole)
        "exportFunction" = (Get-Command Export-TmfDirectoryRole)
        "weight" = 15
    }

    "roleManagementPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfRoleManagementPolicy)
        "testFunction" = (Get-Command Test-TmfRoleManagementPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfRoleManagementPolicy)
    "exportFunction" = (Get-Command Export-TmfRoleManagementPolicy)
        "parentType" = "roleManagement"
        "weight" = 17
    }
    "roleAssignments" = @{
        "registerFunction" = (Get-Command Register-TmfRoleAssignment)
        "testFunction" = (Get-Command Test-TmfRoleAssignment)
        "invokeFunction" = (Get-Command Invoke-TmfRoleAssignment)
    "exportFunction" = (Get-Command Export-TmfRoleAssignment)
        "parentType" = "roleManagement"
        "weight" = 18
    }
    "roleDefinitions" = @{
        "registerFunction" = (Get-Command Register-TmfRoleDefinition)
        "testFunction" = (Get-Command Test-TmfRoleDefinition)
        "invokeFunction" = (Get-Command Invoke-TmfRoleDefinition)
    "exportFunction" = (Get-Command Export-TmfRoleDefinition)
        "parentType" = "roleManagement"
        "weight" = 15
    }
    "roleManagementPolicyRuleTemplates" = @{
        "registerFunction" = (Get-Command Register-TmfRoleManagementPolicyRuleTemplate)
        "parentType" = "roleManagement"
        "weight" = 16
    }
    "appManagementPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfAppManagementPolicy)
        "testFunction" = (Get-Command Test-TmfAppManagementPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfAppManagementPolicy)
    "exportFunction" = (Get-Command Export-TmfAppManagementPolicy)
        "parentType" = "policies"
        "weight" = 6
    }
    "authenticationFlowsPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfAuthenticationFlowsPolicy)
        "testFunction" = (Get-Command Test-TmfAuthenticationFlowsPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfAuthenticationFlowsPolicy)
    "exportFunction" = (Get-Command Export-TmfAuthenticationFlowsPolicy)
        "parentType" = "policies"
        "weight" = 5
    }
    "authenticationMethodsPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfAuthenticationMethodsPolicy)
        "testFunction" = (Get-Command Test-TmfAuthenticationMethodsPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfAuthenticationMethodsPolicy)
    "exportFunction" = (Get-Command Export-TmfAuthenticationMethodsPolicy)
        "parentType" = "policies"
        "weight" = 6
    }
    "authorizationPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfAuthorizationPolicy)
        "testFunction" = (Get-Command Test-TmfAuthorizationPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfAuthorizationPolicy)
    "exportFunction" = (Get-Command Export-TmfAuthorizationPolicy)
        "parentType" = "policies"
        "weight" = 7
    }
    "authenticationStrengthPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfAuthenticationStrengthPolicy)
        "testFunction" = (Get-Command Test-TmfAuthenticationStrengthPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfAuthenticationStrengthPolicy)
    "exportFunction" = (Get-Command Export-TmfAuthenticationStrengthPolicy)
        "parentType" = "policies"
        "weight" = 8
    }
    "tenantAppManagementPolicy" = @{
        "registerFunction" = (Get-Command Register-TmfTenantAppManagementPolicy)
        "testFunction" = (Get-Command Test-TmfTenantAppManagementPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfTenantAppManagementPolicy)
    "exportFunction" = (Get-Command Export-TmfTenantAppManagementPolicy)
        "parentType" = "policies"
        "weight" = 5
    }
    "attributeSets" = @{
        "registerFunction" = (Get-Command Register-TmfAttributeSet)
        "testFunction" = (Get-Command Test-TmfAttributeSet)
        "invokeFunction" = (Get-Command Invoke-TmfAttributeSet)
    "exportFunction" = (Get-Command Export-TmfAttributeSet)
        "parentType" = "customSecurityAttributes"
        "weight" = 40
    }
    "customSecurityAttributeDefinitions" = @{
        "registerFunction" = (Get-Command Register-TmfCustomSecurityAttributeDefinition)
        "testFunction" = (Get-Command Test-TmfCustomSecurityAttributeDefinition)
        "invokeFunction" = (Get-Command Invoke-TmfCustomSecurityAttributeDefinition)
    "exportFunction" = (Get-Command Export-TmfCustomSecurityAttributeDefinition)
        "parentType" = "customSecurityAttributes"
        "weight" = 41
    }
    "customSecurityAttributeAllowedValues" = @{
        "registerFunction" = (Get-Command Register-TmfCustomSecurityAttributeAllowedValue)
        "testFunction" = (Get-Command Test-TmfCustomSecurityAttributeAllowedValue)
        "invokeFunction" = (Get-Command Invoke-TmfCustomSecurityAttributeAllowedValue)
    "exportFunction" = (Get-Command Export-TmfCustomSecurityAttributeAllowedValue)
        "parentType" = "customSecurityAttributes"
        "weight" = 42
    }
    "authenticationContextClassReferences" = @{
        "registerFunction" = (Get-Command Register-TmfAuthenticationContextClassReference)
        "testFunction" = (Get-Command Test-TmfAuthenticationContextClassReference)
        "invokeFunction" = (Get-Command Invoke-TmfAuthenticationContextClassReference)
        "exportFunction" = (Get-Command Export-TmfAuthenticationContextClassReference)
        "weight" = 49
    }
    "organizationalBrandings" = @{
        "registerFunction" = (Get-Command Register-TmfOrganizationalBranding)
        "testFunction" = (Get-Command Test-TmfOrganizationalBranding)
        "invokeFunction" = (Get-Command Invoke-TmfOrganizationalBranding)
        "exportFunction" = (Get-Command Export-TmfOrganizationalBranding)
        "weight" = 100
    }
    "crossTenantAccessPolicy" = @{
        "registerFunction" = (Get-Command Register-TmfCrossTenantAccessPolicy)
        "testFunction" = (Get-Command Test-TmfCrossTenantAccessPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfCrossTenantAccessPolicy)
        "exportFunction" = (Get-Command Export-TmfCrossTenantAccessPolicy)
        "parentType" = "crossTenantAccess"
        "weight" = 90
    }
    "crossTenantAccessDefaultSettings" = @{
        "registerFunction" = (Get-Command Register-TmfCrossTenantAccessDefaultSetting)
        "testFunction" = (Get-Command Test-TmfCrossTenantAccessDefaultSetting)
        "invokeFunction" = (Get-Command Invoke-TmfCrossTenantAccessDefaultSetting)
        "exportFunction" = (Get-Command Export-TmfCrossTenantAccessDefaultSetting)
        "parentType" = "crossTenantAccess"
        "weight" = 91
    }
    "crossTenantAccessPartnerSettings" = @{
        "registerFunction" = (Get-Command Register-TmfCrossTenantAccessPartnerSetting)
        "testFunction" = (Get-Command Test-TmfCrossTenantAccessPartnerSetting)
        "invokeFunction" = (Get-Command Invoke-TmfCrossTenantAccessPartnerSetting)
        "exportFunction" = (Get-Command Export-TmfCrossTenantAccessPartnerSetting)
        "parentType" = "crossTenantAccess"
        "weight" = 92
    }
    "directorySettings" = @{
        "registerFunction" = (Get-Command Register-TmfDirectorySetting)
        "testFunction" = (Get-Command Test-TmfDirectorySetting)
        "invokeFunction" = (Get-Command Invoke-TmfDirectorySetting)
        "exportFunction" = (Get-Command Export-TmfDirectorySetting)
        "weight" = 4
    }

} # All currently supported components.
Set-Variable -Name supportedResources -Option ReadOnly

$script:validateFunctionMapping = @{
    <# Legacy ... #>
}