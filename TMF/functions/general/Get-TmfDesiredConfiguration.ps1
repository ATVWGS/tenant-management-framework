function Get-TmfDesiredConfiguration
{
	<#
		.SYNOPSIS
			Returns currently loaded desired configurations.
	#>
	[CmdletBinding()]
	Param (	
		[ValidateSet("accessPackageAssignmentPolicies","accessPackageCatalogs","accessPackageResources","accessPackages","accessReviews","administrativeUnits","agreements",
		"appManagementPolicies","attributeSets","authenticationContextClassReferences","authenticationFlowsPolicies","authenticationMethodsPolicies","authenticationStrengthPolicies",
		"authorizationPolicies","conditionalAccessPolicies","crossTenantAccessDefaultSettings","crossTenantAccessPartnerSettings","crossTenantAccessPolicy","customSecurityAttributeAllowedValues",
		"customSecurityAttributeDefinitions","directoryRoles","directorySettings","groups","namedLocations","organizationalBrandings","roleAssignments","roleDefinitions","roleManagementPolicies",
		"roleManagementPolicyRuleTemplates","stringMappings","tenantAppManagementPolicy","adminConsentRequestPolicy")]
		$resourceTypes
	)
	
	process
	{
		if ($resourceTypes) {
			$returndata = @()
			foreach ($type in $resourceTypes) {
				$returndata += $script:desiredConfiguration[$type]
			}
			return $returndata
		}
		else {
			return $script:desiredConfiguration
		}
		
	}
}
