function Get-TmfRequiredScope
{
	<#
		.SYNOPSIS
			Returns required Microsoft Graph permission scopes.
	#>
	[CmdletBinding()]
	Param (
	
	)
	
	begin
	{
		
	}
	process
	{
		return @("Group.ReadWrite.All")
	}
	end
	{
	
	}
}
