function Validate-ConditionalAccessPlatforms
{
	[CmdletBinding()]
	Param (
		[ValidateSet("android", "iOS", "windows", "windowsPhone", "macOS", "all")]
		[string[]] $includePlatforms,
		[ValidateSet("android", "iOS", "windows", "windowsPhone", "macOS", "all")]
		[string[]] $excludePlatforms,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$parentResourceName = "conditionalAccessPolicies"
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$hashtable = @{}
		foreach ($property in ($PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -ne "Cmdlet"})) {			
			$hashtable[$property.Key] = @($property.Value)
		}
	}
	end
	{
		$hashtable
	}
}