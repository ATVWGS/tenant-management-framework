function Validate-ConditionalAccessApplications
{
	[CmdletBinding()]
	Param (
		[string[]] $includeApplications,
		[string[]] $excludeApplications,
		[string[]] $includeUserActions,
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
			if ($property.Key -eq "includeUserActions") {
				$validated = @($property.Value)
			}
			else {
				$validated = @($property.Value | Foreach-Object {Resolve-Application -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
			}
			$hashtable[$property.Key] = $validated
		}
	}
	end
	{
		$hashtable
	}
}
