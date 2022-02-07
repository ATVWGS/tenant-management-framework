function Validate-ConditionalAccessLocations
{
	[CmdletBinding()]
	Param (
		[string[]] $includeLocations,
		[string[]] $excludeLocations,
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
			$hashtable[$property.Key] = @($property.Value | Foreach-Object {Resolve-NamedLocation -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
		}
	}
	end
	{
		$hashtable
	}
}
