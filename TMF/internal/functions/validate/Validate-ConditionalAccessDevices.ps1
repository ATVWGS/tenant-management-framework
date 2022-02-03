function Validate-ConditionalAccessDevices
{
	[CmdletBinding()]
	Param (
		[ValidateSet("All")]
		[string[]] $includeDevices,
		[ValidateSet("Compliant", "DomainJoined")]
		[string[]] $excludeDevices,		
		[object] $deviceFilter,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$parentResourceName = "conditionalAccessPolicies"
		try {			
			if (($includeDevices -or $excludeDevices) -and $deviceFilter) {
				throw "It is not allowed to provide includeDevices/excludeDevices and a deviceFilter."
			}
		}
		catch {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "ConditionalAccess" -Tag "failed" -ErrorRecord $_ -FunctionName $Cmdlet.CommandRuntime
			$cmdlet.ThrowTerminatingError($_)
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$hashtable = @{}
		foreach ($property in ($PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -ne "Cmdlet"})) {
			if ($script:supportedResources[$parentResourceName]["validateFunctions"].ContainsKey($property.Key)) {
				if ($property.Value.GetType().BaseType -eq "System.Array") {
					$validated = @()
					foreach ($value in $property.Value) {
						$dummy = $value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
						$validated += & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @dummy -Cmdlet $Cmdlet
					}					
				}
				else {
					$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
					$validated = & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @validated -Cmdlet $Cmdlet
				}				
			}
			else {
				$validated = @($property.Value)			
			}
			$hashtable[$property.Key] = $validated
		}
	}
	end
	{
		$hashtable
	}
}
