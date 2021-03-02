function Invoke-TmfGroup
{
	[CmdletBinding()]
	Param (
	
	)
	
	begin
	{
		if (!$script:desiredConfiguration["groups"]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "Group"
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
