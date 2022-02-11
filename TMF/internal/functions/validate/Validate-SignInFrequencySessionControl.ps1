function Validate-SignInFrequencySessionControl
{
	[CmdletBinding()]
	Param (
		[bool] $isEnabled,
		[ValidateSet("days", "hours")]
		[string] $type,
		[int32] $value,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{ }
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