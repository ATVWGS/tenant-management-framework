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
	{}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$hashtable = @{}
		foreach ($property in ($PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -ne "Cmdlet"})) {
			if ($script:validateFunctionMapping.ContainsKey($property.Key)) {
				if ($property.Value.GetType().BaseType -eq "System.Array") {
					$validated = @()
					foreach ($value in $property.Value) {
						$dummy = $value | ConvertTo-PSFHashtable -Include $($script:validateFunctionMapping[$property.Key].Parameters.Keys)
						$validated += & $script:validateFunctionMapping[$property.Key] @dummy -Cmdlet $Cmdlet
					}					
				}
				else {
					$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:validateFunctionMapping[$property.Key].Parameters.Keys)
					$validated = & $script:validateFunctionMapping[$property.Key] @validated -Cmdlet $Cmdlet
				}				
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