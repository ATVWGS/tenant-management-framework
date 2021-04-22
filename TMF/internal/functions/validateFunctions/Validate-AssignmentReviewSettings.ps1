function Validate-AssignmentReviewSettings
{
	[CmdletBinding()]
	Param (
		[bool] $isEnabled,
		[ValidateSet("monthly", "quarterly")]
		[string] $recurrenceType,
		[ValidateSet("Self", "Reviewers")]
		[string] $reviewerType,
		[datetime] $startDateTime,
		[int] $durationInDays,
		[string[]] $reviewers,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$hashtable = @{}
		foreach ($property in ($PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -ne "Cmdlet"})) {
			if ($script:validateFunctionMapping.ContainsKey($property.Key)) {
				$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:validateFunctionMapping[$_].Parameters.Keys)
				$validated = & $script:validateFunctionMapping[$_] @validated -Cmdlet $Cmdlet
			}
			else {
				$validated = $property.Value
			}
			$hashtable[$property.Key] = $validated
		}
	}
	end
	{
		$hashtable
	}
}
