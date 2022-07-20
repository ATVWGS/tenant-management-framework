@{
	# Script module or binary module file associated with this manifest
	RootModule = 'TMF.psm1'
	
	# Version number of this module.
	ModuleVersion = '0.0.1'
	
	# ID used to uniquely identify this module
	GUID = 'f1f44bfb-f67c-4595-a18f-ae4565ac0728'
	
	# Author of this module
	Author = 'Johannes Seitle'
	
	# Company or vendor of this module
	CompanyName = 'Volkswagen Group Services GmbH'
	
	# Copyright statement for this module
	Copyright = 'Copyright (c) 2021 Volkswagen Group Services GmbH'
	
	# Description of the functionality provided by this module
	Description = 'Helper module to manage Azure AD Tenants as code.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.1'
	
	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules = @(@{ ModuleName='PSFramework'; ModuleVersion='1.5.171' }, 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Graph.Identity.Governance')
	
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
		'Activate-TmfConfiguration',
		'Deactivate-TmfConfiguration',
		'Load-TmfConfiguration',
		'Test-TmfTenant',
		'Invoke-TmfTenant',
		'Register-TmfStringMapping',
		'Register-TmfGroup',
		'Test-TmfGroup',
		'Invoke-TmfGroup',
		'Register-TmfNamedLocation',
		'Test-TmfNamedLocation',
		'Invoke-TmfNamedLocation',
		'Register-TmfAgreement',
		'Test-TmfAgreement',
		'Invoke-TmfAgreement',
		'Register-TmfConditionalAccessPolicy',
		'Test-TmfConditionalAccessPolicy',
		'Invoke-TmfConditionalAccessPolicy',
		'Test-TmfEntitlementManagement',
		'Invoke-TmfEntitlementManagement',
		'Register-TmfAccessPackageCatalog',
		'Test-TmfAccessPackageCatalog',
		'Invoke-TmfAccessPackageCatalog',
		'Register-TmfAccessPackage',
		'Test-TmfAccessPackage',
		'Invoke-TmfAccessPackage',
		'Register-TmfAccessPackageAssignmentPolicy',
		'Test-TmfAccessPackageAssignmentPolicy',
		'Invoke-TmfAccessPackageAssignmentPolicy',
		'Invoke-TmfAdministrativeUnit',
        'Test-TmfAdministrativeUnit',
        'Register-TmfAdministrativeUnit',
		'Register-TmfAccessPackageResource',
		'Test-TmfAccessPackageResource',
		'Invoke-TmfAccessPackageResource',
		'Register-TmfAccessReview',
		'Test-TmfAccessReview',
		'Invoke-TmfAccessReview',
		'Register-TmfDirectoryRole',
		'Test-TmfDirectoryRole',
		'Invoke-TmfDirectoryRole',
		'Register-TmfRoleManagementPolicy',
		'Test-TmfRoleManagementPolicy',
		'Invoke-TmfRoleManagementPolicy',
		'Register-TmfRoleManagementPolicyRuleTemplate',
		'Register-TmfRoleAssignment',
		'Test-TmfRoleAssignment',
		'Invoke-TmfRoleAssignment',
		'Register-TmfRoleDefinition',
		'Test-TmfRoleDefinition',
		'Invoke-TmfRoleDefinition',
		'Test-TmfRoleManagement',
		'Invoke-TmfRoleManagement',
		'Register-TmfAuthenticationFlowsPolicy',
		'Test-TmfAuthenticationFlowsPolicy',
		'Invoke-TmfAuthenticationFlowsPolicy',
		'Register-TmfAuthenticationMethodsPolicy',
		'Test-TmfAuthenticationMethodsPolicy',
		'Invoke-TmfAuthenticationMethodsPolicy',
		'Register-TmfAuthorizationPolicy',
		'Test-TmfAuthorizationPolicy',
		'Invoke-TmfAuthorizationPolicy',
		'Test-TmfPolicy',
		'Invoke-TmfPolicy'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport = ''
	
	# Variables to export from this module
	VariablesToExport = ''
	
	# Aliases to export from this module
	AliasesToExport = ''
	
	# List of all files packaged with this module
	FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
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