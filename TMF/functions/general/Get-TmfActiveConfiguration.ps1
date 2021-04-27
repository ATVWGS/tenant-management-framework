function Get-TmfActiveConfiguration
{
	<#
		.SYNOPSIS
			Returns currently activated configurations.
	#>
	[CmdletBinding()]
	Param (
	)
	
	process
	{
		return $script:activatedConfigurations
	}
}
