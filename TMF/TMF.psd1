@{
	# Script module or binary module file associated with this manifest
	RootModule        = 'TMF.psm1'

	# Version number of this module.
	ModuleVersion     = '0.0.1'

	# ID used to uniquely identify this module
	GUID              = 'f1f44bfb-f67c-4595-a18f-ae4565ac0728'

	# Author of this module
	Author            = 'Azure Team VWGS'

	# Company or vendor of this module
	CompanyName       = 'Volkswagen Group Services GmbH'

	# Copyright statement for this module
	Copyright         = 'Copyright (c) 2025 Volkswagen Group Services GmbH'

	# Description of the functionality provided by this module
	Description       = 'Helper module to manage Azure AD Tenants as code.'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.1'

	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules   = @('PSFramework', 'Microsoft.Graph.Authentication')

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\TMF.dll')

	# Type files (.ps1xml) to be loaded when importing this module
	# Expensive for import time, no more than one should be used.
	# TypesToProcess = @('xml\TMF.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module.
	# Expensive for import time, no more than one should be used.
	# FormatsToProcess = @('xml\TMF.Format.ps1xml')

	# Functions to export from this module
	FunctionsToExport = @(
		'Beautify-TmfTestResult'
		'New-TmfConfiguration',
		'Get-TmfRequiredScope',
		'Get-TmfActiveConfiguration',
		'Get-TmfDesiredConfiguration',
		'Get-TmfSupportedResources',
		'Activate-TmfConfiguration',
		'Deactivate-TmfConfiguration',
		'Load-TmfConfiguration',
		'Test-TmfTenant',
		'Invoke-TmfTenant',
		'Export-TmfTenant',
		'Register-TmfStringMapping',
		'Register-TmfGroup',
		'Export-TmfGroup',
		'Test-TmfGroup',
		'Invoke-TmfGroup',
		'Register-TmfNamedLocation',
		'Export-TmfNamedLocation',
		'Test-TmfNamedLocation',
		'Invoke-TmfNamedLocation',
		'Register-TmfAgreement',
		'Export-TmfAgreement',
		'Test-TmfAgreement',
		'Invoke-TmfAgreement',
		'Register-TmfConditionalAccessPolicy',
		'Export-TmfConditionalAccessPolicy',
		'Test-TmfConditionalAccessPolicy',
		'Invoke-TmfConditionalAccessPolicy',
		'Test-TmfEntitlementManagement',
		'Invoke-TmfEntitlementManagement',
		'Export-TmfEntitlementManagement',
		'Export-TmfAccessPackageCatalog',
		'Export-TmfAccessPackage',
		'Register-TmfAccessPackageCatalog',
		'Test-TmfAccessPackageCatalog',
		'Invoke-TmfAccessPackageCatalog',
		'Register-TmfAccessPackageResource',
		'Test-TmfAccessPackageResource',
		'Invoke-TmfAccessPackageResource',		
		'Register-TmfAccessPackage',
		'Test-TmfAccessPackage',
		'Invoke-TmfAccessPackage',
		'Register-TmfAccessPackageAssignmentPolicy',
		'Test-TmfAccessPackageAssignmentPolicy',
		'Invoke-TmfAccessPackageAssignmentPolicy',
		'Invoke-TmfAdministrativeUnit',
		'Test-TmfAdministrativeUnit',
		'Register-TmfAdministrativeUnit',
		'Export-TmfAdministrativeUnit',
		'Register-TmfAccessReview',
		'Export-TmfAccessReview',
		'Test-TmfAccessReview',
		'Invoke-TmfAccessReview',
		'Export-TmfDirectoryRole',
		'Register-TmfDirectoryRole',
		'Test-TmfDirectoryRole',
		'Invoke-TmfDirectoryRole',
		'Register-TmfRoleManagementPolicy',
		'Export-TmfRoleManagementPolicy',
		'Test-TmfRoleManagementPolicy',
		'Invoke-TmfRoleManagementPolicy',
		'Register-TmfRoleManagementPolicyRuleTemplate',
		'Register-TmfRoleAssignment',
		'Export-TmfRoleAssignment',
		'Test-TmfRoleAssignment',
		'Invoke-TmfRoleAssignment',
		'Register-TmfRoleDefinition',
		'Export-TmfRoleDefinition',
		'Test-TmfRoleDefinition',
		'Invoke-TmfRoleDefinition',
		'Export-TmfRoleManagement',
		'Test-TmfRoleManagement',
		'Invoke-TmfRoleManagement',
		'Register-TmfAuthenticationFlowsPolicy',
		'Test-TmfAuthenticationFlowsPolicy',
		'Invoke-TmfAuthenticationFlowsPolicy',
		'Export-TmfAuthenticationFlowsPolicy',
		'Register-TmfAuthenticationMethodsPolicy',
		'Test-TmfAuthenticationMethodsPolicy',
		'Invoke-TmfAuthenticationMethodsPolicy',
		'Export-TmfAuthenticationMethodsPolicy',
		'Register-TmfAuthenticationStrengthPolicy',
		'Test-TmfAuthenticationStrengthPolicy',
		'Invoke-TmfAuthenticationStrengthPolicy',
		'Export-TmfAuthenticationStrengthPolicy',
		'Register-TmfAuthorizationPolicy',
		'Test-TmfAuthorizationPolicy',
		'Invoke-TmfAuthorizationPolicy',
		'Export-TmfAuthorizationPolicy',
		'Register-TmfAppManagementPolicy',
		'Test-TmfAppManagementPolicy',
		'Invoke-TmfAppManagementPolicy',
		'Export-TmfAppManagementPolicy',
		'Register-TmfTenantAppManagementPolicy',
		'Test-TmfTenantAppManagementPolicy',
		'Invoke-TmfTenantAppManagementPolicy',
		'Export-TmfTenantAppManagementPolicy',
		'Register-TmfAdminConsentRequestPolicy',
		'Test-TmfAdminConsentRequestPolicy',
		'Invoke-TmfAdminConsentRequestPolicy',
		'Export-TmfAdminConsentRequestPolicy',
		'Test-TmfPolicy',
		'Invoke-TmfPolicy',
		'Export-TmfPolicy',
		'Invoke-TmfAttributeSet',
		'Register-TmfAttributeSet',
		'Test-TmfAttributeSet',
		'Export-TmfAttributeSet',
		'Invoke-TmfCustomSecurityAttributeAllowedValue',
		'Register-TmfCustomSecurityAttributeAllowedValue',
		'Test-TmfCustomSecurityAttributeAllowedValue',
		'Export-TmfCustomSecurityAttributeAllowedValue',
		'Invoke-TmfCustomSecurityAttributeDefinition',
		'Register-TmfCustomSecurityAttributeDefinition',
		'Test-TmfCustomSecurityAttributeDefinition',
		'Export-TmfCustomSecurityAttributeDefinition',
		'Invoke-TmfCustomSecurityAttribute',
		'Export-TmfCustomSecurityAttribute',
		'Test-TmfCustomSecurityAttribute',
		'Register-TmfAuthenticationContextClassReference',
		'Export-TmfAuthenticationContextClassReference',
		'Test-TmfAuthenticationContextClassReference',
		'Invoke-TmfAuthenticationContextClassReference',
		'Register-TmfOrganizationalBranding',
		'Export-TmfOrganizationalBranding',
		'Test-TmfOrganizationalBranding',
		'Invoke-TmfOrganizationalBranding',
		'Register-TmfCrossTenantAccessPolicy',
		'Export-TmfCrossTenantAccessPolicy',
		'Test-TmfCrossTenantAccessPolicy',
		'Invoke-TmfCrossTenantAccessPolicy',
		'Register-TmfCrossTenantAccessDefaultSetting',
		'Export-TmfCrossTenantAccessDefaultSetting',
		'Test-TmfCrossTenantAccessDefaultSetting',
		'Invoke-TmfCrossTenantAccessDefaultSetting',
		'Register-TmfCrossTenantAccessPartnerSetting',
		'Export-TmfCrossTenantAccessPartnerSetting',
		'Test-TmfCrossTenantAccessPartnerSetting',
		'Invoke-TmfCrossTenantAccessPartnerSetting',
		'Export-TmfCrossTenantAccess',
		'Test-TmfCrossTenantAccess',
		'Invoke-TmfCrossTenantAccess',
		'Export-TmfDirectorySetting',
		'Register-TmfDirectorySetting',
		'Test-TmfDirectorySetting',
		'Invoke-TmfDirectorySetting'
	)

	# Cmdlets to export from this module
	CmdletsToExport   = ''

	# Variables to export from this module
	VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport   = ''

	# List of all files packaged with this module
	FileList          = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData       = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()

			# A URL to the license for this module.
			# LicenseUri = ''

			# A URL to the main website for this project.
			# ProjectUri = ''

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}
