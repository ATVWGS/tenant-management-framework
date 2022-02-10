$script:supportedResources = @{
    "stringMappings" = @{
        "registerFunction" = (Get-Command Register-TmfStringMapping)
        "weight" = 0
    }    
    "groups" = @{
        "registerFunction" = (Get-Command Register-TmfGroup)
        "testFunction" = (Get-Command Test-TmfGroup)
        "invokeFunction" = (Get-Command Invoke-TmfGroup)        
        "weight" = 10
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
        "registerFunction" = (Get-Command Register-TmfAdministrativeUnits)
        "testFunction" = (Get-Command Test-TmfAdministrativeUnits)
        "invokeFunction" = (Get-Command Invoke-TmfAdministrativeUnits)       
        "weight" = 20
    }
    "conditionalAccessPolicies" = @{
        "registerFunction" = (Get-Command Register-TmfConditionalAccessPolicy)
        "testFunction" = (Get-Command Test-TmfConditionalAccessPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfConditionalAccessPolicy)
        "validateFunctions" = @{
            "deviceFilter" = (Get-Command Validate-ConditionalAccessFilter)
            "conditions" = (Get-Command Validate-ConditionalAccessConditionSet)
            "applications" = (Get-Command Validate-ConditionalAccessApplications)
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
        "parentType" = "entitlementManagement"
        "weight" = 54
    }
    "accessPackageResources" = @{
        "testFunction" = (Get-Command Test-TmfAccessPackageResource)
        "invokeFunction" = (Get-Command Invoke-TmfAccessPackageResource)
        "parentType" = "entitlementManagement"
        "weight" = 55
    }
    "accessPackages" = @{
        "registerFunction" = (Get-Command Register-TmfAccessPackage)
        "testFunction" = (Get-Command Test-TmfAccessPackage)
        "invokeFunction" = (Get-Command Invoke-TmfAccessPackage)
        "parentType" = "entitlementManagement"
        "weight" = 56
    }
    "accessPackageAssignementPolicies" = @{     
        "testFunction" = (Get-Command Test-TmfAccessPackageAssignementPolicy)
        "invokeFunction" = (Get-Command Invoke-TmfAccessPackageAssignementPolicy)
        "validateFunctions" = @{
            "accessReviewSettings" = (Get-Command Validate-AssignmentReviewSettings)
            "requestApprovalSettings" = (Get-Command Validate-RequestApprovalSettings)
            "requestorSettings" = (Get-Command Validate-RequestorSettings)
            "approvalStages" = (Get-Command Validate-ApprovalStage)    
            "allowedRequestors" = (Get-Command Validate-UserSet)
            "reviewers" = (Get-Command Validate-UserSet)
            "primaryApprovers" = (Get-Command Validate-UserSet)
            "escalationApprovers" = (Get-Command Validate-UserSet)
        }
        "parentType" = "entitlementManagement"
        "weight" = 57
    }    
	"accessReviews" = @{
        "registerFunction" = (Get-Command Register-TmfAccessReview)
        "testFunction" = (Get-Command Test-TmfAccessReview)
        "invokeFunction" = (Get-Command Invoke-TmfAccessReview)
        "validateFunctions" = @{
            "scope" = (Get-Command Validate-AccessReviewScope)
            "settings" = (Get-Command Validate-AccessReviewSettings)
            "recurrence" = (Get-Command Validate-AccessReviewRecurrence)
            "pattern" = (Get-Command Validate-AccessReviewPattern)
            "range" = (Get-Command Validate-AccessReviewRange)
            "reviewers" = (Get-Command Validate-AccessReviewReviewers)
        }
        "weight" = 60
    }
} # All currently supported components.
Set-Variable -Name supportedResources -Option ReadOnly

$script:validateFunctionMapping = @{
    <# Legacy ... #>
}
