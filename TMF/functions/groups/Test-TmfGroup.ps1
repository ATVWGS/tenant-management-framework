function Test-TmfGroup
{
	[CmdletBinding()]
	Param (
	
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
	}
	process
	{
		foreach ($group in $script:desiredConfiguration["groups"]) {
			$group
		}
	}
	end
	{
	
	}
}
