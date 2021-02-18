function Activate-TmfConfiguration
{
	[CmdletBinding()]
	Param (
		[string] $Path
	)
	
	begin
	{
		$configurationFilePath = "{0}\configuration.json" -f $Path
		if (!(Test-Path $configurationFilePath)) {
			Stop-PSFFunction -String "Activate-TMFConfiguration.PathDoesNotExist" -StringValues $configurationFilePath
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		
	}
	end
	{
	
	}
}
