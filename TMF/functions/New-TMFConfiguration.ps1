function New-TMFConfiguration
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $OutPath,
		[Parameter(Mandatory = $true)]
		[string] $Name,
		[switch] $ForceCreation
	)
	
	begin
	{
		if (!$Force -and !(Test-Path $OutPath)) {
			Stop-PSFFunction -String "New-TMFConfiguration.OutPath.PathDoesNotExist" -StringValues $OutPath
		}
	}
	process
	{
	
	}
	end
	{
	
	}
}
