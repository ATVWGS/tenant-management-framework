function Validate-RequestApprovalSettings
{
	[CmdletBinding(DefaultParameterSetName = 'IPRanges')]
	Param (
		[ValidateSet("NoApproval", "SingleStage", "Serial")]
		[string] $approvalMode,
		[bool] $isApprovalRequired,
		[bool] $isApprovalRequiredForExtension,
		[bool] $isRequestorJustificationRequired,		
		[object[]] $approvalStages,
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
