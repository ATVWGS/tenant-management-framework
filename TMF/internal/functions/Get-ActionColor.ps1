function Get-ActionColor
{
	[CmdletBinding()]
	Param (
		$Action
	)
	
	process
	{
		switch ($Action) {
			"Create" { return "yellow" }
			"Delete" { return "red" }
			"Update" { return "blue" }
			default { return "green" }
		}
	}
}
