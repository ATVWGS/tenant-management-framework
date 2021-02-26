function Get-TmfActiveConfiguration
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
