function Get-TmfRequiredScope
{
	<#
		.SYNOPSIS
			Returns required Microsoft Graph permission scopes.

		.DESCRIPTION
			Depending on the resources you want to configure, different Microsoft Graph
			permission scopes are required. This command returns the required scopes.

		.PARAMETER All
			Return all scopes that TMF requires.

		.PARAMETER Groups
			Return all scopes required for managing group-resources.

		.PARAMETER Users
			Return all scopes required for managing user-resources.
		
		.PARAMETER NamedLocations
			Return all scopes required for managing namedLocation-resources.
		
		.PARAMETER Agreements
			Return all scopes required for managing agreement-resources.
		
		.PARAMETER ConditionalAccessPolicies
			Return all scopes required for managing conditionalAccessPolicy-resources.

		.PARAMETER ConditionalAccessPolicies
			Return all scopes required for managing administrativeUnit-resources.
		
		.EXAMPLE
			PS> Connect-MgGraph -Scopes (Get-TMFRequiredScope -Groups)

			Requests access to Microsoft Graph with all required scopes for changes to group-resources.
		
		.EXAMPLE
			PS> Connect-MgGraph -Scopes (Get-TMFRequiredScope -All)

			Requests access to Microsoft Graph with access to all resources the TMF can handle.
	#>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $AccessReviews,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $AdministrativeUnits,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Agreements,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $AuthenticationContextClassReferences,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $ConditionalAccessPolicies,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $CrossTenantAccess,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $CustomSecurityAttributes,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $DirectoryRoles,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $DirectorySettings,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $EntitlementManagement,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Groups,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $NamedLocations,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $OrganizationalBrandings,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Policies,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $RoleManagement,		
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Users,
		[Parameter(ParameterSetName = "All")]
		[switch] $All
	)
	
	begin
	{		
		[string[]] $scopes = @()		
	}
	process
	{		
		if($AccessReviews -or $All) {
			$scopes += "Group.Read.All", "AccessReview.ReadWrite.All", "RoleManagement.Read.Directory", "Directory.Read.All", "Directory.AccessAsUser.All"
		}
		if ($AdministrativeUnits -or $All) {
			$scopes += "AdministrativeUnit.ReadWrite.All", "Directory.AccessAsUser.All", "RoleManagement.ReadWrite.Directory"
		}
		if ($Agreements -or $All) {
			$scopes += "Agreement.ReadWrite.All"
		}
		if ($AuthenticationContextClassReferences -or $All) {
			$scopes += "AuthenticationContext.ReadWrite.All"
		}
		if ($ConditionalAccessPolicies -or $All) {
			$scopes += "Policy.ReadWrite.ConditionalAccess", "Policy.Read.All", "RoleManagement.Read.Directory", "Application.Read.All", "Agreement.Read.All", "Group.Read.All"
		}
		if ($CrossTenantAccess -or $All) {
			$scopes += "Policy.ReadWrite.CrossTenantAccess"
		}
		if ($CustomSecurityAttributes -or $All) {
			$scopes += "CustomSecAttributeDefinition.ReadWrite.All"
		}
		if ($DirectoryRoles -or $All) {
			$scopes += "RoleManagement.ReadWrite.Directory"
		}
		if ($DirectorySettings -or $All) {
			$scopes += "Directory.ReadWrite.Directory"
		}
		if ($EntitlementManagement -or $All) {
			$scopes += "EntitlementManagement.ReadWrite.All"
		}
		if ($Groups -or $All) {
			$scopes += "Group.ReadWrite.All", "GroupMember.ReadWrite.All", "Directory.ReadWrite.All", "Directory.AccessAsUser.All"
		}
		if ($NamedLocations -or $All) {
			$scopes += "Policy.ReadWrite.ConditionalAccess"
		}
		if ($OrganizationalBrandings -or $All) {
			$scopes += "OrganizationalBranding.ReadWrite.All"
		}
		if ($Policies -or $All) {
			$scopes += "Policy.ReadWrite.AuthenticationMethod", "Policy.ReadWrite.Authorization", "Policy.ReadWrite.AuthenticationFlows"
		}
		if($RoleManagement -or $All) {
			$scopes += "RoleManagement.ReadWrite.Directory", "Directory.AccessAsUser.All", "RoleEligibilitySchedule.ReadWrite.Directory", "RoleAssignmentSchedule.ReadWrite.Directory", "RoleManagementPolicy.ReadWrite.Directory","RoleManagementPolicy.ReadWrite.AzureADGroup"
		}
		if ($Users -or $All) {
			$scopes += "User.ReadWrite.All"
		}
		
		return ($scopes | Sort-Object -Unique)
	}
}