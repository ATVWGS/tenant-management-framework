function Get-TmfConfiguration
{
	[CmdletBinding()]
	Param (
	)
	
	begin
	{
		
	}
	process
	{
		return $script:activatedConfigurations
	}
	end
	{
	
	}
}
