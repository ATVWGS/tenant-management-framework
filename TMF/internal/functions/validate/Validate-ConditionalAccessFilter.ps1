function Validate-ConditionalAccessFilter
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $mode,
		[Parameter(Mandatory = $true)]
		[string] $rule,
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
			$hashtable[$property.Key] = $property.Value
		}
	}
	end
	{
		$hashtable
	}
}
