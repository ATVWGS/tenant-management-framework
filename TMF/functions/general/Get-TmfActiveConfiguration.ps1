function Get-TmfActiveConfiguration
{
	<#
		.SYNOPSIS
			Return currently activated configurations.
	#>
	[CmdletBinding()]
	Param (
	)
	
	process
	{
		return $script:activatedConfigurations
	}
}
