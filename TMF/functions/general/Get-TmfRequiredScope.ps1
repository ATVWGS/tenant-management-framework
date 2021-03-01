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

		return $scopes
	}
	end
	{
	
	}
}
