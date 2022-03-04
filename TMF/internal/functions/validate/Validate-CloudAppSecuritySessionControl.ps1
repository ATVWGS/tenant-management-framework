function Validate-CloudAppSecuritySessionControl
{
	[CmdletBinding()]
	Param (
		[bool] $isEnabled,
		[ValidateSet("mcasConfigured", "monitorOnly", "blockDownloads", "unknownFutureValue")]
		[string] $cloudAppSecurityType,
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