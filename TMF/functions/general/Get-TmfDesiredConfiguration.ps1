function Get-TmfDesiredConfiguration
{
	<#
		.SYNOPSIS
			Returns currently loaded desired configurations.
	#>
	[CmdletBinding()]
	Param (	
	)
	
	process
	{
		return $script:desiredConfiguration
	}
}
