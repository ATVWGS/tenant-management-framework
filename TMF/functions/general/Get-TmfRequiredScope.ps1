function Get-TmfRequiredScope
{
	<#
		.SYNOPSIS
			Returns required Microsoft Graph permission scopes.
	#>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "SpecifiedComponents")]
		[switch] $Groups,
		[switch] $Users,
		[Parameter(ParameterSetName = "All")]
		[bool] $All = $true
	)
	
	begin
	{		
		[string[]] $scopes = @()		
	}
	process
	{		
		if ($Groups) {
			$scopes += "Group.ReadWrite.All"
		}
		if ($Users) {
			$scopes += "User.ReadWrite.All"
		}


		if ($All) {
			$scopes = @("Group.ReadWrite.All", "User.ReadWrite.All")
		}

		return $scopes
	}
	end
	{
	
	}
}
