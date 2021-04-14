function Get-TmfRequiredScope
{
	<#
		.SYNOPSIS
			Returns required Microsoft Graph permission scopes.
	#>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Groups,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Users,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $NamedLocations,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Agreements,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $ConditionalAccessPolicies,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $EntitlementManagement,
		[Parameter(ParameterSetName = "All")]
		[switch] $All
	)
	
	begin
	{		
		[string[]] $scopes = @()		
	}
	process
	{		
		if ($Groups -or $All) {
			$scopes += "Group.ReadWrite.All", "GroupMember.ReadWrite.All"
		}
		if ($Users -or $All) {
			$scopes += "User.ReadWrite.All"
		}
		if ($NamedLocations -or $All) {
			$scopes += "Policy.ReadWrite.ConditionalAccess"
		} 
		if ($Agreements -or $All) {
			$scopes += "Agreement.ReadWrite.All"
		}
		if ($ConditionalAccessPolicies -or $All) {
			$scopes += "Policy.ReadWrite.ConditionalAccess", "Policy.Read.All", "RoleManagement.Read.Directory", "Application.Read.All", "Agreement.Read.All"
		}
		if ($EntitlementManagement -or $All) {
			$scopes += "EntitlementManagement.ReadWrite.All"
		}
		return ($scopes | Sort-Object -Unique)
	}
}